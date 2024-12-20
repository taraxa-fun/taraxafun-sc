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
Deployer      | 0xD950294a5a0b4587D47AA2bBc64A7174b1D231f1
Pool          | 0x1EDD23DfD4E61a7Ba9e4873c8F12C4e75E649b37
EventTracker  | 0xf967633662C308E8202d0374Df35db5D20010e52
SimpleERC20   | 0xDE9C7589dA391f2DdFAeEa42C48762c620E6Bd9a
FunStorage    | 0xFC401f302E64564952aC1562CC89D8fE099aDFa7
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