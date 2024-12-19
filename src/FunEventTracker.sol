// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFunStorageInterface} from "./interfaces/IFunStorageInterface.sol";

contract FunEventTracker is Ownable {

    address public funRegistry;

    mapping(address => bool) public funContractDeployer;
    mapping(address => uint256) public funContractIndex;

    uint256 public buyEventCount;
    uint256 public sellEventCount;

    event buyCall(
        address indexed buyer,
        address indexed funContract,
        uint256 buyAmount,
        uint256 tokenReceived,
        uint256 index,
        uint256 timestamp
    );

    event sellCall(
        address indexed seller,
        address indexed funContract,
        uint256 sellAmount,
        uint256 nativeReceived,
        uint256 index,
        uint256 timestamp
    );

    event tradeCall(
        address indexed caller,
        address indexed funContract,
        uint256 inAmount,
        uint256 outAmount,
        uint256 index,
        uint256 timestamp,
        string tradeType
    );

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

    event listed(
        address indexed user,
        address indexed tokenAddress,
        address indexed router,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 time,
        uint256 totalVolume
    );

    constructor(address _funStorage) Ownable(msg.sender) {
        funRegistry = _funStorage;
    }

    function buyEvent(
        address _buyer,
        address _funContract,
        uint256 _buyAmount,
        uint256 _tokenReceived
    ) public {
        require(funContractDeployer[msg.sender], "invalid fun contract");
        uint256 funIndex;
        funIndex = IFunStorageInterface(funRegistry).getFunContractIndex(
            _funContract
        );
        emit buyCall(
            _buyer,
            _funContract,
            _buyAmount,
            _tokenReceived,
            funIndex,
            block.timestamp
        );
        emit tradeCall(
            _buyer,
            _funContract,
            _buyAmount,
            _tokenReceived,
            funIndex,
            block.timestamp,
            "buy"
        );
        buyEventCount++;
    }

    function sellEvent(
        address _seller,
        address _funContract,
        uint256 _sellAmount,
        uint256 _tokenReceived
    ) public {
        require(funContractDeployer[msg.sender], "invalid fun contract");
        uint256 funIndex;
        funIndex = IFunStorageInterface(funRegistry).getFunContractIndex(
            _funContract
        );
        emit sellCall(
            _seller,
            _funContract,
            _sellAmount,
            _tokenReceived,
            funIndex,
            block.timestamp
        );
        emit tradeCall(
            _seller,
            _funContract,
            _sellAmount,
            _tokenReceived,
            funIndex,
            block.timestamp,
            "sell"
        );
        sellEventCount++;
    }

    function createFunEvent(
        address creator,
        address funContract,
        address tokenAddress,
        string memory name,
        string memory symbol,
        string memory data,
        uint256 totalSupply,
        uint256 initialReserve,
        uint256 timestamp
    ) public {
        require(funContractDeployer[msg.sender], "not deployer");
        

        funContractIndex[funContract] = IFunStorageInterface(funRegistry)
            .getFunContractIndex(funContract);
        emit funCreated(
            creator,
            funContract,
            tokenAddress,
            name,
            symbol,
            data,
            totalSupply,
            initialReserve,
            timestamp
        );
    }

    function listEvent(
        address user,
        address tokenAddress,
        address router,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 _time,
        uint256 totalVolume
    ) public {
        require(funContractDeployer[msg.sender], "not deployer");
        emit listed(
            user,
            tokenAddress,
            router,
            liquidityAmount,
            tokenAmount,
            _time,
            totalVolume
        );
    }

    function addDeployer(address _newDeployer) public onlyOwner {
        funContractDeployer[_newDeployer] = true;
    }

    function removeDeployer(address _deployer) public onlyOwner {
        funContractDeployer[_deployer] = false;
    }
}