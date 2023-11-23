import { ethers } from "hardhat";
import { Signer } from "ethers";
import { assert, expect } from "chai";
import { ERC721Grandma, ERC721Grandma__factory } from "../typechain-types";

describe("ERC721Grandma", () => {
    let factory: ERC721Grandma__factory;
    let contract: ERC721Grandma;
    let deployer: Signer;
    let user1: Signer;
    let user2: Signer;

    beforeEach(async () => {
        [deployer, user1, user2] = await ethers.getSigners();

        factory = await ethers.getContractFactory("ERC721Grandma", deployer)
        contract = await factory.deploy("GrandmaTestNtf", "GMAT");

        await contract.waitForDeployment();
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(contract);
    });

    it("should be able to mint a token", async () => {
        await contract.connect(deployer).safeMint(await user1.getAddress());
        
        const tokenOwner = await contract.ownerOf(0);
        assert.equal(tokenOwner, await user1.getAddress());
    });

    it("should not be able to mint a token without minter role", async () => {
        const minterRole = await contract.MINTER_ROLE();
        const user1Address = (await user1.getAddress());
        const response = contract.connect(user1).safeMint(user1Address);
        await expect(response).to.be.revertedWith(`AccessControl: account ${user1Address.toLowerCase()} is missing role ${minterRole}`);
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
        const contractAddress = await contract.getAddress();

        assert.equal(contractURI, `https://api.grandma.digital/token/${contractAddress.toLowerCase()}/`);
    });

    it("should have correct token URI", async () => {
        const contractAddress = await contract.getAddress();
        await contract.connect(deployer).safeMint(await user1.getAddress())
        await contract.connect(deployer).safeMint(await user1.getAddress())

        const tokenURI0 = await contract.tokenURI(0);
        assert.equal(tokenURI0, `https://api.grandma.digital/token/${contractAddress.toLowerCase()}/0`);
        
        const tokenURI1 = await contract.tokenURI(1);
        assert.equal(tokenURI1, `https://api.grandma.digital/token/${contractAddress.toLowerCase()}/1`);
    });

    it("should be able to transfer a token", async () => {
        await contract.connect(deployer).safeMint(await user2.getAddress());
        await contract.connect(user2).transferFrom(await user2.getAddress(), await user1.getAddress(), 0);

        const tokenOwner = await contract.ownerOf(0);
        assert.equal(tokenOwner, await user1.getAddress());
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
        await contract.connect(deployer).safeMint(await deployer.getAddress());
        await contract.connect(deployer).safeMint(await deployer.getAddress());

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
