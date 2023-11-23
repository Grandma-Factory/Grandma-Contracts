import { ethers, network } from "hardhat";
import { assert } from "chai";
import { Exchange, Exchange__factory, ERC20GrandmaToken, ERC20GrandmaToken__factory } from "../typechain-types";
import { Signer } from "ethers";



describe("FeeAggregator", () => {
    const exchangeFee = 200; // 2% fee in ETH
    const exchangeFeeGMA = 100; // 1% fee in GMA

    let factoryToken: ERC20GrandmaToken__factory;
    let contractToken: ERC20GrandmaToken;

    let factoryExchange: Exchange__factory;
    let contractExchange: Exchange;
    
    let deployer: Signer;
    let user1: Signer;
    let user2: Signer;
    let user3: Signer;
    let collector = "0x0000000000000000000000000000000000001337";

    beforeEach(async () => {
        [deployer, user1, user2, user3] = await ethers.getSigners();

        // reset collector balance
        await network.provider.send("hardhat_setBalance", [
            collector,
            "0x0",
        ]);

        // deploy GMA
        factoryToken = await ethers.getContractFactory("ERC20GrandmaToken", deployer)
        contractToken = await factoryToken.deploy();

        // deploy Exchange
        factoryExchange = await ethers.getContractFactory("Exchange", deployer)
        contractExchange = await factoryExchange.deploy(contractToken.address);

        await contractExchange.waitForDeployment();
    });

    it("should be able to deploy the contract", async () => {
        assert.exists(await contractExchange.getAddress());
    });

});
