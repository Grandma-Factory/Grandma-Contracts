import { ethers } from "hardhat";

async function main() {

  const factory = await ethers.getContractFactory("ERC777GrandmaToken");
  const token = await factory.deploy([]);

  await token.deployed();
  console.log(`Grandma-Token deployed! address: ` + token.address);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
