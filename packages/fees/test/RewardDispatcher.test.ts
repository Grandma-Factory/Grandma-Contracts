import { ethers, upgrades } from "hardhat";
import { assert, expect } from "chai";
import { RewardDispatcher, RewardDispatcher__factory, ERC20GrandmaToken, ERC20GrandmaToken__factory, SwapRouterMock, SwapRouterMock__factory, FeeAggregator__factory, FeeAggregator, ERC20, ERC20__factory, WETHMock, WETHMock__factory, ERC20Mock, ERC20Mock__factory} from "../typechain-types";
import { Signer } from "ethers";



describe("RewardDispatcher", () => {
    let factoryToken: ERC20GrandmaToken__factory;
    let contractGMA: ERC20GrandmaToken;

    let factoryRDT: ERC20Mock__factory;
    let contractRDT: ERC20Mock;

    let factoryWETH: WETHMock__factory;
    let contractWETH: WETHMock;

    let factoryFeeAggregator: FeeAggregator__factory;
    let contractFeeAggregator: FeeAggregator;

    let factorySwapRouterMock: SwapRouterMock__factory;
    let contractSwapRouterMock: SwapRouterMock;
    
    let factory: RewardDispatcher__factory;
    let contract: RewardDispatcher;
    let deployer: Signer;
    let user1: Signer;
    let user2: Signer;
    let user3: Signer;
    let Ox0 = "0x0000000000000000000000000000000000000000";

    beforeEach(async () => {
        [deployer, user1, user2, user3] = await ethers.getSigners();

        // deploy GMA
        factoryToken = await ethers.getContractFactory("ERC20GrandmaToken", deployer)
        contractGMA = await factoryToken.deploy();

        // deploy a random token 
        factoryRDT = await ethers.getContractFactory("ERC20Mock", deployer)
        contractRDT = await factoryRDT.deploy("RandomToken", "RDT");

        // deploy WETH
        factoryWETH = await ethers.getContractFactory("WETHMock")
        contractWETH = await factoryWETH.deploy();

        // deploy SwapRouterMock
        factorySwapRouterMock = await ethers.getContractFactory("SwapRouterMock", deployer)
        let swapFrom = [await contractRDT.getAddress(), await contractWETH.getAddress()];
        let swapTo = [await contractGMA.getAddress(), await contractGMA.getAddress()];
        let swapRates = [2, 10];
        contractSwapRouterMock = await factorySwapRouterMock.deploy(swapFrom, swapTo, swapRates);

        // deploy RewardDispatcher
        factory = await ethers.getContractFactory("RewardDispatcher");
        contract = await upgrades.deployProxy(factory, [await contractGMA.getAddress(), Ox0, await contractSwapRouterMock.getAddress(), await contractWETH.getAddress()]);
        await contract.waitForDeployment();

        // deploy FeeAggregator
        factoryFeeAggregator = await ethers.getContractFactory("FeeAggregator");
        let addresses = [await contract.getAddress()];
        let shares = [10000]; // 80% for collector and 20% for rewards
        contractFeeAggregator = await upgrades.deployProxy(factoryFeeAggregator, [addresses, shares]);

        // set the fee aggregator address
        await contract.setFeeAggregator(await contractFeeAggregator.getAddress());
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(await contract.getAddress());
    });

    it("should be able to collect ETH", async () => {
        // allocate 100 WEI to FeeAggregator
        await deployer.sendTransaction({
            to: await contractFeeAggregator.getAddress(),
            value: 100,
        });
        // allocate 1000 GMA to SwapRouter
        await contractGMA.connect(deployer).transfer(await contractSwapRouterMock.getAddress(), 1000);

        await contract.connect(deployer)["collectFees()"]();
        const tokenBalance = await contractGMA.connect(deployer).balanceOf(await contract.getAddress());
        assert.equal(tokenBalance, BigInt(1000));
    });

    it("should be able to collect GMA tokens", async () => {
        // allocate 100 GMA to SwapRouter
        await contractGMA.connect(deployer).transfer(await contractFeeAggregator.getAddress(), 100);

        await contract.connect(deployer)["collectFees(address[])"]([await contractGMA.getAddress()]);
        const tokenBalance = await contractGMA.connect(deployer).balanceOf(await contract.getAddress());
        assert.equal(tokenBalance, BigInt(100));
    });

    it("should be able to collect token", async () => {
        // allocate 100 RDT to FeeAggregator
        await contractRDT.connect(deployer).mint(await contractFeeAggregator.getAddress(), 100);
        // allocate 200 GMA to SwapRouter
        await contractGMA.connect(deployer).transfer(await contractSwapRouterMock.getAddress(), 200);

        await contract.connect(deployer)["collectFees(address[])"]([await contractRDT.getAddress()]);
        const tokenBalance = await contractGMA.connect(deployer).balanceOf(await contract.getAddress());
        assert.equal(tokenBalance, BigInt(200));
    });

    it("should be able to collect multiple tokens", async () => {
        // allocate 100 WEI to FeeAggregator
        await deployer.sendTransaction({
            to: await contractWETH.getAddress(),
            value: 100,
        });
        await contractWETH.connect(deployer).transfer(await contractFeeAggregator.getAddress(), 100);

        // allocate 100 RDT to FeeAggregator
        await contractRDT.connect(deployer).mint(await contractFeeAggregator.getAddress(), 100);

        // allocate 200 GMA to SwapRouter
        await contractGMA.connect(deployer).transfer(await contractSwapRouterMock.getAddress(), 1200);

        await contract.connect(deployer)["collectFees(address[])"]([await contractWETH.getAddress(), await contractRDT.getAddress()]);
        const tokenBalance = await contractGMA.connect(deployer).balanceOf(await contract.getAddress());
        assert.equal(tokenBalance, BigInt(1200));
    });

    it("should be able to add pool", async () => {
        // add a reward pool with x1.00 boost
        let poolAAddress = await user1.getAddress();
        await contract.connect(deployer).addPool(poolAAddress, 100);

        let pools = await contract.connect(deployer).getPools();
        let poolABoost= await contract.connect(deployer).getPoolBoost(poolAAddress);

        assert.equal(pools.length, 1);
        assert.equal(pools[0], poolAAddress);
        assert.equal(poolABoost, 100);

        // add a reward pool with x1.50 boost
        let poolBAddress = await user2.getAddress();
        await contract.connect(deployer).addPool(poolBAddress, 150);

        pools = await contract.connect(deployer).getPools();
        let poolBBoost= await contract.connect(deployer).getPoolBoost(poolBAddress);

        assert.equal(pools.length, 2);
        assert.equal(pools[0], poolAAddress);
        assert.equal(pools[1], poolBAddress);
        assert.equal(poolABoost, 100);
        assert.equal(poolBBoost, 150);
    });

    it("should be able to remove pool", async () => {
        // add a reward pool with x1 boost
        let poolAAddress = await user1.getAddress();
        await contract.connect(deployer).addPool(poolAAddress, 100);
        // add a reward pool with x2 boost
        let poolBAddress = await user2.getAddress();
        await contract.connect(deployer).addPool(poolBAddress, 200);

        // remove pool A
        await contract.connect(deployer).removePool(poolAAddress);

        // TODO
        let pools = await contract.connect(deployer).getPools();
        assert.equal(pools.length, 1);
        assert.equal(pools[0], poolBAddress);
    });

    it("should revert distribution if pools are empty", async () => {
        let poolAAddress = await user1.getAddress();
        await contract.connect(deployer).addPool(poolAAddress, 100);
        
        // allocate 100 GMA to contract
        await contractGMA.connect(deployer).transfer(await contract.getAddress(), 100);

        const response = contract.connect(deployer).dispatchFees();
        await expect(response).to.be.revertedWith("RewardDispatcher: Sum of supply times boost must be greater than zero");
    });

    it("should perform distribute with one pool filled", async () => {
        // add a reward pool with x1 boost
        let poolAAddress = await user1.getAddress();
        await contract.connect(deployer).addPool(poolAAddress, 100);
        // add a reward pool with x2 boost
        let poolBAddress = await user2.getAddress();
        await contract.connect(deployer).addPool(poolBAddress, 200);
        // add a reward pool with x3 boost
        let poolCAddress = await user3.getAddress();
        await contract.connect(deployer).addPool(poolCAddress, 300);
        

        // allocate 1000 GMA to pool A
        await contractGMA.connect(deployer).transfer(poolAAddress, 1000);

        await contractGMA.connect(deployer).transfer(contract, 300);
        await contract.connect(deployer).dispatchFees();

        let balancePoolA = await contractGMA.connect(deployer).balanceOf(poolAAddress);
        let balancePoolB = await contractGMA.connect(deployer).balanceOf(poolBAddress);
        let balancePoolC = await contractGMA.connect(deployer).balanceOf(poolCAddress);
        
        assert.equal(balancePoolA, BigInt(1300));
        assert.equal(balancePoolB, BigInt(0));
        assert.equal(balancePoolC, BigInt(0));
    });

    it("should perform distribute", async () => {
        // add a reward pool with x1 boost
        let poolAAddress = await user1.getAddress();
        await contract.connect(deployer).addPool(poolAAddress, 100);
        // add a reward pool with x2 boost
        let poolBAddress = await user2.getAddress();
        await contract.connect(deployer).addPool(poolBAddress, 200);
        // add a reward pool with x3 boost
        let poolCAddress = await user3.getAddress();
        await contract.connect(deployer).addPool(poolCAddress, 300);
        

        // allocate 1000 GMA to pool A
        await contractGMA.connect(deployer).transfer(poolAAddress, 1000);
        // allocate 1000 GMA to pool B
        await contractGMA.connect(deployer).transfer(poolBAddress, 1000);
        // allocate 1000 GMA to pool C
        await contractGMA.connect(deployer).transfer(poolCAddress, 1000);

        await contractGMA.connect(deployer).transfer(contract, 300);
        await contract.connect(deployer).dispatchFees();

        let balancePoolA = await contractGMA.connect(deployer).balanceOf(poolAAddress);
        let balancePoolB = await contractGMA.connect(deployer).balanceOf(poolBAddress);
        let balancePoolC = await contractGMA.connect(deployer).balanceOf(poolCAddress);
        
        assert.equal(balancePoolA, BigInt(1050));
        assert.equal(balancePoolB, BigInt(1100));
        assert.equal(balancePoolC, BigInt(1150));
    });
});
