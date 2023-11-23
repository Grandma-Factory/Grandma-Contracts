import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
};