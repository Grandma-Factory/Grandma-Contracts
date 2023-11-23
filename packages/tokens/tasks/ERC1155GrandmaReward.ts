
task("gma-reward-create-pool", "Create reward pool")
  .addParam("contract", "The contract address")
  .addParam("name", "The pool name")
  .addParam("opened", "The pool status")
  .addParam("mincap", "The pool min cap")
  .addParam("boost", "The pool boost")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC1155GrandmaReward");
    const token = await factory.attach(taskArgs.contract);

    const name = taskArgs.name;
    const opened = taskArgs.opened.toLowerCase() === "true";
    const mincap = parseInt(taskArgs.mincap);
    const boost = parseInt(taskArgs.boost);

    await token.createPool(name, opened, mincap, boost);
    console.log("Created successfully");
  });
