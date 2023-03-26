import { ethers } from "hardhat";
import { Signer } from "ethers";
import { assert, expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC1155Grandma } from "../../typechain-types/contracts/tokens/ERC1155Grandma";
import { ERC1155Grandma__factory } from "../../typechain-types/factories/contracts/tokens/ERC1155Grandma__factory";

const rewardEnum = {
    COTTON: 0,
    CASHMERE: 1,
    SILK: 2,
  }


describe("ERC1155Grandma", () => {
    let chainId;
    let factory: ERC1155Grandma__factory;
    let contract: ERC1155Grandma;
    let deployer: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    beforeEach(async () => {
        chainId = await ethers.getDefaultProvider().getNetwork().chainId;

        [deployer, user1, user2] = await ethers.getSigners();

        factory = await ethers.getContractFactory("ERC1155Grandma", deployer)
        contract = await factory.deploy();

        await contract.deployed();
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(contract.address);
    });

    it("should be able to mint tokens", async () => {
        const user1Address = await user1.getAddress();
        await contract.connect(deployer).mint(user1Address, rewardEnum.COTTON, 1, ethers.utils.hexlify(0));
        const user1BalanceOfCotton = await contract.balanceOf(user1Address, rewardEnum.COTTON);
        assert.equal(user1BalanceOfCotton.toNumber(), 1);
        
        const user2Address = await user1.getAddress();
        await contract.connect(deployer).mint(user2Address, rewardEnum.CASHMERE, 1, ethers.utils.hexlify(0));
        await contract.connect(deployer).mint(user2Address, rewardEnum.CASHMERE, 1, ethers.utils.hexlify(0));
        const user2BalanceOfCashmere = await contract.balanceOf(user2Address, rewardEnum.CASHMERE);
        assert.equal(user2BalanceOfCashmere.toNumber(), 2);
    });

    it("should not be able to mint a token without minter role", async () => {
        const minterRole = await contract.MINTER_ROLE();
        const user1Address = (await user1.getAddress()).toLowerCase();
        const response = contract.connect(user1).mint(user1Address, rewardEnum.COTTON, 1, ethers.utils.hexlify(0));
        await expect(response).to.be.revertedWith(`AccessControl: account ${user1Address} is missing role ${minterRole}`);
    });

    it("should be able to add minter role", async () => {
        const minterRole = await contract.MINTER_ROLE();
        await contract.connect(deployer).grantRole(minterRole, await user1.getAddress());

        const user1Address = await user1.getAddress();
        await contract.connect(user1).mint(user1Address, rewardEnum.COTTON, 1, ethers.utils.hexlify(0));
        const user1BalanceOfCotton = await contract.balanceOf(user1Address, rewardEnum.COTTON);
        assert.equal(user1BalanceOfCotton.toNumber(), 1);
    });

    it("should have correct contract URI", async () => {
        const contractURI = await contract.uri(rewardEnum.COTTON);
        assert.equal(contractURI, `https://api.grandma.digital/token/${contract.address.toLowerCase()}/{id}`);
    });

    it("should be able to update contract URI", async () => {
        await contract.setURI(`https://api.grandma.digital/token/${contract.address.toLowerCase()}/{id}/test`);
        const contractURI = await contract.uri(rewardEnum.COTTON);
        assert.equal(contractURI, `https://api.grandma.digital/token/${contract.address.toLowerCase()}/{id}/test`);
    });
});
