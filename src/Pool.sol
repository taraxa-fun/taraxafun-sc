// SPDX-License-Identifier: MIT

/// 0xFaE1701bC57FC694F836F0704642E15E43C88d3A

pragma solidity ^0.8.20;

import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {Clones} from "./libraries/Clones.sol";
import {IFunDeployer} from "./interfaces/IFunDeployer.sol";
import {IFunEventTracker} from "./interfaces/IFunEventTracker.sol";
import {IWETH} from "./interfaces/IWETH.sol";

import {INonfungiblePositionManager} from "@v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "@v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IQuoterV2} from "@v3-periphery/contracts/interfaces/IQuoterV2.sol";

import "forge-std/console.sol";

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

contract FunPool is Ownable, ReentrancyGuard {
    using FixedPointMathLib for uint256;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant HUNDRED = 100;
    uint256 public constant BASIS_POINTS = 10000;

    address public weth = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address public factory = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    address public router = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
    address public positionManager = 0x1238536071E1c677A632429e3655c799b22cDA52;
    address public quoterV2 = 0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3;

    struct FunTokenPoolData {
        uint256 reserveTokens;
        uint256 reserveETH;
        uint256 volume;
        uint256 listThreshold;
        uint256 initialReserveEth;
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
    uint24 public poolFee = 10000;

    event LiquidityAdded(address indexed provider, uint256 tokenAmount, uint256 ethAmount);
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
    ) payable Ownable(msg.sender) {
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
        uint256[2] memory listThreshold_initReserveEth,
        uint256 _maxBuyPerWallet
    ) public payable returns (address) {
        require(allowedDeployers[msg.sender], "not deployer");

        address funToken = Clones.clone(implementation);
        IFunToken(funToken).initialize(_totalSupply, _name_symbol[0], _name_symbol[1], address(this), msg.sender);

        // add tokens to the tokens user list
        userFunTokens[_creator].push(funToken);

        // create the pool data
        FunTokenPool memory pool;

        pool.creator = _creator;
        pool.token = funToken;
        pool.baseToken = weth;
        pool.router = router;
        pool.deployer = msg.sender;

        pool.pool.tradeActive = true;
        pool.pool.reserveTokens += _totalSupply;
        pool.pool.reserveETH += (listThreshold_initReserveEth[1] + msg.value);
        pool.pool.listThreshold = listThreshold_initReserveEth[0];
        pool.pool.initialReserveEth = listThreshold_initReserveEth[1];
        pool.pool.maxBuyPerWallet = _maxBuyPerWallet;

        // add the fun data for the fun token
        tokenPools[funToken] = pool;
        // tokenPoolData[funToken] = funPoolData;

        emit LiquidityAdded(address(this), _totalSupply, msg.value);

        return address(funToken); // return fun token address
    }

    // Calculate amount of output tokens or ETH to give out
    function getAmountOutTokens(address funToken, uint256 amountIn) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid input amount");
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.reserveTokens > 0 && token.pool.reserveETH > 0, "Invalid reserves");

        uint256 numerator = amountIn * token.pool.reserveTokens;
        uint256 denominator = (token.pool.reserveETH) + amountIn;
        amountOut = numerator / denominator;
    }

    function getAmountOutETH(address funToken, uint256 amountIn) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid input amount");
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.reserveTokens > 0 && token.pool.reserveETH > 0, "Invalid reserves");

        uint256 numerator = amountIn * token.pool.reserveETH;
        uint256 denominator = (token.pool.reserveTokens) + amountIn;
        amountOut = numerator / denominator;
    }

    function getBaseToken(address funToken) public view returns (address) {
        FunTokenPool storage token = tokenPools[funToken];
        return address(token.baseToken);
    }

    function getAmountsMinToken(address funToken, address stableAddress, uint256 ethIN)
        public
        view
        returns (uint256)
    {

        FunTokenPool memory token = tokenPools[funToken];

        /*

        address pool = IUniswapV3Factory(factory).getPool(
            token.baseToken,
            stableAddress,
            500 // 0.05% fee tier
        );
        require(pool != address(0), "Pool does not exist");

        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();

        uint256 numerator = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 denominator = 2 ** 192; // (2^96)^2 
        uint256 sqrtPriceAdjusted = (1e18 * denominator) / numerator;

        return FixedPointMathLib.mulWadDown(ethIN, sqrtPriceAdjusted);

        */

       return 3600000000;
    }

    function getCurrentCap(address funToken) public view returns (uint256) {
        FunTokenPool storage token = tokenPools[funToken];
        return (getAmountsMinToken(funToken, stableAddress, token.pool.reserveETH) * IERC20(funToken).totalSupply())
            / token.pool.reserveTokens;
    }

    function getFuntokenPool(address funToken) public view returns (FunTokenPool memory) {
        return tokenPools[funToken];
    }

    function getFuntokenPools(address[] memory funTokens) public view returns (FunTokenPool[] memory) {
        uint256 length = funTokens.length;
        FunTokenPool[] memory pools = new FunTokenPool[](length);
        for (uint256 i = 0; i < length;) {
            pools[i] = tokenPools[funTokens[i]];
            unchecked {
                i++;
            }
        }
        return pools;
    }

    function getUserFuntokens(address user) public view returns (address[] memory) {
        return userFunTokens[user];
    }

    function checkMaxBuyPerWallet(address funToken, uint256 amount) public view returns (bool) {
        FunTokenPool memory token = tokenPools[funToken];
        uint256 userBalance = IERC20(funToken).balanceOf(msg.sender);
        return userBalance + amount <= token.pool.maxBuyPerWallet;
    }

    function sellTokens(address funToken, uint256 tokenAmount, uint256 minEth, address _affiliate)
        public
        nonReentrant
        returns (bool, bool)
    {
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.tradeActive, "Trading not active");

        uint256 tokenToSell = tokenAmount;
        uint256 ethAmount = getAmountOutETH(funToken, tokenToSell);
        uint256 ethAmountFee = (ethAmount * feePer) / BASIS_POINTS;
        uint256 ethAmountOwnerFee = (ethAmountFee * (IFunDeployer(token.deployer).getOwnerPer())) / BASIS_POINTS;
        uint256 affiliateFee =
            (ethAmountFee * (IFunDeployer(token.deployer).getAffiliatePer(_affiliate))) / BASIS_POINTS;
        require(ethAmount > 0 && ethAmount >= minEth, "Slippage too high");

        token.pool.reserveTokens += tokenAmount;
        token.pool.reserveETH -= ethAmount;
        token.pool.volume += ethAmount;

        IERC20(funToken).transferFrom(msg.sender, address(this), tokenToSell);
        (bool success,) = feeContract.call{value: ethAmountFee - ethAmountOwnerFee - affiliateFee}(""); // paying plat fee
        require(success, "fee ETH transfer failed");

        (success,) = _affiliate.call{value: affiliateFee}(""); // paying affiliate fee which is same amount as plat fee %
        require(success, "aff ETH transfer failed");

        (success,) = payable(owner()).call{value: ethAmountOwnerFee}(""); // paying owner fee per tx
        require(success, "ownr ETH transfer failed");

        (success,) = msg.sender.call{value: ethAmount - ethAmountFee}("");
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
        IFunEventTracker(eventTracker).sellEvent(msg.sender, funToken, tokenToSell, ethAmount);

        return (true, true);
    }

    function buyTokens(address funToken, uint256 minTokens, address _affiliate) public payable nonReentrant {
        require(msg.value > 0, "Invalid buy value");
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.tradeActive, "Trading not active");

        uint256 ethAmount = msg.value;
        uint256 ethAmountFee = (ethAmount * feePer) / BASIS_POINTS;
        uint256 ethAmountOwnerFee = (ethAmountFee * (IFunDeployer(token.deployer).getOwnerPer())) / BASIS_POINTS;
        uint256 affiliateFee =
            (ethAmountFee * (IFunDeployer(token.deployer).getAffiliatePer(_affiliate))) / BASIS_POINTS;

        uint256 tokenAmount = getAmountOutTokens(funToken, ethAmount - ethAmountFee);
        require(tokenAmount >= minTokens, "Slippage too high");
        require(checkMaxBuyPerWallet(funToken, tokenAmount), "Max buy per wallet exceeded");

        token.pool.reserveETH += (ethAmount - ethAmountFee);
        token.pool.reserveTokens -= tokenAmount;
        token.pool.volume += ethAmount;

        (bool success,) = feeContract.call{value: ethAmountFee - ethAmountOwnerFee - affiliateFee}(""); // paying plat fee
        require(success, "fee ETH transfer failed");

        (success,) = _affiliate.call{value: affiliateFee}(""); // paying affiliate fee which is same amount as plat fee %
        require(success, "fee ETH transfer failed");

        (success,) = payable(owner()).call{value: ethAmountOwnerFee}(""); // paying owner fee per tx
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
        IFunEventTracker(eventTracker).buyEvent(msg.sender, funToken, msg.value, tokenAmount);

        uint256 currentMarketCap = getCurrentCap(funToken);
        uint256 listThresholdCap = token.pool.listThreshold * 10 ** IERC20Metadata(stableAddress).decimals();

        // using liquidity value inside contract to check when to add liquidity to DEX
        if (currentMarketCap >= (listThresholdCap / 2) && !token.pool.royalemitted) {
            IFunDeployer(token.deployer).emitRoyal(
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

            _addLiquidityETH(funToken, IERC20(funToken).balanceOf(address(this)), token.pool.reserveETH);
            token.pool.reserveETH = 0;
        }
    }

    function _addLiquidityETH(address funToken, uint256 amountTokenDesired, uint256 nativeForDex) internal {
        uint256 amountETH = nativeForDex;
        FunTokenPool storage token = tokenPools[funToken];

        address token0 = funToken < weth ? funToken : weth;
        address token1 = funToken < weth ? weth : funToken;

        if (token.storedLPAddress == address(0)) {
            uint256 price_numerator;
            uint256 price_denominator;

            if (token0 == funToken) {
                price_numerator = token.pool.reserveETH;
                price_denominator = token.pool.reserveTokens;
            } else {
                price_numerator = token.pool.reserveTokens;
                price_denominator = token.pool.reserveETH;
            }

            INonfungiblePositionManager(positionManager).createAndInitializePoolIfNecessary(
                token0, token1, poolFee, encodePriceSqrtX96(price_numerator, price_denominator)
            );

            token.storedLPAddress = IUniswapV3Factory(factory).getPool(token0, token1, poolFee);
            require(token.storedLPAddress != address(0), "Pool creation failed");
        }

        int24 tickLower = -887200; // Min tick
        int24 tickUpper = 887200; // Max tick

        // Approve tokens
        if (token0 == funToken) {
            IERC20(funToken).approve(positionManager, amountTokenDesired);
            IERC20(weth).approve(positionManager, amountETH);
        } else {
            IERC20(weth).approve(positionManager, amountETH);
            IERC20(funToken).approve(positionManager, amountTokenDesired);
        }

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: poolFee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: token0 == funToken ? amountTokenDesired : amountETH,
            amount1Desired: token0 == funToken ? amountETH : amountTokenDesired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        IWETH(weth).deposit{value: amountETH}();

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) =
            INonfungiblePositionManager(positionManager).mint(params);

        IERC721(positionManager).approve(feeContract, tokenId);
    }

    function encodePriceSqrtX96(uint256 price_numerator, uint256 price_denominator) internal pure returns (uint160) {
        require(price_denominator > 0, "Invalid price denominator");
        uint256 price = (price_numerator * (1 << 96)) / price_denominator;
        return uint160(sqrt(price));
    }

    // Helper function to calculate square root
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
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

    function updateWETH(address _newWETH) public onlyOwner {
        weth = _newWETH;
    }

    function updateFactory(address _newFactory) public onlyOwner {
        factory = _newFactory;
    }

    function updateRouter(address _newRouter) public onlyOwner {
        router = _newRouter;
    }

    function updatePositionManager(address _newPositionManager) public onlyOwner {
        positionManager = _newPositionManager;
    }

    function updatePoolFee(uint24 _newPoolFee) public onlyOwner {
        poolFee = _newPoolFee;
    }
}
