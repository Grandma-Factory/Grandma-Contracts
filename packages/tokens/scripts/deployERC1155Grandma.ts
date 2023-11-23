import { ethers } from "hardhat";

async function main() {

  const factory = await ethers.getContractFactory("ERC1155Grandma");
  const token = await factory.deploy();

  await token.deployed();
  console.log(`Grandma-NFT deployed! address: ` + token.address);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
