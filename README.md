# Taraxa-fun Smart Contracts

## Overview

Taraxa.fun smart contracts enable users to deploy their own tokens in one click and trade them through an automated liquidity system powered by UniswapV3. The platform features a streamlined token creation process, automated market making, and LP fee management.

## Contracts

* `FunDeployer.sol`: Token deployment contract
* `FunPool.sol`: Trading and token listing management
* `SimpleERC20.sol`: ERC-20 implementation for token deployment
* `FunLPManager.sol`: UniswapV3 LP lock and fee claims

## Deployed Addresses

### Taraxa Mainnet
```solidity
Deployer      | 0x0E94575E54bb2c1755eB3Cf684Adda8eacFDAD87
Pool          | 0x10e8fCE09e9c1F990F9452853d8dBc0cA9c39B0a
SimpleERC20   | 0xe1ac50e0cece63c24ab24311be5a6b8eb67bfc2f
FunLPManager  | 0xD613EE5b1FB38e275A13da9a0e8D173Bfac328a0
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
* `test/FunTest.t.sol`: Contracts tests suite

## Acknowledgments

* Special Thanks to [Taraxa](https://taraxa.io) Foundation for the grant
* Contracts originally forked from [dx.fun](https://www.dx.fun/)

⚠️ **WARNING: These contracts are not audited. Use at your own risk.**