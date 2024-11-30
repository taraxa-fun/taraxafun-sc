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

    address usdcETH = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address wethETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address routerV2ETH = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

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
            address(implementation), address(treasury), address(treasury), usdcETH, address(eventTracker), 0
        );

        deployer = new FunDeployer(address(pool), address(treasury), address(funStorage), address(eventTracker));

        deployer.addBaseToken(wethETH);
        deployer.addBaseToken(usdcETH);
        deployer.addRouter(routerV2ETH);

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
            1000 ether,
            0, 
            address(wethETH), 
            address(routerV2ETH), 
            false, 
            0
        );

        FunStorage.FunDetails memory funTokenDetail = funStorage.getFunContract(0);

        pool.getCurrentCap(funTokenDetail.funAddress);

        (uint256 amountOut,) = pool.getAmountOutTokens(funTokenDetail.funAddress, 1 ether);

        pool.buyTokens{value : 1 ether}(funTokenDetail.funAddress, amountOut, address(0x0));

        (uint256 amountOut2,) = pool.getAmountOutETH(funTokenDetail.funAddress, IERC20(funTokenDetail.tokenAddress).balanceOf(address(owner)));

        // pool.sellTokens(funTokenDetail.funAddress, IERC20(funTokenDetail.tokenAddress).balanceOf(address(owner)), amountOut2, address(0x0));

        owner.balance;
    }
}
