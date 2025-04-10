// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

import {FunDeployer} from "../src/FunDeployer.sol";
import {FunPool} from "../src/FunPool.sol";
import {Multicall3} from "../src/Multicall3.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FunLPManager} from "../src/FunLPManager.sol";

contract DeployTARAXAFUN is Script {
    
    FunDeployer deployer;
    FunPool pool;
    Multicall3 multicall;
    SimpleERC20 implementation;
    FunLPManager lpManager;

    address owner;
    address treasury;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);

        treasury = vm.envAddress("TREASURY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        implementation = new SimpleERC20();

        pool = new FunPool(
            address(implementation), 
            address(treasury)
        );

        deployer = new FunDeployer(address(pool), address(treasury));
        lpManager = new FunLPManager(address(0x10e8fCE09e9c1F990F9452853d8dBc0cA9c39B0a), address(treasury), 5000);

        multicall = new Multicall3();

        pool.addDeployer(address(deployer));
        pool.setLPManager(address(lpManager));

        vm.stopBroadcast();

        console.log("Deployed FunDeployer at address: ", address(deployer));
        console.log("Deployed FunPool at address: ", address(pool));
        console.log("Deployed FunLPManager at address: ", address(lpManager));
        console.log("Deployed Multicall3 at address: ", address(multicall));
    }
}

