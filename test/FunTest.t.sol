// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FunDeployer} from "../src/Deployer.sol";
import {FunEventTracker} from "../src/EventTracker.sol";
import {FunPool} from "../src/Pool.sol";
import {FunStorage} from "../src/Storage.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FunTest is Test {
    FunDeployer deployer;
    FunEventTracker eventTracker;
    FunPool pool;
    FunStorage funStorage;
    SimpleERC20 implementation;

    address owner;
    address treasury;
    address user1;
    address user2;

    address usdcETH = 0xcF81A5750F3c08B64eDaDD0D78Fb37a4aB5252c0;
    address wethSEP = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address routerV3SEP = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    function setUp() public {
        uint256 forkId = vm.createFork("https://ethereum-rpc.publicnode.com");
        vm.selectFork(forkId);

        owner = vm.addr(1);
        treasury = vm.addr(2);
        user1 = vm.addr(3);
        user2 = vm.addr(4);

        vm.deal(owner, 10 ether);
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.startPrank(owner);

        implementation = new SimpleERC20();
        funStorage = new FunStorage();
        eventTracker = new FunEventTracker(address(funStorage));

        pool = new FunPool(
            address(implementation), 
            address(treasury),
            address(treasury), 
            usdcETH, 
            address(eventTracker), 
            0
        );

        deployer = new FunDeployer(address(pool), address(treasury), address(funStorage), address(eventTracker));

        deployer.addBaseToken(wethSEP);
        deployer.addRouter(routerV3SEP);

        pool.addDeployer(address(deployer));
        funStorage.addDeployer(address(deployer));
        eventTracker.addDeployer(address(deployer));
        eventTracker.addDeployer(address(pool));
    }

    function test_createToken() public {
        deployer.CreateFun{value: 10000000}(
            "TestToken", 
            "TT", 
            "Test Token DATA", 
            1000000000 ether,
            0, 
            false, 
            0,
            0
        );

        FunStorage.FunDetails memory funTokenDetail = funStorage.getFunContract(0);

        pool.getCurrentCap(funTokenDetail.funAddress);

        uint256 amountOut = pool.getAmountOutTokens(funTokenDetail.funAddress, .1 ether);

        /// pool.buyTokens{value : .1 ether}(funTokenDetail.funAddress, amountOut, address(0x0));


        /// uint256 amountOut2 = pool.getAmountOutETH(funTokenDetail.funAddress, IERC20(funTokenDetail.tokenAddress).balanceOf(address(owner)));

        // pool.sellTokens(funTokenDetail.funAddress, IERC20(funTokenDetail.tokenAddress).balanceOf(address(owner)), amountOut2, address(0x0));

        // owner.balance;
    }
}
