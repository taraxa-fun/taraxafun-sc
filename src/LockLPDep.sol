pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface decentralizedStorage {
    function addNewLock(address _lpAddress, uint256 _locktime, address _lockContract, uint256 _tokenAmount, string memory _logo) external;

    function extendLockerTime(uint256 _userLockerNumber, uint256 _newLockTime) external;

    function transferLocker(address _newOwner, uint256 _userLockerNumber) external;

    function unlockLocker(uint256 _userLockerNumber) external;

    function changeLogo(string memory _newLogo, uint256 _userLockerNumber) external;

    function getPersonalLockerCount(address _owner) external returns (uint256);

    function getBurnContractAddress() external view returns (address);
}

contract LaunchLPLocker is Ownable {

    string public deployer = "dx.app";
    string public deployerType = "Launchpad";
    bool public launchpad = true;
    uint256 public LockedAmount;

    uint256 public personalLockerCount;
    decentralizedStorage public storagePersonal;

    uint256 public LockExpireTimestamp;
    uint256 public LockerCreationTimestamp;

    bool public feePaid;
    uint256 public percFeeAmount;
    uint256 public RewardsNativeClaimed;
    mapping(address => uint256) public RewardsTokenClaimed;
    IERC20 public PersonalLockerToken;


    constructor (address _lockTokenAddress, uint256 _lockTimeEnd, uint256 _personalLockerCount, address _lockerStorage, uint256 _lockingAmount, uint256 _feeAmount, address _funOwner) Ownable(msg.sender) {
        require(_lockingAmount > 0,"can't lock 0 Tokens");
        require(_lockTimeEnd > (block.timestamp + 600), "Please lock longer than now");

        LockedAmount = _lockingAmount;

        PersonalLockerToken = IERC20(_lockTokenAddress);

        LockExpireTimestamp = _lockTimeEnd;
        personalLockerCount = _personalLockerCount;
        storagePersonal = decentralizedStorage(_lockerStorage);

        LockerCreationTimestamp = block.timestamp;

        feePaid = true;
        percFeeAmount = _feeAmount;

        _transferOwnership(_funOwner);
    }

    receive() external payable {

    }

    function changeLogo(string memory _logo) public onlyOwner {
        storagePersonal.changeLogo(_logo, personalLockerCount);
    }

    function CheckLockedBalance() public view returns (uint256){
        return PersonalLockerToken.balanceOf(address(this));
    }

    function ExtendPersonalLocker(uint256 _newLockTime) external onlyOwner {
        require(LockExpireTimestamp < _newLockTime, "You cant reduce locktime...");
        require(block.timestamp < LockExpireTimestamp, "Your Lock Expired ");

        LockExpireTimestamp = _newLockTime;
        storagePersonal.extendLockerTime(LockExpireTimestamp, personalLockerCount);
    }

    function transferOwnership(address _newOwner) public override onlyOwner {
        _transferOwnership(_newOwner);
        storagePersonal.transferLocker(_newOwner, personalLockerCount);
    }

    function unlockTokensAfterTimestamp() external onlyOwner {
        require(block.timestamp >= LockExpireTimestamp, "Token is still Locked");
        require(feePaid, "Please pay the fee first");

        PersonalLockerToken.transfer(owner(), PersonalLockerToken.balanceOf(address(this)));
        storagePersonal.unlockLocker(personalLockerCount);
    }


    function unlockPercentageAfterTimestamp(uint256 _percentage) external onlyOwner {
        require(block.timestamp >= LockExpireTimestamp, "Token is still Locked");
        require(feePaid, "Fee not paid yet");
        uint256 amountUnlock = (PersonalLockerToken.balanceOf(address(this)) * _percentage) / 100;
        PersonalLockerToken.transfer(owner(), amountUnlock);
    }
    function WithdrawRewardNativeToken() external onlyOwner {
        uint256 amountFee = (address(this).balance * percFeeAmount) / 100;
        payable(storagePersonal.getBurnContractAddress()).transfer(amountFee);
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
        RewardsNativeClaimed += amount;
    }

    function WithdrawTokensReward(address _token) external onlyOwner {
        require(_token != address(PersonalLockerToken), "You can't unlock the Tokens you locked with this function!");

        uint256 amountFee = (IERC20(_token).balanceOf(address(this))* percFeeAmount) / 100;
        IERC20(_token).transfer(storagePersonal.getBurnContractAddress(), amountFee);

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), amount);
        RewardsTokenClaimed[_token] += amount;
    }

}

