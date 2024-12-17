// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunDeployer {
    function getAffiliatePer(
        address _affiliateAddrs
    ) external view returns (uint256);
    function getDevFeePer() external view returns (uint256);
    function getTradingFeePer() external view returns (uint256);
    function emitRoyal(
        address tokenAddress,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 time,
        uint256 totalVolume
    ) external;
}