// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFunToken {
    function initialize(
        uint256 initialSupply,
        string memory _name,
        string memory _symbol,
        address _midDeployer,
        address _deployer
    ) external;
    function initiateDex() external;
}