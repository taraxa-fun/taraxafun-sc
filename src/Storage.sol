// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FunStorage is Ownable {
    struct FunDetails {
        address funAddress;
        address tokenAddress;
        address funOwner;
        string name;
        string symbol;
        string data;
        uint256 totalSupply;
        uint256 initialLiquidity;
        uint256 createdOn;
    }

    FunDetails[] public funContracts;
    mapping(address => bool) public deployer;
    mapping(address => uint256) public funContractToIndex;
    mapping(address => uint256) public tokenContractToIndex;
    mapping(address => uint256) public ownerToFunCount;
    mapping(address => mapping(uint256 => uint256))
        public ownerIndexToStorageIndex;
    mapping(address => address) public funContractToOwner;
    mapping(address => uint256) public funContractToOwnerCount;
    uint256 public funCount;
    modifier onlyDeployer() {
        require(deployer[msg.sender], "not deployer");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function addFunContract(
        address _funOwner,
        address _funAddress,
        address _tokenAddress,
        string memory _name,
        string memory _symbol,
        string memory _data,
        uint256 _totalSupply,
        uint256 _initialLiquidity
    ) external onlyDeployer {
        FunDetails memory newFun = FunDetails({
            funAddress: _funAddress,
            tokenAddress: _tokenAddress,
            funOwner: _funOwner,
            name: _name,
            symbol: _symbol,
            data: _data,
            totalSupply: _totalSupply,
            initialLiquidity: _initialLiquidity,
            createdOn: block.timestamp
        });
        funContracts.push(newFun);
        funContractToIndex[_funAddress] = funContracts.length - 1;
        tokenContractToIndex[_tokenAddress] = funContracts.length - 1;
        funContractToOwner[_funAddress] = _funOwner;
        funContractToOwnerCount[_funAddress] = ownerToFunCount[_funOwner]; // new addition for deployment after base
        ownerIndexToStorageIndex[_funOwner][
            ownerToFunCount[_funOwner]
        ] = funCount;
        ownerToFunCount[_funOwner]++;
        funCount++;
    }

    function updateData(
        address _funOwner,
        uint256 _ownerFunIndex,
        string memory _data
    ) external onlyDeployer {
        require(
            _ownerFunIndex < ownerToFunCount[_funOwner],
            "invalid owner fun count"
        );
        require(
            funContracts[ownerIndexToStorageIndex[_funOwner][_ownerFunIndex]]
                .funOwner == _funOwner,
            "invalid caller"
        );
        funContracts[ownerIndexToStorageIndex[_funOwner][_ownerFunIndex]]
            .data = _data;
    }
    function getFunContract(
        uint256 index
    ) public view returns (FunDetails memory) {
        return funContracts[index];
    }
    function getFunContractIndex(
        address _funContract
    ) public view returns (uint256) {
        return funContractToIndex[_funContract];
    }
    function getTotalContracts() public view returns (uint) {
        return funContracts.length;
    }

    function getFunContractOwner(
        address _funContract
    ) public view returns (address) {
        return funContractToOwner[_funContract];
    }

    function addDeployer(address _deployer) public onlyOwner {
        require(!deployer[_deployer], "already added");
        deployer[_deployer] = true;
    }
    function removeDeployer(address _deployer) public onlyOwner {
        require(deployer[_deployer], "not deployer");
        deployer[_deployer] = false;
    }
    // Emergency withdrawal by owner
    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}