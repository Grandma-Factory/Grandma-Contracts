import { ethers } from "hardhat";
import { Signer } from "ethers";
import { assert, expect } from "chai";
import { ERC721Grandma } from "../../typechain-types/contracts/tokens/ERC721Grandma";
import { ERC721Grandma__factory } from "../../typechain-types/factories/contracts/tokens/ERC777GrandmaToken__factory";

describe("ERC721Grandma", () => {
    let chainId;
    let factory: ERC721Grandma__factory;
    let contract: ERC721Grandma;
    let deployer: Signer;
    let user1: Signer;
    let user2: Signer;

    beforeEach(async () => {
        chainId = await ethers.getDefaultProvider().getNetwork().chainId;

        [deployer, user1, user2] = await ethers.getSigners();

        factory = await ethers.getContractFactory("ERC721Grandma", deployer)
        contract = await factory.deploy("GrandmaTestNtf", "GMAT");

        await contract.deployed();
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(contract.address);
    });

    it("should be able to mint a token", async () => {
        await contract.connect(deployer).safeMint(await user1.getAddress());
        
        const tokenOwner = await contract.ownerOf(0);

        assert.equal(tokenOwner, await user1.getAddress());
    });

    it("should not be able to mint a token without minter role", async () => {
        const minterRole = await contract.MINTER_ROLE();
        const user1Address = (await user1.getAddress()).toLowerCase();
        const response = contract.connect(user1).safeMint(user1Address);
        await expect(response).to.be.revertedWith(`AccessControl: account ${user1Address} is missing role ${minterRole}`);
    });

    it("should be able to add minter role", async () => {
        const minterRole = await contract.MINTER_ROLE();
        await contract.connect(deployer).grantRole(minterRole, await user1.getAddress());

        await contract.connect(user1).safeMint(await user1.getAddress());
        const tokenOwner = await contract.ownerOf(0);
        assert.equal(tokenOwner, await user1.getAddress());
    });

    it("should have correct contract URI", async () => {
        const contractURI = await contract.contractURI();

        assert.equal(contractURI, `https://api.grandma.digital/token/${contract.address.toLowerCase()}/`);
    });

    it("should have correct token URI", async () => {
        await contract.connect(deployer).safeMint(await user1.getAddress())
        await contract.connect(deployer).safeMint(await user1.getAddress())

        const tokenURI0 = await contract.tokenURI(0);
        assert.equal(tokenURI0, `https://api.grandma.digital/token/${contract.address.toLowerCase()}/0`);
        
        const tokenURI1 = await contract.tokenURI(1);
        assert.equal(tokenURI1, `https://api.grandma.digital/token/${contract.address.toLowerCase()}/1`);
    });

    it("should be able to transfer a token", async () => {
        await contract.connect(deployer).safeMint(await user2.getAddress());

        await contract.connect(user2).transferFrom(await user2.getAddress(), await user1.getAddress(), 0);

        const tokenOwner = await contract.ownerOf(0);
        assert.equal(tokenOwner, await user1.getAddress());
    });
});
