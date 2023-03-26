
task("gma-1155-mint", "Mint an NFT")
  .addParam("contract", "The contract address")
  .addParam("to", "The receiver address")
  .addParam("id", "The token id")
  .addParam("amount", "The amount to mint")
  .addParam("data", "The amount to mint")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC1155Grandma");
    const token = await factory.attach(taskArgs.contract);

    await token.mint(taskArgs.to, parseInt(taskArgs.id), parseInt(taskArgs.amount), ethers.utils.hexlify(parseInt(taskArgs.data)));
    console.log("Minted successfully");
  });

task("gma-1155-metadata", "Get metadata URI")
  .addParam("contract", "The contract address")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC1155Grandma");
    const token = await factory.attach(taskArgs.contract);

    console.log("Metadata URI: " + await token.uri(0));
  });


task("gma-1155-set-metadata", "Set metadata URI")
  .addParam("contract", "The contract address")
  .addParam("uri", "The uri to set")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC1155Grandma");
    const token = await factory.attach(taskArgs.contract);
    await token.setURI(taskArgs.uri);
    console.log("metadata updated successfully");
  });
