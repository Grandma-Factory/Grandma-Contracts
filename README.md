# Grandma-Contracts Hardhat Project

This project contains all Grandma-Factory platform smart-contracts.



## Installation 

Install node dependencies

```
npm install
```

Create the environment configuration file ```.env```

```
ETHSCAN_API_KEY="..."
ALCHEMY_MAINNET_API_KEY="..."
ALCHEMY_SEPOLIA_API_KEY="..."
MAINNET_PRIVATE_KEY="..."
SEPOLIA_PRIVATE_KEY="..."
...
```


## Usage


Run tests:

```
npx hardhat test
```

Run compilation:


```
npx hardhat compile
```

Deploy Grandma-Token example:


```
npx hardhat run --network sepolia scripts/deployGrandmaToken.ts
```


## Security

If you detect any security flaw, please contact us at **security@grandma.digital**
