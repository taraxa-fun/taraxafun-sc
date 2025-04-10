// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunPool {

    struct FunTokenPoolData {
        uint256 reserveTokens;
        uint256 reserveTARA;
        uint256 volume;
        uint256 listThreshold;
        uint256 initialReserveTARA;
        uint256 maxBuyPerWallet;
        bool tradeActive;
        bool royalemitted;
    }

    struct FunTokenPool {
        address creator;
        address token;
        address baseToken;
        address router;
        address lockerAddress;
        address storedLPAddress;
        address deployer;
        FunTokenPoolData pool;
    }

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

    function tokenPools(address) external view returns (FunTokenPool memory);

}