import { ethers } from "hardhat";

async function main() {

  const factory = await ethers.getContractFactory("ERC1155GrandmaReward");
  const token = await factory.deploy("0x595459307ed4189D5bE3E94fB9c25A1e177330cA");

  await token.deployed();
  console.log(`Grandma-Reward deployed! address: ` + token.address);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
