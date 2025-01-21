// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IFunPool} from "./interfaces/IFunPool.sol";
import {IFunStorageInterface} from "./interfaces/IFunStorageInterface.sol";
import {IFunEventTracker} from "./interfaces/IFunEventTracker.sol";

contract FunDeployer is Ownable {

    event funCreated(
        address indexed creator,
        address indexed funContract,
        address indexed tokenAddress,
        string name,
        string symbol,
        string data,
        uint256 totalSupply,
        uint256 initialReserve,
        uint256 timestamp
    );

    event royal(
        address indexed tokenAddress, 
        uint256 liquidityAmount,
        uint256 tokenAmount, 
        uint256 time, 
        uint256 totalVolume
    );

    address public feeWallet;
    address public funStorage;
    address public eventTracker;
    address public funPool;

    /// deployment fee in wei
    uint256 public deploymentFee = 10000000; 
    // base of 10000 -> 500 equals 5%
    uint256 public antiSnipePer = 500; 
    // base of 10000 -> 1000 equals 10%
    uint256 public affiliatePer = 1000; 
    // base of 10000 -> 1000 means 10%
    uint256 public devFeePer = 1000; 
    // base of 10000 -> 100 equals 1%
    uint256 public tradingFeePer = 100; 
    // listing marketcap in $USD
    uint256 public listThreshold = 10; 
    /// virtual liquidity
    uint256 public initialReserveTARA = 100 ether; 

    mapping(address => uint256) public affiliateSpecialPer;
    mapping(address => bool) public affiliateSpecial;

    constructor(
        address _funPool, 
        address _feeWallet, 
        address _funStorage, 
        address _eventTracker
    ) Ownable(msg.sender) {
        funPool = _funPool;
        feeWallet = _feeWallet;
        funStorage = _funStorage;
        eventTracker = _eventTracker;
    }

    function createFun(
        string memory _name,
        string memory _symbol,
        string memory _data,
        uint256 _totalSupply,
        uint256 _liquidityETHAmount,
        uint256 _amountAntiSnipe,
        uint256 _maxBuyPerWallet
    ) public payable {
        require(_amountAntiSnipe <= ((initialReserveTARA * antiSnipePer) / 10000), "over antisnipe restrictions");
        require(msg.value >= (deploymentFee + _liquidityETHAmount + _amountAntiSnipe), "fee amount error");

        if (_maxBuyPerWallet == 0) {
            _maxBuyPerWallet = _totalSupply;
        }

        (bool feeSuccess,) = feeWallet.call{value: deploymentFee}("");
        require(feeSuccess, "creation fee failed");

        address funToken = IFunPool(funPool).initFun{value: _liquidityETHAmount}(
            [_name, _symbol], _totalSupply, msg.sender, [listThreshold, initialReserveTARA], _maxBuyPerWallet
        );

        IFunStorageInterface(funStorage).addFunContract(
            msg.sender, (funToken), funToken, _name, _symbol, _data, _totalSupply, _liquidityETHAmount
        );

        IFunEventTracker(eventTracker).createFunEvent(
            msg.sender,
            (funToken),
            (funToken),
            _name,
            _symbol,
            _data,
            _totalSupply,
            initialReserveTARA + _liquidityETHAmount,
            block.timestamp
        );

        if (_amountAntiSnipe > 0) {
            IFunPool(funPool).buyTokens{value: _amountAntiSnipe}(funToken, 0, msg.sender);
            IERC20(funToken).transfer(msg.sender, IERC20(funToken).balanceOf(address(this)));
        }

        emit funCreated(
            msg.sender,
            (funToken),
            (funToken),
            _name,
            _symbol,
            _data,
            _totalSupply,
            initialReserveTARA + _liquidityETHAmount,
            block.timestamp
        );
    }

    function getTradingFeePer() public view returns (uint256) {
        return tradingFeePer;
    }

    function getAffiliatePer(address _affiliateAddrs) public view returns (uint256) {
        if (affiliateSpecial[_affiliateAddrs]) {
            return affiliateSpecialPer[_affiliateAddrs];
        } else {
            return affiliatePer;
        }
    }

    function getDevFeePer() public view returns (uint256) {
        return devFeePer;
    }

    function getSpecialAffiliateValidity(address _affiliateAddrs) public view returns (bool) {
        return affiliateSpecial[_affiliateAddrs];
    }

    function setDeploymentFee(uint256 _newdeploymentFee) public onlyOwner {
        require(_newdeploymentFee > 0, "invalid fee");
        deploymentFee = _newdeploymentFee;
    }

    function setDevFeePer(uint256 _newOwnerFee) public onlyOwner {
        require(_newOwnerFee > 0, "invalid fee");
        devFeePer = _newOwnerFee;
    }

    function setSpecialAffiliateData(address _affiliateAddrs, bool _status, uint256 _specialPer) public onlyOwner {
        affiliateSpecial[_affiliateAddrs] = _status;
        affiliateSpecialPer[_affiliateAddrs] = _specialPer;
    }

    function setInitReserveTARA(uint256 _newVal) public onlyOwner {
        require(_newVal > 0, "invalid reserve");
        initialReserveTARA = _newVal;
    }

    function setFunPool(address _newfunPool) public onlyOwner {
        require(_newfunPool != address(0), "invalid pool");
        funPool = _newfunPool;
    }

    function setFeeWallet(address _newFeeWallet) public onlyOwner {
        require(_newFeeWallet != address(0), "invalid wallet");
        feeWallet = _newFeeWallet;
    }

    function setStorageContract(address _newStorageContract) public onlyOwner {
        require(_newStorageContract != address(0), "invalid storage");
        funStorage = _newStorageContract;
    }

    function setEventContract(address _newEventContract) public onlyOwner {
        require(_newEventContract != address(0), "invalid event");
        eventTracker = _newEventContract;
    }

    function setListThreshold(uint256 _newListThreshold) public onlyOwner {
        require(_newListThreshold > 0, "invalid threshold");
        listThreshold = _newListThreshold;
    }

    function setAntiSnipePer(uint256 _newAntiSnipePer) public onlyOwner {
        require(_newAntiSnipePer > 0, "invalid antisnipe");
        antiSnipePer = _newAntiSnipePer;
    }

    function setAffiliatePer(uint256 _newAffPer) public onlyOwner {
        require(_newAffPer > 0, "invalid affiliate");
        affiliatePer = _newAffPer;
    }

    function emitRoyal(
        address tokenAddress,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 time,
        uint256 totalVolume
    ) public {
        require(msg.sender == funPool, "invalid caller");
        emit royal(tokenAddress, liquidityAmount, tokenAmount, time, totalVolume);
    }
}
