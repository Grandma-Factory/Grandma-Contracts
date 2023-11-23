
import { expect } from "chai";
import { ethers } from "hardhat";
import { ERC777GrandmaToken, ERC777GrandmaToken__factory } from "../typechain-types";
import { Signer } from "ethers";


describe("ERC777GrandmaToken", function () {

  let totalSupply = '10000000000000000000000000000';
  let factory: ERC777GrandmaToken__factory;
  let gmaToken: ERC777GrandmaToken;
  let owner: Signer;
  let addr1: Signer;
  let addr2: Signer;
  let addrs: Signer[];

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    factory = await ethers.getContractFactory("ERC777GrandmaToken");
    gmaToken = await factory.deploy([]);
  });

  describe("Deployment", function () {
    it("Deployment should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await gmaToken.balanceOf(owner);
      expect(ownerBalance.toString()).to.equal(totalSupply);
      expect(await gmaToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {

    it("Should transfer tokens between accounts", async function () {
      const ownerBalance = await gmaToken.balanceOf(owner);

      // send 100 token to addr1
      await gmaToken.transfer(addr1, 100);
      expect(await gmaToken.balanceOf(addr1)).to.equal(100);

      // send 100 token from addr1 to addr2
      await gmaToken.connect(addr1).transfer(addr2, 100);
      expect(await gmaToken.balanceOf(addr1)).to.equal(0);
      expect(await gmaToken.balanceOf(addr2)).to.equal(100);
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      const initialOwnerBalance = await gmaToken.balanceOf(owner);

      // Try to send 1 token from addr1 to owner.
      await expect(
        gmaToken.connect(addr1).transfer(owner, 1)
      ).to.be.revertedWith("ERC777: transfer amount exceeds balance");

      // Owner balance shouldn't have changed.
      expect(await gmaToken.balanceOf(owner)).to.equal(
        initialOwnerBalance
      );
    });
  });
});
