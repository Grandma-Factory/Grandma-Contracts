
task("gma-balance", "Prints an account's balance")
  .addParam("contract", "The Grandma-Token contract address")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC777GrandmaToken");
    const token = await factory.attach(taskArgs.contract);
    const balance = await token.balanceOf(taskArgs.account);

    console.log(ethers.utils.formatEther(balance), "ETH");
  });

task("gma-transfer", "Transfer Grandma-Token")
  .addParam("contract", "The Grandma-Token contract address")
  .addParam("to", "The account's 'to' address")
  .addParam("amount", "The amount to transfer")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC777GrandmaToken");
    const token = await factory.attach(taskArgs.contract);

    await token.transfer(taskArgs.to, taskArgs.amount)
    console.log("Tokens transfered")
  });

task("gma-transferFrom", "Transfer Grandma-Token from")
  .addParam("contract", "The Grandma-Token contract address")
  .addParam("from", "The account's 'from' address")
  .addParam("to", "The account's 'to' address")
  .addParam("amount", "The amount to transfer")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC777GrandmaToken");
    const token = await factory.attach(taskArgs.contract);

    await token.transferFrom(taskArgs.from, taskArgs.to, taskArgs.amount)
    console.log("Tokens transfered")
  });
