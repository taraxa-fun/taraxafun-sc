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
        address indexed funContract,
        address indexed tokenAddress,
        address indexed router,
        address baseAddress,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 _time,
        uint256 totalVolume
    );

    address public creationFeeDistributionContract;
    address public funStorage;
    address public eventTracker;
    address public funPool;
    uint256 public teamFee = 10000000; // value in wei
    uint256 public teamFeePer = 100; // base of 10000 -> 100 equals 1%
    uint256 public ownerFeePer = 1000; // base of 10000 -> 1000 means 10%
    uint256 public listThreshold = 1200000000000; // value in ether -> 12000 means 12000 tokens(any decimal place)
    uint256 public antiSnipePer = 5; // base of 100 -> 5 equals 5%
    uint256 public affiliatePer = 1000; // base of 10000 -> 1000 equals 10%
    uint256 public supplyValue = 1000 ether;
    uint256 public initialReserveEth = 1 ether;
    uint256 public curveFactor = 0.005 ether;
    uint256 public routerCount;
    uint256 public baseCount;
    bool public supplyLock = true;
    bool public curveFactorLock = true;
    bool public lpBurn = true;
    mapping(address => bool) public routerValid;
    mapping(address => bool) public routerAdded;
    mapping(uint256 => address) public routerStorage;
    mapping(address => bool) public baseValid;
    mapping(address => bool) public baseAdded;
    mapping(uint256 => address) public baseStorage;
    mapping(address => uint256) public affiliateSpecialPer;
    mapping(address => bool) public affiliateSpecial;
    constructor(
        address _funPool,
        address _creationFeeContract,
        address _funStorage,
        address _eventTracker
    ) Ownable(msg.sender) {
        funPool = _funPool;
        creationFeeDistributionContract = _creationFeeContract;
        funStorage = _funStorage;
        eventTracker = _eventTracker;
    }

    function CreateFun(
        string memory _name,
        string memory _symbol,
        string memory _data,
        uint256 _totalSupply,
        uint256 _liquidityETHAmount,
        address _baseToken,
        address _router,
        bool _antiSnipe,
        uint256 _amountAntiSnipe,
        uint256 _curveFactor,
        bool _isLinearCurve
    ) public payable {
        require(routerValid[_router], "invalid router");
        require(baseValid[_baseToken], "invalid base token");

        if (supplyLock) {
            require(_totalSupply == supplyValue, "invalid supply");
        }
        if (_antiSnipe) {
            require(_amountAntiSnipe > 0, "invalid antisnipe value");
        }
        if (!_isLinearCurve) {
            require(_curveFactor > 0, "invalid factor");
            if (curveFactorLock){
                require(_curveFactor == curveFactor, "invalid curve factor");
            }
        }

        require(
            _amountAntiSnipe <= ((initialReserveEth * antiSnipePer) / 100),
            "over antisnipe restrictions"
        );

        require(
            msg.value >= (teamFee + _liquidityETHAmount + _amountAntiSnipe),
            "fee amount error"
        );

        (bool feeSuccess, ) = creationFeeDistributionContract.call{
            value: teamFee
        }("");
        require(feeSuccess, "creation fee failed");

        address funToken = IFunPool(funPool).createFun{
            value: _liquidityETHAmount
        }(
            [_name, _symbol],
            _totalSupply,
            msg.sender,
            _baseToken,
            _router,
            [listThreshold, initialReserveEth],
            lpBurn,
            _curveFactor,
            _isLinearCurve ? IFunPool.CurveType.LINEAR : IFunPool.CurveType.EXPONENTIAL
        );
        IFunStorageInterface(funStorage).addFunContract(
            msg.sender,
            (funToken),
            funToken,
            address(_router),
            _name,
            _symbol,
            _data,
            _totalSupply,
            _liquidityETHAmount
        );

        if (_antiSnipe) {
            IFunPool(funPool).buyTokens{value: _amountAntiSnipe}(
                funToken,
                0,
                msg.sender
            );
            IERC20(funToken).transfer(
                msg.sender,
                IERC20(funToken).balanceOf(address(this))
            );
        }
        IFunEventTracker(eventTracker).createFunEvent(
            msg.sender,
            (funToken),
            (funToken),
            _name,
            _symbol,
            _data,
            _totalSupply,
            initialReserveEth + _liquidityETHAmount,
            block.timestamp
        );
        emit funCreated(
            msg.sender,
            (funToken),
            (funToken),
            _name,
            _symbol,
            _data,
            _totalSupply,
            initialReserveEth + _liquidityETHAmount,
            block.timestamp
        );
    }

    function updateTeamFee(uint256 _newTeamFeeInWei) public onlyOwner {
        teamFee = _newTeamFeeInWei;
    }
    function updateownerFee(uint256 _newOwnerFeeBaseTenK) public onlyOwner {
        ownerFeePer = _newOwnerFeeBaseTenK;
    }

    function updateSpecialAffiliateData(
        address _affiliateAddrs,
        bool _status,
        uint256 _specialPer
    ) public onlyOwner {
        affiliateSpecial[_affiliateAddrs] = _status;
        affiliateSpecialPer[_affiliateAddrs] = _specialPer;
    }

    function getAffiliatePer(
        address _affiliateAddrs
    ) public view returns (uint256) {
        if (affiliateSpecial[_affiliateAddrs]) {
            return affiliateSpecialPer[_affiliateAddrs];
        } else {
            return affiliatePer;
        }
    }
    function getOwnerPer() public view returns (uint256) {
        return ownerFeePer;
    }
    function getSpecialAffiliateValidity(
        address _affiliateAddrs
    ) public view returns (bool) {
        return affiliateSpecial[_affiliateAddrs];
    }
    function updateSupplyValue(uint256 _newSupplyVal) public onlyOwner {
        supplyValue = _newSupplyVal;
    }
    function updateInitResEthVal(uint256 _newVal) public onlyOwner {
        initialReserveEth = _newVal;
    }
    function stateChangeSupplyLock(bool _lockState) public onlyOwner {
        supplyLock = _lockState;
    }
    function addRouter(address _routerAddress) public onlyOwner {
        require(!routerAdded[_routerAddress], "already added");
        routerAdded[_routerAddress] = true;
        routerValid[_routerAddress] = true;
        routerStorage[routerCount] = _routerAddress;
        routerCount++;
    }

    function disableRouter(address _routerAddress) public onlyOwner {
        require(routerAdded[_routerAddress], "not added");
        require(routerValid[_routerAddress], "not valid");
        routerValid[_routerAddress] = false;
    }
    function enableRouter(address _routerAddress) public onlyOwner {
        require(routerAdded[_routerAddress], "not added");
        require(!routerValid[_routerAddress], "already enabled");
        routerValid[_routerAddress] = true;
    }
    function addBaseToken(address _baseTokenAddress) public onlyOwner {
        require(!baseAdded[_baseTokenAddress], "already added");
        baseAdded[_baseTokenAddress] = true;
        baseValid[_baseTokenAddress] = true;
        baseStorage[baseCount] = _baseTokenAddress;
        baseCount++;
    }

    function disableBaseToken(address _baseTokenAddress) public onlyOwner {
        require(baseAdded[_baseTokenAddress], "not added");
        require(baseValid[_baseTokenAddress], "not valid");
        baseValid[_baseTokenAddress] = false;
    }
    function enableBasetoken(address _baseTokenAddress) public onlyOwner {
        require(baseAdded[_baseTokenAddress], "not added");
        require(!baseValid[_baseTokenAddress], "already enabled");
        baseValid[_baseTokenAddress] = true;
    }
    function updateFunData(
        uint256 _ownerFunCount,
        string memory _newData
    ) public {
        IFunStorageInterface(funStorage).updateData(
            msg.sender,
            _ownerFunCount,
            _newData
        );
    }

    function updateFunPool(address _newfunPool) public onlyOwner {
        funPool = _newfunPool;
    }

    function updateCreationFeeContract(
        address _newCreationFeeContract
    ) public onlyOwner {
        creationFeeDistributionContract = _newCreationFeeContract;
    }

    function updateStorageContract(
        address _newStorageContract
    ) public onlyOwner {
        funStorage = _newStorageContract;
    }
    function updateEventContract(address _newEventContract) public onlyOwner {
        eventTracker = _newEventContract;
    }

    function updateListThreshold(uint256 _newListThreshold) public onlyOwner {
        listThreshold = _newListThreshold;
    }
    function updateAntiSnipePer(uint256 _newAntiSnipePer) public onlyOwner {
        antiSnipePer = _newAntiSnipePer;
    }
    function stateChangeLPBurn(bool _state) public onlyOwner {
        lpBurn = _state;
    }

    function updateAffiliatePerBaseTenK(uint256 _newAffPer) public onlyOwner {
        affiliatePer = _newAffPer;
    }

    function updateteamFeeper(uint256 _newFeePer) public onlyOwner {
        teamFeePer = _newFeePer;
    }

    function updateCurveFactor(uint256 _newFactor) public onlyOwner {
        curveFactor = _newFactor;
    }

    function stateChangeCurveFactorLock(bool _state) public onlyOwner {
        curveFactorLock = _state;
    }

    function emitRoyal(
        address funContract,
        address tokenAddress,
        address router,
        address baseAddress,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 _time,
        uint256 totalVolume
    ) public {
        require(msg.sender == funPool, "invalid caller");
        emit royal(
            funContract,
            tokenAddress,
            router,
            baseAddress,
            liquidityAmount,
            tokenAmount,
            _time,
            totalVolume
        );
    }
    // Emergency withdrawal by owner
    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}