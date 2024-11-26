// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunEventTracker {
    function buyEvent(
        address _caller,
        address _funContract,
        uint256 _buyAmount,
        uint256 _tokenRecieved
    ) external;
    function sellEvent(
        address _caller,
        address _funContract,
        uint256 _sellAmount,
        uint256 _nativeRecieved
    ) external;
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
    ) external;
    function listEvent(
        address user,
        address tokenAddress,
        address router,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 _time,
        uint256 totalVolume
    ) external;
    function callerValidate(address _newFunContract) external;
    function addDeployer(address) external;
}