// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//dx.fun//base.fun powered by dextools and dxsale.

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function decimals() external returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public voter;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyVoter() {
        require(msg.sender == voter);
        _;
    }
    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
interface UniswapRouter02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
    // function WBNB() external pure returns(address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}
interface UniswapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}
interface LPToken {
    function sync() external;
}
interface ILpLockDeployerInterface {
    function createLPLocker(
        address _lockingToken,
        uint256 _lockerEndTimeStamp,
        string memory _logo,
        uint256 _lockingAmount,
        address _funOwner
    ) external payable returns (address);
}
interface IFunDeployerInterface {
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
}
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

import "./lib/Clones.sol";

contract FunPool is Ownable, ReentrancyGuard {
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant HUNDRED = 100;
    uint256 public constant BASIS_POINTS = 10000;

    struct FunTokenPoolData {
        uint256 reserveTokens;
        uint256 reserveETH;
        uint256 volume;
        uint256 listThreshold;
        uint256 initialReserveEth;
        uint8 nativePer;
        bool tradeActive;
        bool lpBurn;
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

    // deployer allowed to create fun tokens
    mapping(address => bool) public allowedDeployers;
    // user => array of fun tokens
    mapping(address => address[]) public userFunTokens;
    // fun token => fun token details
    mapping(address => FunTokenPool) public tokenPools;

    address public implementation;
    address public feeContract;
    address public stableAddress;
    address public lpLockDeployer;
    address public eventTracker;
    uint16 public feePer;

    event LiquidityAdded(
        address indexed provider,
        uint tokenAmount,
        uint ethAmount
    );
    event sold(
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        uint256 _time,
        uint256 reserveEth,
        uint256 reserveTokens,
        uint256 totalVolume
    );
    event bought(
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        uint256 _time,
        uint256 reserveEth,
        uint256 reserveTokens,
        uint256 totalVolume
    );
    event funTradeCall(
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        uint256 _time,
        uint256 reserveEth,
        uint256 reserveTokens,
        string tradeType,
        uint256 totalVolume
    );
    event listed(
        address indexed user,
        address indexed tokenAddress,
        address indexed router,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 _time,
        uint256 totalVolume
    );

    constructor(
        address _implementation,
        address _feeContract,
        address _lpLockDeployer,
        address _stableAddress,
        address _eventTracker,
        uint16 _feePer
    ) payable {
        implementation = _implementation;
        feeContract = _feeContract;
        lpLockDeployer = _lpLockDeployer;
        stableAddress = _stableAddress;
        eventTracker = _eventTracker;
        feePer = _feePer;
    }

    function createFun(
        string[2] memory _name_symbol,
        uint256 _totalSupply,
        address _creator,
        address _baseToken,
        address _router,
        uint256[2] memory listThreshold_initReserveEth,
        bool lpBurn
    ) public payable returns (address) {
        require(allowedDeployers[msg.sender], "not deployer");

        address funToken = Clones.clone(implementation);
        IFunToken(funToken).initialize(
            _totalSupply,
            _name_symbol[0],
            _name_symbol[1],
            address(this),
            msg.sender
        );

        // add tokens to the tokens user list
        userFunTokens[_creator].push(funToken);

        // create the pool data
        FunTokenPool memory pool;

        pool.creator = _creator;
        pool.token = funToken;
        pool.baseToken = _baseToken;
        pool.router = _router;
        pool.deployer = msg.sender;

        if (_baseToken == UniswapRouter02(_router).WETH()) {
            pool.pool.nativePer = 100;
        } else {
            pool.pool.nativePer = 50;
        }
        pool.pool.tradeActive = true;
        pool.pool.lpBurn = lpBurn;
        pool.pool.reserveTokens += _totalSupply;
        pool.pool.reserveETH += (listThreshold_initReserveEth[1] + msg.value);
        pool.pool.listThreshold = listThreshold_initReserveEth[0];
        pool.pool.initialReserveEth = listThreshold_initReserveEth[1];

        // add the fun data for the fun token
        tokenPools[funToken] = pool;
        // tokenPoolData[funToken] = funPoolData;

        emit LiquidityAdded(address(this), _totalSupply, msg.value);

        return address(funToken); // return fun token address
    }

    // Calculate amount of output tokens or ETH to give out
    function getAmountOutTokens(
        address funToken,
        uint amountIn
    ) public view returns (uint amountOut) {
        require(amountIn > 0, "Invalid input amount");
        FunTokenPool storage token = tokenPools[funToken];
        require(
            token.pool.reserveTokens > 0 && token.pool.reserveETH > 0,
            "Invalid reserves"
        );
        uint numerator = amountIn * token.pool.reserveTokens;
        uint denominator = (token.pool.reserveETH) + amountIn;
        amountOut = numerator / denominator;
    }

    function getAmountOutETH(
        address funToken,
        uint amountIn
    ) public view returns (uint amountOut) {
        require(amountIn > 0, "Invalid input amount");
        FunTokenPool storage token = tokenPools[funToken];
        require(
            token.pool.reserveTokens > 0 && token.pool.reserveETH > 0,
            "Invalid reserves"
        );
        uint numerator = amountIn * token.pool.reserveETH;
        uint denominator = (token.pool.reserveTokens) + amountIn;
        amountOut = numerator / denominator;
    }

    function getBaseToken(address funToken) public view returns (address) {
        FunTokenPool storage token = tokenPools[funToken];
        return address(token.baseToken);
    }

    function getWrapAddr(address funToken) public view returns (address) {
        return UniswapRouter02(tokenPools[funToken].router).WETH();
    }

    function getAmountsMinToken(
        address funToken,
        address _tokenAddress,
        uint256 _ethIN
    ) public view returns (uint256) {
        // generate the pair path of token -> weth
        uint256[] memory amountMinArr;
        address[] memory path = new address[](2);
        path[0] = getWrapAddr(funToken);
        path[1] = address(_tokenAddress);
        amountMinArr = UniswapRouter02(tokenPools[funToken].router)
            .getAmountsOut(_ethIN, path);
        return uint256(amountMinArr[1]);
    }

    function getCurrentCap(address funToken) public view returns (uint256) {
        FunTokenPool storage token = tokenPools[funToken];
        return
            (getAmountsMinToken(
                funToken,
                stableAddress,
                token.pool.reserveETH
            ) * IERC20(funToken).totalSupply()) / token.pool.reserveTokens;
    }

    function getFuntokenPool(address funToken) public view returns(FunTokenPool memory) {
      return tokenPools[funToken];
    }

    function getFuntokenPools(address[] memory funTokens) public view returns(FunTokenPool[] memory) {
      uint length = funTokens.length;
      FunTokenPool[] memory pools = new FunTokenPool[](length);
      for( uint i=0 ;i < length;  ) {
        pools[i] = tokenPools[funTokens[i]];
        unchecked {
          i++;
        }
      }
      return pools;
    }

     function getUserFuntokens(address user) public view returns(address[] memory) {
      return userFunTokens[user];
    }

    function sellTokens(
        address funToken,
        uint256 tokenAmount,
        uint256 minEth,
        address _affiliate
    ) public nonReentrant returns (bool, bool) {
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.tradeActive, "Trading not active");

        uint256 tokenToSell = tokenAmount;
        uint256 ethAmount = getAmountOutETH(funToken, tokenToSell);
        uint256 ethAmountFee = (ethAmount * feePer) / BASIS_POINTS;
        uint256 ethAmountOwnerFee = (ethAmountFee *
            (IFunDeployerInterface(token.deployer).getOwnerPer())) /
            BASIS_POINTS;
        uint256 affiliateFee = (ethAmountFee *
            (
                IFunDeployerInterface(token.deployer).getAffiliatePer(
                    _affiliate
                )
            )) / BASIS_POINTS;
        require(ethAmount > 0 && ethAmount >= minEth, "Slippage too high");

        token.pool.reserveTokens += tokenAmount;
        token.pool.reserveETH -= ethAmount;
        token.pool.volume += ethAmount;

        IERC20(funToken).transferFrom(msg.sender, address(this), tokenToSell);
        (bool success, ) = feeContract.call{
            value: ethAmountFee - ethAmountOwnerFee - affiliateFee
        }(""); // paying plat fee
        require(success, "fee ETH transfer failed");

        (success, ) = _affiliate.call{value: affiliateFee}(""); // paying affiliate fee which is same amount as plat fee %
        require(success, "aff ETH transfer failed");

        (success, ) = owner.call{value: ethAmountOwnerFee}(""); // paying owner fee per tx
        require(success, "ownr ETH transfer failed");

        (success, ) = msg.sender.call{value: ethAmount - ethAmountFee}("");
        require(success, "seller ETH transfer failed");

        emit sold(
            msg.sender,
            tokenAmount,
            ethAmount,
            block.timestamp,
            token.pool.reserveETH,
            token.pool.reserveTokens,
            token.pool.volume
        );
        emit funTradeCall(
            msg.sender,
            tokenAmount,
            ethAmount,
            block.timestamp,
            token.pool.reserveETH,
            token.pool.reserveTokens,
            "sell",
            token.pool.volume
        );
        IFunEventTracker(eventTracker).sellEvent(
            msg.sender,
            funToken,
            tokenToSell,
            ethAmount
        );

        return (true, true);
    }

    function buyTokens(
        address funToken,
        uint256 minTokens,
        address _affiliate
    ) public payable nonReentrant {
        require(msg.value > 0, "Invalid buy value");
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.tradeActive, "Trading not active");

        {
            uint256 ethAmount = msg.value;
            uint256 ethAmountFee = (ethAmount * feePer) / BASIS_POINTS;
            uint256 ethAmountOwnerFee = (ethAmountFee *
                (IFunDeployerInterface(token.deployer).getOwnerPer())) /
                BASIS_POINTS;
            uint256 affiliateFee = (ethAmountFee *
                (
                    IFunDeployerInterface(token.deployer).getAffiliatePer(
                        _affiliate
                    )
                )) / BASIS_POINTS;

            uint256 tokenAmount = getAmountOutTokens(
                funToken,
                ethAmount - ethAmountFee
            );
            require(tokenAmount >= minTokens, "Slippage too high");

            token.pool.reserveETH += (ethAmount - ethAmountFee);
            token.pool.reserveTokens -= tokenAmount;
            token.pool.volume += ethAmount;

            (bool success, ) = feeContract.call{
                value: ethAmountFee - ethAmountOwnerFee - affiliateFee
            }(""); // paying plat fee
            require(success, "fee ETH transfer failed");

            (success, ) = _affiliate.call{value: affiliateFee}(""); // paying affiliate fee which is same amount as plat fee %
            require(success, "fee ETH transfer failed");

            (success, ) = owner.call{value: ethAmountOwnerFee}(""); // paying owner fee per tx
            require(success, "fee ETH transfer failed");

            IERC20(funToken).transfer(msg.sender, tokenAmount);
            emit bought(
                msg.sender,
                msg.value,
                tokenAmount,
                block.timestamp,
                token.pool.reserveETH,
                token.pool.reserveTokens,
                token.pool.volume
            );
            emit funTradeCall(
                msg.sender,
                msg.value,
                tokenAmount,
                block.timestamp,
                token.pool.reserveETH,
                token.pool.reserveTokens,
                "buy",
                token.pool.volume
            );
            IFunEventTracker(eventTracker).buyEvent(
                msg.sender,
                funToken,
                msg.value,
                tokenAmount
            );
        }

        uint currentMarketCap = getCurrentCap(funToken);
        uint listThresholdCap = token.pool.listThreshold *
            10 ** IERC20(stableAddress).decimals();

        // using liquidity value inside contract to check when to add liquidity to DEX
        if (
            currentMarketCap >= (listThresholdCap / 2) &&
            !token.pool.royalemitted
        ) {
            IFunDeployerInterface(token.deployer).emitRoyal(
                funToken,
                funToken,
                token.router,
                token.baseToken,
                token.pool.reserveETH,
                token.pool.reserveTokens,
                block.timestamp,
                token.pool.volume
            );
            token.pool.royalemitted = true;
        }
        // using marketcap value of token to check when to add liquidity to DEX
        if (currentMarketCap >= listThresholdCap) {
            token.pool.tradeActive = false;
            IFunToken(funToken).initiateDex();
            token.pool.reserveETH -= token.pool.initialReserveEth;
            if (token.pool.nativePer > 0) {
                _addLiquidityETH(
                    funToken,
                    (IERC20(funToken).balanceOf(address(this)) *
                        token.pool.nativePer) / HUNDRED,
                    (token.pool.reserveETH * token.pool.nativePer) / HUNDRED,
                    token.pool.lpBurn
                );
                token.pool.reserveETH -=
                    (token.pool.reserveETH * token.pool.nativePer) /
                    HUNDRED;
            }
            if (token.pool.nativePer < HUNDRED) {
                _swapEthToBase(
                    funToken,
                    token.baseToken,
                    token.pool.reserveETH
                );
                _addLiquidity(
                    funToken,
                    IERC20(funToken).balanceOf(address(this)),
                    IERC20(token.baseToken).balanceOf(address(this)),
                    token.pool.lpBurn
                );
            }
        }
    }

    function changeNativePer(address funToken, uint8 _newNativePer) public {
        require(_isUserFunToken(funToken), "Unauthorized");
        FunTokenPool storage token = tokenPools[funToken];
        require(
            token.baseToken != getWrapAddr(funToken),
            "no custom base selected"
        );
        require(_newNativePer >= 0 && _newNativePer <= 100, "invalid per");
        token.pool.nativePer = _newNativePer;
    }

    function _addLiquidityETH(
        address funToken,
        uint256 amountTokenDesired,
        uint256 nativeForDex,
        bool lpBurn
    ) internal {
        uint256 amountETH = nativeForDex;
        uint256 amountETHMin = (amountETH * 90) / HUNDRED;
        uint256 amountTokenToAddLiq = amountTokenDesired;
        uint256 amountTokenMin = (amountTokenToAddLiq * 90) / HUNDRED;
        uint256 LP_WBNB_exp_balance;
        uint256 LP_token_balance;
        uint256 tokenToSend = 0;

        FunTokenPool storage token = tokenPools[funToken];

        address wrapperAddress = getWrapAddr(funToken);
        token.storedLPAddress = _getpair(funToken, funToken, wrapperAddress);
        address storedLPAddress = token.storedLPAddress;
        LP_WBNB_exp_balance = IERC20(wrapperAddress).balanceOf(storedLPAddress);
        LP_token_balance = IERC20(funToken).balanceOf(storedLPAddress);

        if (
            storedLPAddress != address(0x0) &&
            (LP_WBNB_exp_balance > 0 && LP_token_balance <= 0)
        ) {
            tokenToSend =
                (amountTokenToAddLiq * LP_WBNB_exp_balance) /
                amountETH;

            IERC20(funToken).transfer(storedLPAddress, tokenToSend);

            LPToken(storedLPAddress).sync();
            // sync after adding token
        }
        _approve(funToken, false);

        if (lpBurn) {
            UniswapRouter02(token.router).addLiquidityETH{
                value: amountETH - LP_WBNB_exp_balance
            }(
                funToken,
                amountTokenToAddLiq - tokenToSend,
                amountTokenMin,
                amountETHMin,
                DEAD,
                block.timestamp + (300)
            );
        } else {
            UniswapRouter02(token.router).addLiquidityETH{
                value: amountETH - LP_WBNB_exp_balance
            }(
                funToken,
                amountTokenToAddLiq - tokenToSend,
                amountTokenMin,
                amountETHMin,
                address(this),
                block.timestamp + (300)
            );
            _approveLock(storedLPAddress, lpLockDeployer);
            token.lockerAddress = ILpLockDeployerInterface(lpLockDeployer)
                .createLPLocker(
                    storedLPAddress,
                    32503698000,
                    "logo",
                    IERC20(storedLPAddress).balanceOf(address(this)),
                    token.creator
                );
        }
        IFunEventTracker(eventTracker).listEvent(
            msg.sender,
            funToken,
            token.router,
            amountETH - LP_WBNB_exp_balance,
            amountTokenToAddLiq - tokenToSend,
            block.timestamp,
            token.pool.volume
        );
        emit listed(
            msg.sender,
            funToken,
            token.router,
            amountETH - LP_WBNB_exp_balance,
            amountTokenToAddLiq - tokenToSend,
            block.timestamp,
            token.pool.volume
        );
    }

    function _addLiquidity(
        address funToken,
        uint256 amountTokenDesired,
        uint256 baseForDex,
        bool lpBurn
    ) internal {
        uint256 amountBase = baseForDex;
        uint256 amountBaseMin = (amountBase * 90) / HUNDRED;
        uint256 amountTokenToAddLiq = amountTokenDesired;
        uint256 amountTokenMin = (amountTokenToAddLiq * 90) / HUNDRED;
        uint256 LP_WBNB_exp_balance;
        uint256 LP_token_balance;
        uint256 tokenToSend = 0;

        FunTokenPool storage token = tokenPools[funToken];

        token.storedLPAddress = _getpair(funToken, funToken, token.baseToken);
        address storedLPAddress = token.storedLPAddress;

        LP_WBNB_exp_balance = IERC20(token.baseToken).balanceOf(
            storedLPAddress
        );
        LP_token_balance = IERC20(funToken).balanceOf(storedLPAddress);

        if (
            storedLPAddress != address(0x0) &&
            (LP_WBNB_exp_balance > 0 && LP_token_balance <= 0)
        ) {
            tokenToSend =
                (amountTokenToAddLiq * LP_WBNB_exp_balance) /
                amountBase;

            IERC20(funToken).transfer(storedLPAddress, tokenToSend);

            LPToken(storedLPAddress).sync();
            // sync after adding token
        }
        _approve(funToken, false);
        _approve(funToken, true);
        if (lpBurn) {
            UniswapRouter02(token.router).addLiquidity(
                funToken,
                token.baseToken,
                amountTokenToAddLiq - tokenToSend,
                amountBase - LP_WBNB_exp_balance,
                amountTokenMin,
                amountBaseMin,
                DEAD,
                block.timestamp + (300)
            );
        } else {
            UniswapRouter02(token.router).addLiquidity(
                funToken,
                token.baseToken,
                amountTokenToAddLiq - tokenToSend,
                amountBase - LP_WBNB_exp_balance,
                amountTokenMin,
                amountBaseMin,
                address(this),
                block.timestamp + (300)
            );
            _approveLock(storedLPAddress, lpLockDeployer);
            token.lockerAddress = ILpLockDeployerInterface(lpLockDeployer)
                .createLPLocker(
                    storedLPAddress,
                    32503698000,
                    "logo",
                    IERC20(storedLPAddress).balanceOf(address(this)),
                    owner
                );
        }
        IFunEventTracker(eventTracker).listEvent(
            msg.sender,
            funToken,
            token.router,
            amountBase - LP_WBNB_exp_balance,
            amountTokenToAddLiq - tokenToSend,
            block.timestamp,
            token.pool.volume
        );
        emit listed(
            msg.sender,
            funToken,
            token.router,
            amountBase - LP_WBNB_exp_balance,
            amountTokenToAddLiq - tokenToSend,
            block.timestamp,
            token.pool.volume
        );
    }

    function _swapEthToBase(
        address funToken,
        address _baseAddress,
        uint256 _ethIN
    ) internal returns (uint256) {
        _approve(funToken, true);
        // generate the pair path of token -> weth
        uint256[] memory amountMinArr;
        address[] memory path = new address[](2);
        path[0] = getWrapAddr(funToken);
        path[1] = _baseAddress;
        uint256 minBase = (getAmountsMinToken(funToken, _baseAddress, _ethIN) *
            90) / HUNDRED;

        amountMinArr = UniswapRouter02(tokenPools[funToken].router)
            .swapExactETHForTokens{value: _ethIN}(
            minBase,
            path,
            address(this),
            block.timestamp + 300
        );
        return amountMinArr[1];
    }

    function _approve(
        address funToken,
        bool isBaseToken
    ) internal returns (bool) {
        FunTokenPool storage token = tokenPools[funToken];
        IERC20 token_ = IERC20(funToken);
        if (isBaseToken) {
            token_ = IERC20(token.baseToken);
        }

        if (token_.allowance(address(this), token.router) == 0) {
            token_.approve(token.router, type(uint256).max);
        }
        return true;
    }

    function _approveLock(
        address _lp,
        address _lockDeployer
    ) internal returns (bool) {
        IERC20 lp_ = IERC20(_lp);
        if (lp_.allowance(address(this), _lockDeployer) == 0) {
            lp_.approve(_lockDeployer, type(uint256).max);
        }
        return true;
    }

    function _getpair(
        address funToken,
        address _token1,
        address _token2
    ) internal returns (address) {
        address router = tokenPools[funToken].router;
        address factory = UniswapRouter02(router).factory();
        address pair = UniswapFactory(factory).getPair(_token1, _token2);
        if (pair != address(0)) {
            return pair;
        } else {
            return UniswapFactory(factory).createPair(_token1, _token2);
        }
    }

    function _isUserFunToken(address funToken) internal view returns (bool) {
        for (uint i = 0; i < userFunTokens[msg.sender].length; ) {
            if (funToken == userFunTokens[msg.sender][i]) {
                return true;
            }
            unchecked {
                i++;
            }
        }
        return false;
    }

    function addDeployer(address _deployer) public onlyOwner {
        allowedDeployers[_deployer] = true;
    }

    function removeDeployer(address _deployer) public onlyOwner {
        allowedDeployers[_deployer] = false;
    }

    function updateImplementation(address _implementation) public onlyOwner {
        require(_implementation != address(0));
        implementation = _implementation;
    }

    function updateFeeContract(address _newFeeContract) public onlyOwner {
        feeContract = _newFeeContract;
    }

    function updateLpLockDeployer(address _newLpLockDeployer) public onlyOwner {
        lpLockDeployer = _newLpLockDeployer;
    }

    function updateEventTracker(address _newEventTracker) public onlyOwner {
        eventTracker = _newEventTracker;
    }

    function updateStableAddress(address _newStableAddress) public onlyOwner {
        stableAddress = _newStableAddress;
    }

    function updateteamFeeper(uint16 _newFeePer) public onlyOwner {
        feePer = _newFeePer;
    }
}
