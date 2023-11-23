import { expect } from "chai";
import { ethers } from "hardhat";
import { ERC20GrandmaToken, ERC20GrandmaToken__factory, ERC20RewardPool, ERC20RewardPool__factory } from "../typechain-types";
import { Signer } from "ethers";

describe("ERC20RewardPool", function () {
    let factoryToken: ERC20GrandmaToken__factory;
    let contractToken: ERC20GrandmaToken;

    let factory: ERC20RewardPool__factory;
    let contract: ERC20RewardPool;
    let owner: Signer;
    let addr1: Signer;
    let addr2: Signer;
    let addrs: Signer[];

    beforeEach(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        factoryToken = await ethers.getContractFactory("ERC20GrandmaToken");
        contractToken = await factoryToken.deploy();

        factory = await ethers.getContractFactory("ERC20RewardPool");
        contract = await factory.deploy("Reward Pool", "RPL", await contractToken.getAddress(), 100);
    });

    describe("Deployment", function () {
        it("Deployment should initialize the ERC20RewardPool contract", async function () {
            expect(await contract.name()).to.equal("Reward Pool");
            expect(await contract.symbol()).to.equal("RPL");
            expect(await contract.asset()).to.equal(await contractToken.getAddress());
        });
    });

    describe("Convert to shares and contractTokens", function () {
        it("Should convert contractTokens to shares", async function () {
            const contractTokens = 1000; 
            const shares = await contract.convertToShares(contractTokens);
            expect(shares).to.equal(1000);
        });

        it("Should convert shares to contractTokens", async function () {
            const shares = 1000; // Replace with the desired amount of shares to convert
            const contractTokens = await contract.convertToAssets(shares);
            expect(contractTokens).to.equal(1000);
        });
    });
});
