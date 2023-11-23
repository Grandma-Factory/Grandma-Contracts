import { ethers, upgrades } from "hardhat";
import { assert } from "chai";
import { CrowdfundingEscrowFactory, CrowdfundingEscrowFactory__factory, ERC20VaultFactory, ERC20VaultFactory__factory, Incubator, Incubator__factory } from "../typechain-types";
import { Signer } from "ethers";
import * as sale from "../../utils/src/Sale";

describe("Incubator", () => {
    let factory: Incubator__factory;
    let contract: Incubator;
    let escrowFactoryFactory: CrowdfundingEscrowFactory__factory;
    let escrowFactorycontract: CrowdfundingEscrowFactory;
    let vaultFactoryFactory: ERC20VaultFactory__factory;
    let vaultFactorycontract: ERC20VaultFactory;
    let deployer: Signer;
    let user1: Signer;
    let user2: Signer;

    beforeEach(async () => {
        [deployer, user1, user2] = await ethers.getSigners();

        // deploy the escrow factory contract
        escrowFactoryFactory = await ethers.getContractFactory("CrowdfundingEscrowFactory");
        escrowFactorycontract = await escrowFactoryFactory.deploy();

        // deploy the vault factory contract
        vaultFactoryFactory = await ethers.getContractFactory("ERC20VaultFactory");
        vaultFactorycontract = await vaultFactoryFactory.deploy();

        // deploy the Incubator contract
        factory = await ethers.getContractFactory("Incubator");
        contract = await upgrades.deployProxy(factory, [await escrowFactorycontract.getAddress(), await vaultFactorycontract.getAddress()]);

        await contract.waitForDeployment();
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(await contract.getAddress());
    });

    /*it("should be able to post a new sale", async () => {
        // Create a new sale object
        const newAssetType = sale.AssetType()
        // const newAsset = sale.Asset()
        // const newSale = sale.Sale(await user1.getAddress(), newAsset, 1, 0, 0, 0, "", "", 0);

        // Post the sale
        // await contract.postSale(newSale);

        // Retrieve the created crowdfunding escrow address
        // const escrowAddress = await contract.getSaleCrowdfundingEscrow(newSale);

        // Assert that the escrow address is not empty
        // assert.isNotEmpty(escrowAddress);
    });*/


});
