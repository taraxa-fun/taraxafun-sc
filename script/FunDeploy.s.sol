// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

import {FunDeployer} from "../src/FunDeployer.sol";
import {FunEventTracker} from "../src/FunEventTracker.sol";
import {FunPool} from "../src/FunPool.sol";
import {FunStorage} from "../src/Storage.sol";
import {Multicall3} from "../src/Multicall3.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// forge script script/FunDeploy.s.sol --rpc-url https://base-sepolia-rpc.publicnode.com --broadcast --legacy

contract DeployTARAXAFUN is Script {
    
    FunDeployer deployer;
    FunEventTracker eventTracker;
    FunPool pool;
    FunStorage funStorage;
    Multicall3 multicall;
    SimpleERC20 implementation;

    address owner;
    address treasury;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);

        treasury = vm.envAddress("TREASURY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        implementation = new SimpleERC20();
        funStorage = new FunStorage();
        eventTracker = new FunEventTracker(address(funStorage));

        pool = new FunPool(
            address(implementation), 
            address(treasury),
            address(eventTracker) 
        );

        deployer = new FunDeployer(address(pool), address(treasury), address(funStorage), address(eventTracker));

        /// multicall = new Multicall3();

        pool.addDeployer(address(deployer));
        funStorage.addDeployer(address(deployer));
        eventTracker.addDeployer(address(deployer));
        eventTracker.addDeployer(address(pool));

        vm.stopBroadcast();

        console.log("Deployed FunDeployer at address: ", address(deployer));
        console.log("Deployed FunPool at address: ", address(pool));
        console.log("Deployed FunStorage at address: ", address(funStorage));
        console.log("Deployed FunEventTracker at address: ", address(eventTracker));
        // console.log("Deployed Multicall3 at address: ", address(multicall));
    }
}

