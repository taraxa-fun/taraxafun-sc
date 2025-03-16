// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FunDeployer} from "../src/FunDeployer.sol";
import {FunPool} from "../src/FunPool.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FunLPManager} from "../src/FunLPManager.sol";


contract FunTest is Test {
    FunDeployer deployer;
    FunPool pool;
    SimpleERC20 implementation;
    FunLPManager lpManager;

    address owner;
    address treasury;
    address user1;
    address user2;

    function setUp() public {
        uint256 forkId = vm.createFork("https://rpc.mainnet.taraxa.io");
        vm.selectFork(forkId);

        owner = vm.addr(1);
        treasury = vm.addr(2);
        user1 = vm.addr(3);
        user2 = vm.addr(4);

        vm.deal(owner, 1000000000 ether);
        vm.deal(user1, 1000000000 ether);
        vm.deal(user2, 1000000000 ether);

        vm.startPrank(owner);

        implementation = new SimpleERC20();
        
        pool = new FunPool(
            address(implementation), 
            address(treasury)
        );

        deployer = new FunDeployer(address(pool), address(treasury));

        lpManager = new FunLPManager(address(pool), address(treasury), 5000);

        pool.addDeployer(address(deployer));
        pool.setLPManager(address(lpManager));
    }

    function test_createToken() public {
        deployer.createFun{value: 500 ether}(
            "Test", 
            "TEST", 
            "Test Token", 
            1000000000 ether,
            0, 
            0,
            0
        );

        address funAdress = deployer.funContracts(0);


        pool.getCurrentCap(funAdress);
                                                                                
        uint256 amountOut = pool.getAmountOutTokens(funAdress, 890000 ether);

        pool.buyTokens{value : 1000000 ether}(funAdress, amountOut, address(0x0));

        pool.getCurrentCap(funAdress);

    }
}
