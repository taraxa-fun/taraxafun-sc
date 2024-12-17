// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunPool {
    function initFun(
        string[2] memory _name_symbol,
        uint256 _totalSupply,
        address _creator,
        uint256[2] memory listThreshold_initReserveEth,
        uint256 _maxBuyPerWallet
    ) external payable returns (address);

    function buyTokens(
        address funToken,
        uint256 minTokens,
        address _affiliate
    ) external payable;

}