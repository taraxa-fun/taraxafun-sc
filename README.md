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
Deployer      | 0xc749f3f6e8f007efFeD546CAf16936556F538E23
Pool          | 0x156E72c5e3DB665489D477BDF5dD5F91d0F747D3
EventTracker  | 0x9b5EB03c134836CEe8Bf01a4f399082DF64C8397
SimpleERC20   | 0x4dAe95825B182Fb573cC2F2Ee5C5fC133F812e5b
FunStorage    | 0x4De21bdB26D73f39d916AC9D2aF0DcbDbe2244f3
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