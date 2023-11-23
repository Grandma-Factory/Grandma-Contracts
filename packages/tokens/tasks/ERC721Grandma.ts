
task("gma-nft-mint", "Mint an NFT")
  .addParam("contract", "The Grandma-NFT contract address")
  .addParam("to", "The NFT receiver address")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC721Grandma");
    const token = await factory.attach(taskArgs.contract);

    await token.safeMint(taskArgs.to)
    console.log("NFT Minted successfully");
  });

task("gma-nft-metadata", "Get NFT metadata URI")
  .addParam("contract", "The Grandma-NFT contract address")
  .addParam("id", "The token ID")
  .setAction(async (taskArgs: any) => {
    const factory = await ethers.getContractFactory("ERC721Grandma");
    const token = await factory.attach(taskArgs.contract);

    console.log("NFT metadata URI: " + await token.tokenURI(taskArgs.id));
  });
