# Taraxa-fun Smart Contracts

## Overview

Taraxa.fun smart contracts enable users to deploy their own tokens in one click and trade them through an automated liquidity system powered by UniswapV3. The platform features a streamlined token creation process, automated market making, and LP fee management.

## Contracts

* `FunDeployer.sol`: Token deployment contract
* `FunPool.sol`: Trading and token listing management
* `FunEventTracker.sol`: Trading logs for backend tracking
* `SimpleERC20.sol`: ERC-20 implementation for token deployment
* `FunStorage.sol`: Token information storage contract
* `FunLPManager.sol`: UniswapV3 LP management and fee claims

## Deployed Addresses

### Base Sepolia Testnet
```solidity
Deployer      | 0xdd3Ae92998b45da685509b34b716CaEe88981f5A
Pool          | 0xBb1B4FC6e48186Ff4E923ceB2941dB0443479c51
EventTracker  | 0x55447dCcCf7E32413025200Ad74C21596C766D3B
SimpleERC20   | 0x86bd80c78fEd7321AB30bFb68d579E0EEC9d6EBe
FunStorage    | 0xA4b5d3C2223181Eeb55791317056C3F608d98Da9
FunLPManager  | 0x4De21bdB26D73f39d916AC9D2aF0DcbDbe2244f3
```

### Taraxa Mainnet
```solidity
Deployer      | 0x
Pool          | 0x
EventTracker  | 0x
SimpleERC20   | 0x
FunStorage    | 0x
FunLPManager  | 0x
```

## Development

### Prerequisites
* [Foundry](https://getfoundry.sh/)

### Installation
```bash
forge install
```

### Build
```bash
forge build
```

### Test
```bash
forge test
```

### Deploy
```bash
forge script script/FunDeploy.s.sol --rpc-url <network-rpc> --broadcast --legacy
```

### Scripts
* `script/FunDeploy.s.sol`: Deploy all contracts
* `test/FunTest.t.sol`: Contract test suite

## Acknowledgments

* Special Thanks to [Taraxa](https://taraxa.io) Foundation for the grant
* Contracts originally forked from [dx.fun](https://www.dx.fun/)

⚠️ **WARNING: These contracts are not audited. Use at your own risk.**