import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { ERC1155GrandmaReward, ERC1155GrandmaReward__factory, ERC777GrandmaToken, ERC777GrandmaToken__factory } from "../typechain-types";
import { Signer } from "ethers";


describe("ERC1155GrandmaReward", () => {
    let factoryToken: ERC777GrandmaToken__factory;
    let contractToken: ERC777GrandmaToken;
    let factory: ERC1155GrandmaReward__factory;
    let contract: ERC1155GrandmaReward;
    let deployer: Signer;
    let user1: Signer;
    let user2: Signer;
    let user3: Signer;

    beforeEach(async () => {
        [deployer, user1, user2, user3] = await ethers.getSigners();

        factoryToken = await ethers.getContractFactory("ERC777GrandmaToken", deployer)
        contractToken = await factoryToken.deploy([]);
        await contractToken.connect(deployer).transfer(user1, 1000);
        await contractToken.connect(deployer).transfer(user2, 1000);
        await contractToken.connect(deployer).transfer(user3, 1000);


        factory = await ethers.getContractFactory("ERC1155GrandmaReward", deployer)
        contract = await factory.deploy(contractToken);

        await contract.waitForDeployment();
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(contract);
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
        assert.equal(poolCounter, BigInt(1));


        const [name, opened, mincap, boost, supply] = await contract.connect(deployer).getPoolData(0);
        assert.equal(name, "DEFAULT");
        assert.equal(opened, true);
        assert.equal(mincap, BigInt(0));
        assert.equal(boost, BigInt(100));
        assert.equal(supply, BigInt(0));
    });
    

    it("should be able to multiple pool", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contract.connect(deployer).createPool("COTTON", false, 10, 115);
        
        const poolCounter = await contract.connect(deployer).getPoolCount();
        assert.equal(poolCounter, BigInt(2));

        const [name1, opened1, mincap1, boost1, supply1] = await contract.connect(deployer).getPoolData(0);
        const [name2, opened2, mincap2, boost2, supply2] = await contract.connect(deployer).getPoolData(1);
        assert.equal(name1, "DEFAULT");
        assert.equal(opened1, true);
        assert.equal(mincap1, BigInt(0));
        assert.equal(boost1, BigInt(100));
        assert.equal(supply1, BigInt(0));
        assert.equal(name2, "COTTON");
        assert.equal(opened2, false);
        assert.equal(mincap2, BigInt(10));
        assert.equal(boost2, BigInt(115));
        assert.equal(supply2, BigInt(0));
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
        assert.equal(poolCounter, BigInt(2));

        const [name1, opened1, mincap1, boost1, supply1] = await contract.connect(deployer).getPoolData(0);
        const [name2, opened2, mincap2, boost2, supply2] = await contract.connect(deployer).getPoolData(1);
        assert.equal(name1, "DEFAULT");
        assert.equal(opened1, true);
        assert.equal(mincap1, BigInt(0));
        assert.equal(boost1, BigInt(100));
        assert.equal(supply1, BigInt(0));
        assert.equal(name2, "COTTON_UPDATED");
        assert.equal(opened2, true);
        assert.equal(mincap2, BigInt(100));
        assert.equal(boost2, BigInt(150));
        assert.equal(supply2, BigInt(0));
    });
    
    it("should be able to add pauser role", async () => {
        const pauserRole = await contract.PAUSER_ROLE();
        await contract.connect(deployer).grantRole(pauserRole, await user1.getAddress());
        await contract.connect(user1).pause();
        await contract.connect(user1).unpause();
    });

    it("should cumulate pending distribution on token receipt", async () => {
        let pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount, BigInt(0));

        await contractToken.connect(deployer).transfer(contract, 100);
        pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount, BigInt(100));

        await contractToken.connect(deployer).transfer(contract, 150);
        pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount, BigInt(250));
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
        
        await contractToken.connect(user1).authorizeOperator(contract);
        await contractToken.connect(user2).authorizeOperator(contract);

        await contract.connect(user1).enter(0, 1000);
        let [,,,, supply] = await contract.connect(deployer).getPoolData(0);
        assert.equal(supply, BigInt(1000));
        let user1Balance = await contract.connect(deployer).balanceOf(user1, 0);
        assert.equal(user1Balance, BigInt(1000));

        await contract.connect(user2).enter(0, 1000);
        [,,,, supply] = await contract.connect(deployer).getPoolData(0);
        assert.equal(supply, BigInt(2000));
        const user2Balance = await contract.connect(deployer).balanceOf(user1, 0);
        assert.equal(user2Balance, BigInt(1000));
        
        user1Balance = await contract.connect(deployer).balanceOf(user1, 0);
        assert.equal(user1Balance, BigInt(1000));

    });

    it("should revert distribution if pools are empty", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contractToken.connect(deployer).transfer(contract, 100);

        const response = contract.connect(deployer).distribute();
        await expect(response).to.be.revertedWith("ERC1155GrandmaRewards: Sum of supply times boost must be greater than zero");
    });

    it("should perform distribute with one pool filled", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contract.connect(deployer).createPool("COTTON", true, 0, 200);
        await contract.connect(deployer).createPool("CASHMERE", true, 0, 300);
        
        await contractToken.connect(user1).authorizeOperator(contract);
        await contractToken.connect(user2).authorizeOperator(contract);
        await contractToken.connect(user3).authorizeOperator(contract);

        await contract.connect(user1).enter(0, 1000);
        await contract.connect(user2).enter(0, 1000);
        await contract.connect(user3).enter(0, 500);

        await contractToken.connect(deployer).transfer(contract, 300);
        await contract.connect(deployer).distribute();

        const [,,,, supply1] = await contract.connect(deployer).getPoolData(0);
        const [,,,, supply2] = await contract.connect(deployer).getPoolData(1);
        const [,,,, supply3] = await contract.connect(deployer).getPoolData(2);
        
        const pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount, BigInt(0));
        
        assert.equal(supply1, BigInt(2800));
        assert.equal(supply2, BigInt(0));
        assert.equal(supply3, BigInt(0));
    });

    it("should perform distribute", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contract.connect(deployer).createPool("COTTON", true, 0, 200);
        await contract.connect(deployer).createPool("CASHMERE", true, 0, 300);
        
        await contractToken.connect(user1).authorizeOperator(contract);
        await contractToken.connect(user2).authorizeOperator(contract);
        await contractToken.connect(user3).authorizeOperator(contract);
        
        await contract.connect(user1).enter(0, 1000);
        await contract.connect(user2).enter(1, 1000);
        await contract.connect(user3).enter(2, 1000);

        await contractToken.connect(deployer).transfer(contract, 300);
        await contract.connect(deployer).distribute();

        const [,,,, supply1] = await contract.connect(deployer).getPoolData(0);
        const [,,,, supply2] = await contract.connect(deployer).getPoolData(1);
        const [,,,, supply3] = await contract.connect(deployer).getPoolData(2);
        
        const pending_amount = await contract.connect(deployer).getPendingDistribution();
        assert.equal(pending_amount, BigInt(0));
        
        assert.equal(supply1, BigInt(1050));
        assert.equal(supply2, BigInt(1100));
        assert.equal(supply3, BigInt(1150));
    });

    it("should be able to withdraw", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        
        await contractToken.connect(user1).authorizeOperator(contract);
        await contractToken.connect(user2).authorizeOperator(contract);
        
        await contract.connect(user1).enter(0, 1000);
        await contract.connect(user2).enter(0, 1000);

        await contractToken.connect(deployer).transfer(contract, 200);
        await contract.connect(deployer).distribute();

        
        await contract.connect(user1).leave(0, 1000);
        const [,,,, supply1] = await contract.connect(deployer).getPoolData(0);
        assert.equal(supply1, BigInt(1100));

        const balanceOfPool = await contract.connect(deployer).balanceOf(user1, 0);
        const balanceOfToken = await contractToken.connect(deployer).balanceOf(user1);
        assert.equal(balanceOfPool, BigInt(0));
        assert.equal(balanceOfToken, BigInt(1100));
    });

    it("should not be able to withdraw without enough tokens", async () => {
        await contract.connect(deployer).createPool("DEFAULT", true, 0, 100);
        await contractToken.connect(user1).authorizeOperator(contract);
        await contract.connect(user1).enter(0, 1000);

        const response = contract.connect(user1).leave(0, 1001);
        await expect(response).to.be.revertedWith("ERC1155GrandmaRewards: Not enough token shares");
    });

});
