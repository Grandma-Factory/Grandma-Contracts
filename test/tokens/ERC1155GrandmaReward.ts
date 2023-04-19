import { ethers } from "hardhat";
import { Signer } from "ethers";
import { assert, expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC1155GrandmaReward } from "../../typechain-types/contracts/tokens/ERC1155GrandmaReward";
import { ERC1155GrandmaReward__factory } from "../../typechain-types/factories/contracts/tokens/ERC1155GrandmaReward__factory";
import { ERC777GrandmaToken, ERC777GrandmaToken__factory } from "../../typechain-types";

const rewardEnum = {
    COTTON: 0,
    CASHMERE: 1,
    SILK: 2,
  }


describe("ERC1155GrandmaReward", () => {
    let chainId;
    let factoryToken: ERC777GrandmaToken__factory;
    let contractToken: ERC777GrandmaToken;
    let factory: ERC1155GrandmaReward__factory;
    let contract: ERC1155GrandmaReward;
    let deployer: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    let user3: SignerWithAddress;

    beforeEach(async () => {
        chainId = await ethers.getDefaultProvider().getNetwork().chainId;

        [deployer, user1, user2, user3] = await ethers.getSigners();

        factoryToken = await ethers.getContractFactory("ERC777GrandmaToken", deployer)
        contractToken = await factoryToken.deploy([]);
        await contractToken.connect(deployer).transfer(user1.address, 1000);
        await contractToken.connect(deployer).transfer(user2.address, 1000);
        await contractToken.connect(deployer).transfer(user3.address, 1000);


        factory = await ethers.getContractFactory("ERC1155GrandmaReward", deployer)
        contract = await factory.deploy(contractToken.address);

        await contract.deployed();
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(contract.address);
    });

    it("should not be able to create a pool if not admin", async () => {
        const response = contract.connect(user1).createPool("DEFAULT", true, 0, 100);
        
        const adminRole = await contract.DEFAULT_ADMIN_ROLE();
        const user1Address = await user1.getAddress();
        await expect(response).to.be.revertedWith(`AccessControl: account ${user1Address.toLowerCase()} is missing role ${adminRole}`);
    });

    it("should be able to create a pool", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        const poolCounter = await contract.connect(deployer).getPoolCount();
        assert.equal(poolCounter.toNumber(), 1);


        const [name, opened, mincap, boost, supply] = await contract.connect(deployer).getPoolData(0);
        assert.equal(name, "DEFAULT");
        assert.equal(opened, true);
        assert.equal(mincap.toNumber(), 0);
        assert.equal(boost.toNumber(), 100);
        assert.equal(supply.toNumber(), 0);
    });
    

    it("should be able to multiple pool", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contract.connect(deployer).createPool("COTTON", false, 10, 115);
        
        const poolCounter = await contract.connect(deployer).getPoolCount();
        assert.equal(poolCounter.toNumber(), 2);

        const [name1, opened1, mincap1, boost1, supply1] = await contract.connect(deployer).getPoolData(0);
        const [name2, opened2, mincap2, boost2, supply2] = await contract.connect(deployer).getPoolData(1);
        assert.equal(name1, "DEFAULT");
        assert.equal(opened1, true);
        assert.equal(mincap1.toNumber(), 0);
        assert.equal(boost1.toNumber(), 100);
        assert.equal(supply1.toNumber(), 0);
        assert.equal(name2, "COTTON");
        assert.equal(opened2, false);
        assert.equal(mincap2.toNumber(), 10);
        assert.equal(boost2.toNumber(), 115);
        assert.equal(supply2.toNumber(), 0);
    });

    it("should not be able to update pool if not admin", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        const response =  contract.connect(user1).updatePool(0, "DEFAULT_UPDATED", true, 1, 110);
        
        const user1Address = await user1.getAddress();
        const adminRole = await contract.DEFAULT_ADMIN_ROLE();
        await expect(response).to.be.revertedWith(`AccessControl: account ${user1Address.toLowerCase()} is missing role ${adminRole}`);
    });
    
    it("should be able to update multiple pool", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contract.connect(deployer).createPool("COTTON", false, 10, 115);
        await contract.connect(deployer).updatePool(1, "COTTON_UPDATED", true, 100, 150);
        
        const poolCounter = await contract.connect(deployer).getPoolCount();
        assert.equal(poolCounter.toNumber(), 2);

        const [name1, opened1, mincap1, boost1, supply1] = await contract.connect(deployer).getPoolData(0);
        const [name2, opened2, mincap2, boost2, supply2] = await contract.connect(deployer).getPoolData(1);
        assert.equal(name1, "DEFAULT");
        assert.equal(opened1, true);
        assert.equal(mincap1.toNumber(), 0);
        assert.equal(boost1.toNumber(), 100);
        assert.equal(supply1.toNumber(), 0);
        assert.equal(name2, "COTTON_UPDATED");
        assert.equal(opened2, true);
        assert.equal(mincap2.toNumber(), 100);
        assert.equal(boost2.toNumber(), 150);
        assert.equal(supply2.toNumber(), 0);
    });
    
    it("should be able to add pauser role", async () => {
        const pauserRole = await contract.PAUSER_ROLE();
        await contract.connect(deployer).grantRole(pauserRole, await user1.getAddress());
        await contract.connect(user1).pause();
        await contract.connect(user1).unpause();
    });

    it("should cumulate pending distribution on token receipt", async () => {
        let pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount.toNumber(), 0);

        await contractToken.connect(deployer).transfer(contract.address, 100);
        pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount.toNumber(), 100);

        await contractToken.connect(deployer).transfer(contract.address, 150);
        pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount.toNumber(), 250);
    });

    it("should reject stackers if pool not opened", async () => {
        await contract.connect(deployer).createPool("DEFAULT", false, 0, 100);
        const response = contract.connect(user1).enter(0, 1000);
        await expect(response).to.be.revertedWith("ERC1155GrandmaRewards: Token id not opened");
    });

    it("should reject stackers if contract is not a token operator", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        const response = contract.connect(user1).enter(0, 1000);
        await expect(response).to.be.revertedWith("ERC777: caller is not an operator for holder");
    });

    it("should accept stacker", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contract.connect(deployer).createPool("COTTON", true, 0, 100);
        
        await contractToken.connect(user1).authorizeOperator(contract.address);
        await contractToken.connect(user2).authorizeOperator(contract.address);

        await contract.connect(user1).enter(0, 1000);
        let [,,,, supply] = await contract.connect(deployer).getPoolData(0);
        assert.equal(supply.toNumber(), 1000);
        let user1Balance = await contract.connect(deployer).balanceOf(user1.address, 0);
        assert.equal(user1Balance.toNumber(), 1000);

        await contract.connect(user2).enter(0, 1000);
        [,,,, supply] = await contract.connect(deployer).getPoolData(0);
        assert.equal(supply.toNumber(), 2000);
        const user2Balance = await contract.connect(deployer).balanceOf(user1.address, 0);
        assert.equal(user2Balance.toNumber(), 1000);
        
        user1Balance = await contract.connect(deployer).balanceOf(user1.address, 0);
        assert.equal(user1Balance.toNumber(), 1000);

    });

    it("should revert distribution if pools are empty", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contractToken.connect(deployer).transfer(contract.address, 100);

        const response = contract.connect(deployer).distribute();
        await expect(response).to.be.revertedWith("ERC1155GrandmaRewards: Sum of supply times boost must be greater than zero");
    });

    it("should perform distribute with one pool filled", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contract.connect(deployer).createPool("COTTON", true, 0, 200);
        await contract.connect(deployer).createPool("CASHMERE", true, 0, 300);
        
        await contractToken.connect(user1).authorizeOperator(contract.address);
        await contractToken.connect(user2).authorizeOperator(contract.address);
        await contractToken.connect(user3).authorizeOperator(contract.address);

        await contract.connect(user1).enter(0, 1000);
        await contract.connect(user2).enter(0, 1000);
        await contract.connect(user3).enter(0, 500);

        await contractToken.connect(deployer).transfer(contract.address, 300);
        await contract.connect(deployer).distribute();

        const [,,,, supply1] = await contract.connect(deployer).getPoolData(0);
        const [,,,, supply2] = await contract.connect(deployer).getPoolData(1);
        const [,,,, supply3] = await contract.connect(deployer).getPoolData(2);
        
        const pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount.toNumber(), 0);
        
        assert.equal(supply1.toNumber(), 2800);
        assert.equal(supply2.toNumber(), 0);
        assert.equal(supply3.toNumber(), 0);
    });

    it("should perform distribute", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contract.connect(deployer).createPool("COTTON", true, 0, 200);
        await contract.connect(deployer).createPool("CASHMERE", true, 0, 300);
        
        await contractToken.connect(user1).authorizeOperator(contract.address);
        await contractToken.connect(user2).authorizeOperator(contract.address);
        await contractToken.connect(user3).authorizeOperator(contract.address);
        
        await contract.connect(user1).enter(0, 1000);
        await contract.connect(user2).enter(1, 1000);
        await contract.connect(user3).enter(2, 1000);

        await contractToken.connect(deployer).transfer(contract.address, 300);
        await contract.connect(deployer).distribute();

        const [,,,, supply1] = await contract.connect(deployer).getPoolData(0);
        const [,,,, supply2] = await contract.connect(deployer).getPoolData(1);
        const [,,,, supply3] = await contract.connect(deployer).getPoolData(2);
        
        const pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount.toNumber(), 0);
        
        assert.equal(supply1.toNumber(), 1050);
        assert.equal(supply2.toNumber(), 1100);
        assert.equal(supply3.toNumber(), 1150);
    });

    it("should be able to withdraw", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        
        await contractToken.connect(user1).authorizeOperator(contract.address);
        await contractToken.connect(user2).authorizeOperator(contract.address);
        
        await contract.connect(user1).enter(0, 1000);
        await contract.connect(user2).enter(0, 1000);

        await contractToken.connect(deployer).transfer(contract.address, 200);
        await contract.connect(deployer).distribute();

        
        await contract.connect(user1).leave(0, 1000);
        const [,,,, supply1] = await contract.connect(deployer).getPoolData(0);
        assert.equal(supply1.toNumber(), 1100);

        const balanceOfPool = await contract.connect(deployer).balanceOf(user1.address, 0);
        const balanceOfToken = await contractToken.connect(deployer).balanceOf(user1.address);
        assert.equal(balanceOfPool.toNumber(), 0);
        assert.equal(balanceOfToken.toNumber(), 1100);
    });

    it("should not be able to withdraw without enough tokens", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contractToken.connect(user1).authorizeOperator(contract.address);
        await contract.connect(user1).enter(0, 1000);

        const response = contract.connect(user1).leave(0, 1001);
        await expect(response).to.be.revertedWith("ERC1155GrandmaRewards: Not enough token shares");
    });

});
