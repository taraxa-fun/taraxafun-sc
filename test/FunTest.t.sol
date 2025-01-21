// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FunDeployer} from "../src/FunDeployer.sol";
import {FunEventTracker} from "../src/FunEventTracker.sol";
import {FunPool} from "../src/FunPool.sol";
import {FunStorage} from "../src/Storage.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FunLPManager} from "../src/FunLPManager.sol";


contract FunTest is Test {
    FunDeployer deployer;
    FunEventTracker eventTracker;
    FunPool pool;
    FunStorage funStorage;
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
        funStorage = new FunStorage();
        eventTracker = new FunEventTracker(address(funStorage));
        

        pool = new FunPool(
            address(implementation), 
            address(treasury), 
            address(eventTracker)
        );

        deployer = new FunDeployer(address(pool), address(treasury), address(funStorage), address(eventTracker));

        lpManager = new FunLPManager(address(pool), 1000);

        pool.addDeployer(address(deployer));
        pool.setLPManager(address(lpManager));
        funStorage.addDeployer(address(deployer));
        eventTracker.addDeployer(address(deployer));
        eventTracker.addDeployer(address(pool));
    }

    function test_createToken() public {
        deployer.createFun{value: 10000000}(
            "Test", 
            "TT", 
            "Test Token", 
            1000000000 ether,
            0, 
            0,
            0
        );

        FunStorage.FunDetails memory funTokenDetail = funStorage.getFunContract(0);
                                                                                
        uint256 amountOut = pool.getAmountOutTokens(funTokenDetail.funAddress, 300 ether);

        pool.buyTokens{value : 500 ether}(funTokenDetail.funAddress, amountOut, address(0x0));

        pool.getCurrentCap(funTokenDetail.funAddress);

    }
}
