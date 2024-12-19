// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunLPManager {
    function depositNFTPosition(
        uint256 _tokenId, 
        address _dev
    ) external;
}