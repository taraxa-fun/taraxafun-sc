// SPDX-License-Identifier: MIT
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
import {IFunLPManager} from "./interfaces/IFunLPManager.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IFunToken} from "./interfaces/IFunToken.sol";

import {INonfungiblePositionManager} from "@v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Factory} from "@v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract FunPool is Ownable, ReentrancyGuard {
    using FixedPointMathLib for uint256;

    struct FunTokenPoolData {
        uint256 reserveTokens;
        uint256 reserveTARA;
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

    uint256 public constant BASIS_POINTS = 10000;

    address public wtara = 0x4200000000000000000000000000000000000006;
    address public factory = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public router = 0x050E797f3625EC8785265e1d9BDd4799b97528A1; 
    address public positionManager = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    // deployer allowed to create fun tokens
    mapping(address => bool) public allowedDeployers;
    // user => array of fun tokens
    mapping(address => address[]) public userFunTokens;
    // fun token => fun token details
    mapping(address => FunTokenPool) public tokenPools;

    address public implementation;
    address public feeContract;
    address public stableAddress;
    address public LPManager;
    address public eventTracker;

    uint24 public uniswapPoolFee = 10000;

    event LiquidityAdded(address indexed provider, uint256 tokenAmount, uint256 taraAmount);

    event listed(
        address indexed tokenAddress,
        address indexed router,
        address indexed pair,
        uint256 liquidityAmount,
        uint256 tokenAmount,
        uint256 time,
        uint256 totalVolume
    );

    constructor(
        address _implementation,
        address _feeContract,
        address _LPManager,
        address _stableAddress,
        address _eventTracker
    ) payable Ownable(msg.sender) {
        implementation = _implementation;
        feeContract = _feeContract;
        LPManager = _LPManager;
        stableAddress = _stableAddress;
        eventTracker = _eventTracker;
    }

    function initFun(
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
        pool.baseToken = wtara;
        pool.router = router;
        pool.deployer = msg.sender;

        pool.pool.tradeActive = true;
        pool.pool.reserveTokens += _totalSupply;
        pool.pool.reserveTARA += (listThreshold_initReserveEth[1] + msg.value);
        pool.pool.listThreshold = listThreshold_initReserveEth[0];
        pool.pool.initialReserveEth = listThreshold_initReserveEth[1];
        pool.pool.maxBuyPerWallet = _maxBuyPerWallet;

        // add the fun data for the fun token
        tokenPools[funToken] = pool;

        emit LiquidityAdded(address(this), _totalSupply, msg.value);

        return address(funToken); 
    }

    // Calculate amount of output tokens based on input TARA
    function getAmountOutTokens(address funToken, uint256 amountIn) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid input amount");
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.reserveTokens > 0 && token.pool.reserveTARA > 0, "Invalid reserves");

        uint256 numerator = amountIn * token.pool.reserveTokens;
        uint256 denominator = (token.pool.reserveTARA) + amountIn;
        amountOut = numerator / denominator;
    }

    // Calculate amount of output TARA based on input tokens
    function getAmountOutTARA(address funToken, uint256 amountIn) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid input amount");
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.reserveTokens > 0 && token.pool.reserveTARA > 0, "Invalid reserves");

        uint256 numerator = amountIn * token.pool.reserveTARA;
        uint256 denominator = (token.pool.reserveTokens) + amountIn;
        amountOut = numerator / denominator;
    }

    function getBaseToken(address funToken) public view returns (address) {
        FunTokenPool storage token = tokenPools[funToken];
        return address(token.baseToken);
    }

    function getAmountsMinToken(address funToken, address stableAddress, uint256 taraIN) public view returns (uint256) {
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

        return FixedPointMathLib.mulWadDown(taraIN, sqrtPriceAdjusted);

        */

        /// 10000 = 0.01$
        return FixedPointMathLib.mulWadDown(taraIN, 10000);
    }

    function getCurrentCap(address funToken) public view returns (uint256) {
        FunTokenPool storage token = tokenPools[funToken];

        return (getAmountsMinToken(funToken, stableAddress, token.pool.reserveTARA) * IERC20(funToken).totalSupply())
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
        uint256 taraAmount = getAmountOutTARA(funToken, tokenToSell);
        uint256 taraAmountFee = (taraAmount * IFunDeployer(token.deployer).getTradingFeePer()) / BASIS_POINTS;
        uint256 taraAmountOwnerFee = (taraAmountFee * IFunDeployer(token.deployer).getDevFeePer()) / BASIS_POINTS;
        uint256 affiliateFee =
            (taraAmountFee * (IFunDeployer(token.deployer).getAffiliatePer(_affiliate))) / BASIS_POINTS;
        require(taraAmount > 0 && taraAmount >= minEth, "Slippage too high");

        token.pool.reserveTokens += tokenAmount;
        token.pool.reserveTARA -= taraAmount;
        token.pool.volume += taraAmount;

        IERC20(funToken).transferFrom(msg.sender, address(this), tokenToSell);
        (bool success,) = feeContract.call{value: taraAmountFee - taraAmountOwnerFee - affiliateFee}("");
        require(success, "fee TARA transfer failed");

        (success,) = _affiliate.call{value: affiliateFee}(""); 
        require(success, "aff TARA transfer failed");

        (success,) = payable(owner()).call{value: taraAmountOwnerFee}(""); 
        require(success, "ownr TARA transfer failed");

        (success,) = msg.sender.call{value: taraAmount - taraAmountFee}("");
        require(success, "seller TARA transfer failed");

        IFunEventTracker(eventTracker).sellEvent(msg.sender, funToken, tokenToSell, taraAmount);

        return (true, true);
    }

    function buyTokens(address funToken, uint256 minTokens, address _affiliate) public payable nonReentrant {
        require(msg.value > 0, "Invalid buy value");
        FunTokenPool storage token = tokenPools[funToken];
        require(token.pool.tradeActive, "Trading not active");

        uint256 taraAmount = msg.value;
        uint256 taraAmountFee = (taraAmount * IFunDeployer(token.deployer).getTradingFeePer()) / BASIS_POINTS;
        uint256 taraAmountOwnerFee = (taraAmountFee * (IFunDeployer(token.deployer).getDevFeePer())) / BASIS_POINTS;
        uint256 affiliateFee = (taraAmountFee * (IFunDeployer(token.deployer).getAffiliatePer(_affiliate))) / BASIS_POINTS;

        uint256 tokenAmount = getAmountOutTokens(funToken, taraAmount - taraAmountFee);
        require(tokenAmount >= minTokens, "Slippage too high");
        require(checkMaxBuyPerWallet(funToken, tokenAmount), "Max buy per wallet exceeded");

        token.pool.reserveTARA += (taraAmount - taraAmountFee);
        token.pool.reserveTokens -= tokenAmount;
        token.pool.volume += taraAmount;

        (bool success,) = feeContract.call{value: taraAmountFee - taraAmountOwnerFee - affiliateFee}("");
        require(success, "fee TARA transfer failed");

        (success,) = _affiliate.call{value: affiliateFee}("");
        require(success, "fee TARA transfer failed");

        (success,) = payable(owner()).call{value: taraAmountOwnerFee}(""); 
        require(success, "fee TARA transfer failed");

        IERC20(funToken).transfer(msg.sender, tokenAmount);
        
        IFunEventTracker(eventTracker).buyEvent(
            msg.sender, 
            funToken, 
            msg.value, 
            tokenAmount
        );

        uint256 currentMarketCap = getCurrentCap(funToken);
        uint256 listThresholdCap = token.pool.listThreshold * 10 ** 6; ///** IERC20Metadata(stableAddress).decimals();

        /// royal emit when marketcap is half of listThresholdCap
        if (currentMarketCap >= (listThresholdCap / 2) && !token.pool.royalemitted) {
            IFunDeployer(token.deployer).emitRoyal(
                funToken, token.pool.reserveTARA, token.pool.reserveTokens, block.timestamp, token.pool.volume
            );
            token.pool.royalemitted = true;
        }
        // using marketcap value of token to check when to add liquidity to DEX
        if (currentMarketCap >= listThresholdCap) {
            token.pool.tradeActive = false;
            IFunToken(funToken).initiateDex();
            token.pool.reserveTARA -= token.pool.initialReserveEth;

            _addLiquidityV3(funToken, IERC20(funToken).balanceOf(address(this)), token.pool.reserveTARA);

            uint256 reserveTARA = token.pool.reserveTARA;
            token.pool.reserveTARA = 0;

            emit listed(
                token.token,
                token.router,
                token.storedLPAddress,
                reserveTARA,
                token.pool.reserveTokens,
                block.timestamp,
                token.pool.volume
            );
        }
    }

    function _addLiquidityV3(address funToken, uint256 amountTokenDesired, uint256 nativeForDex) internal {
        FunTokenPool storage token = tokenPools[funToken];

        address token0 = funToken < wtara ? funToken : wtara;
        address token1 = funToken < wtara ? wtara : funToken;

        uint256 price_numerator;
        uint256 price_denominator;

        if (token0 == funToken) {
            price_numerator = nativeForDex;
            price_denominator = amountTokenDesired;
        } else {
            price_numerator = amountTokenDesired;
            price_denominator = nativeForDex;
        }

        if (token.storedLPAddress == address(0)) {
            INonfungiblePositionManager(positionManager).createAndInitializePoolIfNecessary(
                token0, token1, uniswapPoolFee, encodePriceSqrtX96(price_numerator, price_denominator)
            );
            token.storedLPAddress = IUniswapV3Factory(factory).getPool(token0, token1, uniswapPoolFee);
            require(token.storedLPAddress != address(0), "Pool creation failed");
        }

        IWETH(wtara).deposit{value: nativeForDex}();

        IERC20(wtara).approve(positionManager, nativeForDex);
        IERC20(funToken).approve(positionManager, amountTokenDesired);

        int24 tickLower = -887200;
        int24 tickUpper = 887200;

        uint256 _amount0Desired = (token0 == funToken ? amountTokenDesired : nativeForDex);
        uint256 _amount1Desired = (token0 == funToken ? nativeForDex : amountTokenDesired);

        uint256 _amount0Min = (_amount0Desired * 95) / 100;
        uint256 _amount1Min = (_amount1Desired * 95) / 100;

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: uniswapPoolFee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: _amount0Desired,
            amount1Desired: _amount1Desired,
            amount0Min: _amount0Min,
            amount1Min: _amount1Min,
            recipient: address(this),
            deadline: block.timestamp + 1
        });

        (uint256 tokenId,,,) = INonfungiblePositionManager(positionManager).mint(params);

        IERC721(positionManager).approve(feeContract, tokenId);

        IFunLPManager(LPManager).depositNFTPosition(tokenId, msg.sender);
    }

    function encodePriceSqrtX96(uint256 price_numerator, uint256 price_denominator) internal pure returns (uint160) {
        require(price_denominator > 0, "Invalid price denominator");
        uint256 ratioX192 = (price_numerator << 192) / price_denominator;

        return uint160(sqrt(ratioX192));
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

    function setImplementation(address _implementation) public onlyOwner {
        require(_implementation != address(0), "Invalid implementation");
        implementation = _implementation;
    }

    function setFeeContract(address _newFeeContract) public onlyOwner {
        require(_newFeeContract != address(0), "Invalid fee contract");
        feeContract = _newFeeContract;
    }

    function setLPManager(address _newLPManager) public onlyOwner {
        require(_newLPManager != address(0), "Invalid LP lock deployer");
        LPManager = _newLPManager;
    }

    function setEventTracker(address _newEventTracker) public onlyOwner {
        require(_newEventTracker != address(0), "Invalid event tracker");
        eventTracker = _newEventTracker;
    }

    function setStableAddress(address _newStableAddress) public onlyOwner {
        require(_newStableAddress != address(0), "Invalid stable address");
        stableAddress = _newStableAddress;
    }

    function setwtara(address _newwtara) public onlyOwner {
        require(_newwtara != address(0), "Invalid wtara");
        wtara = _newwtara;
    }

    function setFactory(address _newFactory) public onlyOwner {
        require(_newFactory != address(0), "Invalid factory");
        factory = _newFactory;
    }

    function setRouter(address _newRouter) public onlyOwner {
        require(_newRouter != address(0), "Invalid router");
        router = _newRouter;
    }

    function setPositionManager(address _newPositionManager) public onlyOwner {
        require(_newPositionManager != address(0), "Invalid position manager");
        positionManager = _newPositionManager;
    }

    function setuniswapPoolFee(uint24 _newuniswapPoolFee) public onlyOwner {
        require(_newuniswapPoolFee > 0, "Invalid pool fee");
        uniswapPoolFee = _newuniswapPoolFee;
    }

    function findNearestValidTick(int256 tickSpacing, bool nearestToMin) public pure returns (int256) {
        require(tickSpacing > 0, "Tick spacing must be positive");

        int24 MIN_TICK = -887272; // Min tick
        int24 MAX_TICK = 887272; // Max tick

        if (nearestToMin) {
            // Adjust to find a tick greater than or equal to MIN_TICK.
            int256 adjustedMinTick = MIN_TICK + (tickSpacing - 1);
            // Prevent potential overflow.
            if (MIN_TICK < 0 && adjustedMinTick > 0) {
                adjustedMinTick = MIN_TICK;
            }
            int256 adjustedTick = (adjustedMinTick / tickSpacing) * tickSpacing;
            // Ensure the adjusted tick does not fall below MIN_TICK.
            return (adjustedTick > MIN_TICK) ? adjustedTick - tickSpacing : adjustedTick;
        } else {
            // Find the nearest valid tick less than or equal to MAX_TICK, straightforward due to floor division.
            return (MAX_TICK / tickSpacing) * tickSpacing;
        }
    }
}
