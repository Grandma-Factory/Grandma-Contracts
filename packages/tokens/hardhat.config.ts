import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

// plugins for testing purpose
import "hardhat-erc1820";

// import task
require("./tasks/ERC777GrandmaToken");
require("./tasks/ERC721Grandma");
require("./tasks/ERC1155Grandma");
require("./tasks/ERC1155GrandmaReward");

require('dotenv').config({ path: require('find-config')('.env') })

const config: HardhatUserConfig = {
  solidity: "0.8.20", 
  overrides: {
    "contracts/tokens/ERC777GrandmaToken.sol": {
      version: "0.8.17"
    }
  },
  etherscan: {
    apiKey: process.env.ETHSCAN_API_KEY,
  },
  networks: {
    hardhat: {
      chainId: 1337, // default is 31337
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_SEPOLIA_API_KEY}`,
      accounts: [process.env.SEPOLIA_PRIVATE_KEY],
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_API_KEY}`,
      accounts: [process.env.GOERLI_PRIVATE_KEY],
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_MAINNET_API_KEY}`,
      accounts: [process.env.MAINNET_PRIVATE_KEY],
    },
  }
};

export default config;
