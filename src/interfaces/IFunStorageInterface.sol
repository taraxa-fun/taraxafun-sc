// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunStorageInterface {
    function addFunContract(
        address _funOwner,
        address _funAddress,
        address _tokenAddress,
        string memory _name,
        string memory _symbol,
        string memory _data,
        uint256 _totalSupply,
        uint256 _initialLiquidity
    ) external;
    function getFunContractOwner(
        address _funContract
    ) external view returns (address);
    function getFunContractIndex(
        address _funContract
    ) external view returns (uint256);
    function updateData(
        address _funOwner,
        uint256 _ownerFunNumber,
        string memory _data
    ) external;
    function addDeployer(address) external;
    function owner() external view;
}