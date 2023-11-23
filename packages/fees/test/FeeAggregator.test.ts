import { ethers, upgrades, network } from "hardhat";
import { assert } from "chai";
import { FeeAggregator, FeeAggregator__factory, ERC20GrandmaToken, ERC20GrandmaToken__factory } from "../typechain-types";
import { Signer } from "ethers";



describe("FeeAggregator", () => {
    let factoryToken: ERC20GrandmaToken__factory;
    let contractToken: ERC20GrandmaToken;
    let factory: FeeAggregator__factory;
    let contract: FeeAggregator;
    let deployer: Signer;
    let collector: Signer;
    let reward: Signer;

    beforeEach(async () => {
        [deployer, collector, reward] = await ethers.getSigners();

        // deploy GMA
        factoryToken = await ethers.getContractFactory("ERC20GrandmaToken", deployer)
        contractToken = await factoryToken.deploy();

        // deploy the FeeAggregator
        factory = await ethers.getContractFactory("FeeAggregator");
        let addresses = [await collector.getAddress(), await reward.getAddress()];
        let shares = [8500, 1500]; // 85% for collector and 15% for rewards
        contract = await upgrades.deployProxy(factory, [addresses, shares]);

        await contract.waitForDeployment();
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(await contract.getAddress());
    });

    it("should be able to release ETH by batch", async () => {
        // reset balances
        await network.provider.send("hardhat_setBalance", [
            await collector.getAddress(),
            "0x0",
        ]);
        await network.provider.send("hardhat_setBalance", [
            await reward.getAddress(),
            "0x0",
        ]);
        // allocate 100 WEI to contract
        await deployer.sendTransaction({
            to: await contract.getAddress(),
            value: 100,
        });

        // release a batch
        await contract.connect(deployer)["releaseBatch(address[])"]([await collector.getAddress(), await reward.getAddress()]);

        let balanceCollector = await ethers.provider.getBalance(await collector.getAddress());
        let balanceReward = await ethers.provider.getBalance(await reward.getAddress());
        assert.equal(balanceCollector, BigInt(85));
        assert.equal(balanceReward, BigInt(15));
    });

    it("should be able to release token by batch", async () => {
        // allocate 100 GMA to contract
        await contractToken.connect(deployer).transfer(await contract.getAddress(), 100);

        // release a batch
        await contract.connect(deployer)["releaseBatch(address,address[])"](await contractToken.getAddress(), [await collector.getAddress(), await reward.getAddress()]);

        let balanceCollector = await contractToken.balanceOf(await collector.getAddress());
        let balanceReward = await contractToken.balanceOf(await reward.getAddress());
        assert.equal(balanceCollector, BigInt(85));
        assert.equal(balanceReward, BigInt(15));
    });
});
