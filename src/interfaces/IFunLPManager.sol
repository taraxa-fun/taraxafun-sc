// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunLPManager {
    function depositNFTPosition(
        uint256 _tokenId, 
        address _dev
    ) external;

    function collectFees(uint256 _tokenId) external;

    function tokenIdToLPPosition(uint256 _tokenId) external view returns (address, uint256, uint256);
}