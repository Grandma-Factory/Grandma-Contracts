import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { ERC1155Grandma, ERC1155Grandma__factory } from "../typechain-types";
import { Signer } from "ethers";


describe("ERC1155Grandma", () => {
    let chainId = 111;
    let factory: ERC1155Grandma__factory;
    let contract: ERC1155Grandma;
    let contractAddress: string;
    let deployer: Signer;
    let user1: Signer;
    let user2: Signer;

    beforeEach(async () => {
        [deployer, user1, user2] = await ethers.getSigners();

        factory = await ethers.getContractFactory("ERC1155Grandma", deployer)
        contract = await factory.deploy();

        await contract.waitForDeployment();
        contractAddress = await contract.getAddress();
    });

    it("should be able to mint tokens", async () => {
        const user1Address = await user1.getAddress();
        await contract.connect(deployer).mint(user1Address, 0, 1, ethers.toBeHex(0));
        const user1BalanceOfCotton = await contract.balanceOf(user1Address, 0);
        assert.equal(user1BalanceOfCotton, BigInt(1));
        
        const user2Address = await user1.getAddress();
        await contract.connect(deployer).mint(user2Address, 1, 1, ethers.toBeHex(0));
        await contract.connect(deployer).mint(user2Address, 1, 1, ethers.toBeHex(0));
        const user2BalanceOfCashmere = await contract.balanceOf(user2Address, 1);
        assert.equal(user2BalanceOfCashmere, BigInt(2));
    });

    it("should not be able to mint a token without minter role", async () => {
        const minterRole = await contract.MINTER_ROLE();
        const user1Address = (await user1.getAddress());
        const response = contract.connect(user1).mint(user1Address, 0, 1, ethers.toBeHex(0));
        await expect(response).to.be.revertedWith(`AccessControl: account ${user1Address.toLowerCase()} is missing role ${minterRole}`);
    });

    it("should be able to add minter role", async () => {
        const minterRole = await contract.MINTER_ROLE();
        await contract.connect(deployer).grantRole(minterRole, await user1.getAddress());

        const user1Address = await user1.getAddress();
        await contract.connect(user1).mint(user1Address, 0, 1, ethers.toBeHex(0));
        const user1BalanceOfCotton = await contract.balanceOf(user1Address, 0);
        assert.equal(user1BalanceOfCotton, BigInt(1));
    });

    it("should have correct contract URI", async () => {
        const contractURI = await contract.uri(0);
        assert.equal(contractURI, `https://api.grandma.digital/token/${contractAddress.toLowerCase()}/{id}`);
    });

    it("should be able to update contract URI", async () => {
        await contract.setURI(`https://api.grandma.digital/token/${contractAddress.toLowerCase()}/{id}/test`);
        const contractURI = await contract.uri(0);
        assert.equal(contractURI, `https://api.grandma.digital/token/${contractAddress.toLowerCase()}/{id}/test`);
    });
    
    it("should not be able to set royality without royalty admin role", async () => {
        const royaltyAdminRole = await contract.ADMIN_ROYALTIES_ROLE();
        const user1Address = (await user1.getAddress());
        const response = contract.connect(user1).setDefaultRoyalty(deployer.getAddress(), 125);
        await expect(response).to.be.revertedWith(`AccessControl: account ${user1Address.toLowerCase()} is missing role ${royaltyAdminRole}`);
    });

    it("should be able to set royalty admin role", async () => {
        const royaltyAdminRole = await contract.ADMIN_ROYALTIES_ROLE();
        await contract.connect(deployer).grantRole(royaltyAdminRole, await user1.getAddress());
        await contract.connect(user1).setDefaultRoyalty(deployer.getAddress(), 125);
    });

    it("should be able to set royalty receiver", async () => {
        await contract.connect(deployer).mint(deployer.getAddress(), 0, 1, ethers.toBeHex(0));
        await contract.connect(deployer).mint(deployer.getAddress(), 1, 1, ethers.toBeHex(0));

        // set 1.25% fees on for deployer address by default
        await contract.connect(deployer).setDefaultRoyalty(deployer.getAddress(), 125);
        // set 3.75 fees on for user1 address for token 1 
        await contract.connect(deployer).setTokenRoyalty(1, user1.getAddress(), 375);

        let [receiver0, fee0] = await contract.connect(deployer).royaltyInfo(0,10000);
        let [receiver1, fee1] = await contract.connect(deployer).royaltyInfo(1,10000);

        assert.equal(receiver0, await deployer.getAddress());
        assert.equal(receiver1, await user1.getAddress());

        assert.equal(fee0, BigInt(125));
        assert.equal(fee1, BigInt(375));
    });
});
