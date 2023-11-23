
import { expect } from "chai";
import { ethers } from "hardhat";
import { ERC20Vault, ERC20Vault__factory } from "../typechain-types";
import { Signer } from "ethers";

describe("ERC20Vault", function () {
  let factory: ERC20Vault__factory;
  let erc20Vault: ERC20Vault;
  let owner: Signer;
  let addr1: Signer;
  let addr2: Signer;
  let addrs: Signer[];

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    factory = await ethers.getContractFactory("ERC20Vault");
    erc20Vault = await factory.deploy("Test Vault", "TV", [owner, addr1], [40, 60]);
  });

  describe("Deployment", function () {
    it("Deployment should assign the total supply of tokens to the token holders", async function () {
      const ownerBalance = await erc20Vault.balanceOf(owner);
      const addr1Balance = await erc20Vault.balanceOf(addr1);

      expect(ownerBalance).to.equal(BigInt(40000000000000000000));
      expect(addr1Balance).to.equal(BigInt(60000000000000000000));
      expect(await erc20Vault.totalSupply()).to.equal(ownerBalance + addr1Balance);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      const ownerBalance = await erc20Vault.balanceOf(owner);

      // Transfer 100 tokens from owner to addr1
      await erc20Vault.transfer(addr1, BigInt(40000000000000000000));
      expect(await erc20Vault.balanceOf(addr1)).to.equal(BigInt(100000000000000000000));

      // Transfer 100 tokens from addr1 to addr2
      await erc20Vault.connect(addr1).transfer(addr2, BigInt(100000000000000000000));
      expect(await erc20Vault.balanceOf(addr1)).to.equal(0);
      expect(await erc20Vault.balanceOf(addr2)).to.equal(BigInt(100000000000000000000));
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      const initialOwnerBalance = await erc20Vault.balanceOf(owner);

      // Try to transfer 1 token from addr1 to owner
      await expect(
        erc20Vault.connect(addr2).transfer(owner, 1)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

      // Owner balance shouldn't have changed
      expect(await erc20Vault.balanceOf(owner)).to.equal(initialOwnerBalance);
    });
  });
});