contract DxLockLPDep is Ownable {
    address[] public shareholders;
    mapping(address => uint256) public shares;  // Shares for each shareholder
    mapping(address => bool) public isShareholder;
    uint256 public totalShares;
    uint256 public totalAmount;
    decentralizedStorage PersonalLockerStorage;
    //mapping (address => bool) public maindapps;
   // uint256 public lockerFees = 3 * 10 ** 17;
//    bool public feeCreationMode; //false = fees at creation
    uint256 public percFeeAmount = 10; //Divider is 1000 so 1 is 0.1%

    bool public lpLockFeeEnabled = true;
    //uint256 public FeesEarned;
    address[] public LockerContractStorage;
    event FeeDistributed(address indexed recipient, uint256 amount);
    event SharesUpdated(address indexed shareholder, uint256 oldShares, uint256 newShares);
    event ShareholderAdded(address indexed shareholder);
    event ShareholderRemoved(address indexed shareholder);
    
    constructor(decentralizedStorage _lockerStorage) Ownable(msg.sender) {
        PersonalLockerStorage = _lockerStorage;
    }

    function createLPLocker(address _lockingToken, uint256 _lockerEndTimeStamp, string memory _logo, uint256 _lockingAmount, address _funOwner) public returns (address newLock)  {
        
        uint256 feeAmount;
        uint256 lockingFinalAmount;
        require(_lockingAmount > 0,"can't lock 0 Tokens");
        
        //require(address(Ownable(Ownable(msg.sender).owner()).owner()) == owner(), "call from invalid address");
        if(lpLockFeeEnabled){
            feeAmount = _lockingAmount * percFeeAmount / 1000;
            lockingFinalAmount = _lockingAmount - feeAmount;
            distributeFees(_lockingToken,feeAmount);  
            //IERC20(_lockingToken).transferFrom(msg.sender,tokenFeeAddress,feeAmount);

        }
        else{

            lockingFinalAmount = _lockingAmount;

        }
        
        //require(maindapps[Ownable(msg.sender).owner()], "call from invalid address");
        /*if (_feeCreationMode) {
            require(msg.value >= lockerFees, "err : Please pay the price");
            payable(PersonalLockerStorage.getBurnContractAddress()).transfer(msg.value);
            FeesEarned += lockerFees;
        }
        */

        uint256 _counter = PersonalLockerStorage.getPersonalLockerCount(_funOwner);


        LaunchLPLocker createNewLock;
        createNewLock = new LaunchLPLocker(_lockingToken, _lockerEndTimeStamp, _counter, address(PersonalLockerStorage), lockingFinalAmount, percFeeAmount, _funOwner);

        require(IERC20(_lockingToken).transferFrom(msg.sender, address(createNewLock), lockingFinalAmount), "Entry failed due to failed transfer.");

        PersonalLockerStorage.addNewLock(_lockingToken, _lockerEndTimeStamp, address(createNewLock), lockingFinalAmount, _logo);
        LockerContractStorage.push(address(createNewLock));

        return address(createNewLock);
    }

    function changeStorageContract(decentralizedStorage _lockerStorage) external onlyOwner {
        PersonalLockerStorage = _lockerStorage;
    }

    function changeFeePerc(uint256 _feeAmount) external onlyOwner {
        percFeeAmount = _feeAmount;
    }

    function changeFeeState(bool _feeState) public onlyOwner {

        lpLockFeeEnabled = _feeState;

        
    }

    function getLockerCount() public view returns (uint256 isSize){
        return LockerContractStorage.length;
    }

    function getAllLockers() public view returns (address[] memory){
        address[] memory allTokens = new address[](LockerContractStorage.length);
        for (uint256 i = 0; i < LockerContractStorage.length; i++) {
            allTokens[i] = LockerContractStorage[i];
        }
        return allTokens;
    }

    function sendBNBstoBurnContract() public onlyOwner {
        address payable BurnContractAddress = payable(PersonalLockerStorage.getBurnContractAddress());
        BurnContractAddress.transfer(address(this).balance);
    }
/*
    function changeVault(address _vault) public onlyOwner {
        BurnContractAddress = payable(_vault);
    }
*/


    function withdrawStuckCurrency(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }


    // Function to set shares for a shareholder
    function setShares(address _shareHolder, uint256 _share) public onlyOwner {
        require(_shareHolder != address(0), "Invalid address");
        require(_share >= 0 && _share <= 10000, "Invalid share percentage");

        if (isShareholder[_shareHolder]) {
            totalShares = totalShares - shares[_shareHolder] + _share;
            shares[_shareHolder] = _share;
            if (_share == 0) {
                removeShareholder(_shareHolder);
            }
        } else {
            require(_share > 0, "Share must be greater than 0 to add shareholder");
            addShareholder(_shareHolder);
            shares[_shareHolder] = _share;
            totalShares += _share;
        }

        emit SharesUpdated(_shareHolder, shares[_shareHolder], _share);
    }

// Function to edit shares for an existing shareholder
    function editShares(address shareholder, uint256 newShare) public onlyOwner {
        require(shareholder != address(0), "Invalid address");
        require(newShare >= 0 && newShare <= 10000, "Invalid share percentage");
        require(isShareholder[shareholder], "Address is not a shareholder");

        uint256 currentShare = shares[shareholder];
        if (newShare == 0) {
            // If the new share is zero, remove the shareholder
            removeShareholder(shareholder);
        } else if (currentShare == 0 && newShare > 0) {
            // If currently no shares and new shares are added, add as shareholder
            addShareholder(shareholder);
        }

        // Update total shares and shareholder's shares
        totalShares = totalShares - currentShare + newShare;
        shares[shareholder] = newShare;

        emit SharesUpdated(shareholder, currentShare, newShare);
    }

    // Function to distribute fees among shareholders based on their shares
    function distributeFees(address _lpAddrs, uint256 _lpAmount) internal {

        uint256 totalReceived = _lpAmount;

        for (uint i = 0; i < shareholders.length; i++) {
            uint256 payment = totalReceived * shares[shareholders[i]] / totalShares;
            IERC20(_lpAddrs).transferFrom(msg.sender,shareholders[i],payment);
        }
    }

    // Helper functions to manage shareholders
    function addShareholder(address shareholder) internal {
        isShareholder[shareholder] = true;
        shareholders.push(shareholder);
        emit ShareholderAdded(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        isShareholder[shareholder] = false;
        for (uint i = 0; i < shareholders.length; i++) {
            if (shareholders[i] == shareholder) {
                shareholders[i] = shareholders[shareholders.length - 1];
                shareholders.pop();
                break;
            }
        }
        emit ShareholderRemoved(shareholder);
    }
}