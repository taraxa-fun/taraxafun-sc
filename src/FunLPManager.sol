// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {INonfungiblePositionManager} from "@v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IFunStorageInterface} from "./interfaces/IFunStorageInterface.sol";

contract FunLPManager is Ownable, IERC721Receiver {

    struct LPPosition {
        address dev;
        uint256 token0Collected;
        uint256 token1Collected;
    }

    event positionDeposited(
        uint256 tokenId, 
        address dev, 
        uint256 timestamp
    );

    event feesCollected(
        uint256 tokenId, 
        address dev,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 timestamp
    );

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public feePer;

    address public nonfungiblePositionManager;
    address public funPool;

    mapping(uint256 => LPPosition) public tokenIdToLPPosition;

    constructor(
        address _nonfungiblePositionManager, 
        address _funPool,
        uint256 _feePer
        ) Ownable(msg.sender) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
        funPool = _funPool;

        feePer = _feePer;
    }

    function depositNFTPosition(uint256 _tokenId, address _dev) external {
        require(msg.sender == funPool, "LPManager: Only FunPool can call this function");

        IERC721(nonfungiblePositionManager).transferFrom(funPool, address(this), _tokenId);

        LPPosition memory lpPosition = LPPosition({
            dev: _dev,
            token0Collected: 0,
            token1Collected: 0
        });

        tokenIdToLPPosition[_tokenId] = lpPosition;

        emit positionDeposited(_tokenId, _dev, block.timestamp);
    }

    function collectFees(uint256 _tokenId) external {

        require(IERC721(nonfungiblePositionManager).ownerOf(_tokenId) == address(this), "LPManager: LP Token not owned by LPManager");

        LPPosition storage lpPosition = tokenIdToLPPosition[_tokenId];
        
        require((msg.sender == lpPosition.dev) || (msg.sender == owner()), "LPManager: Only Dev or Owner can collect fees");

        INonfungiblePositionManager(nonfungiblePositionManager).collect(INonfungiblePositionManager.CollectParams({
            tokenId: _tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        }));

        (,,address token0, address token1,,,,,,,,) = INonfungiblePositionManager(nonfungiblePositionManager).positions(_tokenId);

        uint256 token0Balance = IERC20(token0).balanceOf(address(this));
        uint256 token1Balance = IERC20(token1).balanceOf(address(this));

        uint256 feeAmount0 = (token0Balance * feePer) / BASIS_POINTS;
        uint256 feeAmount1 = (token1Balance * feePer) / BASIS_POINTS;

        IERC20(token0).transfer(owner(), feeAmount0);
        IERC20(token1).transfer(owner(), feeAmount1);

        IERC20(token0).transfer(lpPosition.dev, token0Balance - feeAmount0);
        IERC20(token1).transfer(lpPosition.dev, token1Balance - feeAmount1);

        emit feesCollected(_tokenId, lpPosition.dev, token0Balance, token1Balance, block.timestamp);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setFeePer(uint256 _feePer) external onlyOwner {
        require(_feePer > 0, "LPManager: Fee Per must be greater than 0");
        feePer = _feePer;
    }

    function emergencyWithdrawERC721(address _token, uint256 _tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), owner(), _tokenId);
    }
}