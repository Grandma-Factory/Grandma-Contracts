
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC777GrandmaToken", function () {

  let totalSupply = '10000000000000000000000000000';
  let factory: any;
  let gmaToken: any;
  let owner: any;
  let addr1: any;
  let addr2: any;
  let addrs: any;

  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    factory = await ethers.getContractFactory("ERC777GrandmaToken");
    gmaToken = await factory.deploy([]);
  });

  describe("Deployment", function () {
    it("Deployment should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await gmaToken.balanceOf(owner.address);
      expect(ownerBalance.toString()).to.equal(totalSupply);
      expect(await gmaToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {

    it("Should transfer tokens between accounts", async function () {
      const ownerBalance = await gmaToken.balanceOf(owner.address);

      // send 100 token to addr1
      await gmaToken.transfer(addr1.address, 100);
      expect(await gmaToken.balanceOf(addr1.address)).to.equal(100);

      // send 100 token from addr1 to addr2
      await gmaToken.connect(addr1).transfer(addr2.address, 100);
      expect(await gmaToken.balanceOf(addr1.address)).to.equal(0);
      expect(await gmaToken.balanceOf(addr2.address)).to.equal(100);
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      const initialOwnerBalance = await gmaToken.balanceOf(owner.address);

      // Try to send 1 token from addr1 to owner.
      await expect(
        gmaToken.connect(addr1).transfer(owner.address, 1)
      ).to.be.revertedWith("ERC777: transfer amount exceeds balance");

      // Owner balance shouldn't have changed.
      expect(await gmaToken.balanceOf(owner.address)).to.equal(
        initialOwnerBalance
      );
    });
  });
});
