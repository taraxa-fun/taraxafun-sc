// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunPool {
    function createFun(
        string[2] memory _name_symbol,
        uint256 _totalSupply,
        address _creator,
        address _baseToken,
        address _router,
        uint256[2] memory listThreshold_initReserveEth,
        bool lpBurn
    ) external payable returns (address);

    function buyTokens(
        address funToken,
        uint256 minTokens,
        address _affiliate
    ) external payable;
}