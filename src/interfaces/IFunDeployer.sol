// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunDeployer {
    function getAffiliatePer(
        address _affiliateAddrs
    ) external view returns (uint256);
    function getOwnerPer() external view returns (uint256);
    function emitRoyal(
        address funContract,
        address tokenAddress,
        address router,
        address baseAddress,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 _time,
        uint256 totalVolume
    ) external;
}