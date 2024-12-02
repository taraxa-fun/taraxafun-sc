// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

import {FunDeployer} from "../src/Deployer.sol";
import {FunEventTracker} from "../src/EventTracker.sol";
import {FunPool} from "../src/Pool.sol";
import {FunStorage} from "../src/Storage.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployTARAXAFUN is Script {
    FunDeployer deployer;
    FunEventTracker eventTracker;
    FunPool pool;
    FunStorage funStorage;
    SimpleERC20 implementation;

    address owner;
    address treasury;

    address usdcETH = 0xcF81A5750F3c08B64eDaDD0D78Fb37a4aB5252c0;
    address wethSEP = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address routerV3SEP = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);

        treasury = vm.envAddress("TREASURY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        vm.stopBroadcast();
    }
}
