// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {INonfungiblePositionManager} from "@v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import {IFunStorageInterface} from "./interfaces/IFunStorageInterface.sol";


contract LPManager is Ownable, IERC721Receiver {

    uint256 public constant BASIS_POINTS = 10000;

    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    uint256 public feePer;

    mapping(uint256 => address) public lpTokenToDeployer;

    constructor(address _nonfungiblePositionManager, uint256 _feePer) Ownable(msg.sender) {
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
        feePer = _feePer;
    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function emergencyWithdrawERC721(address _token, uint256 _tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), owner(), _tokenId);
    }
}