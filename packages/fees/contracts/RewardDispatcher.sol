// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@grandma/interfaces/contracts/IWETH.sol";
import "@grandma/access-upgradeable/contracts/OperatorRoleUpgradeable.sol";
import "./interfaces/IRewardDispatcher.sol";
import "./interfaces/IFeeAggregator.sol";

/// @title RewardDispatcher
/// @author Grandma-Factory
/// @notice Contract used to dispatch fees on multiple reward pools by applying reward boost multiplier. Note that ETH and Tokens collected are swapped to GMA.
/// @custom:security-contact security@grandma.digital
contract RewardDispatcher is
    IRewardDispatcher,
    Initializable,
    OperatorRoleUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint24 private constant UNISWAP_POOL_FEE = 300;

    IERC20Upgradeable public grandmaToken;
    IFeeAggregator public feeAggregator;
    ISwapRouter public swapRouter;
    IWETH public weth;

    // reward tokens datas
    EnumerableSet.AddressSet private _pools;
    mapping(address => uint96) private _poolsBoost;

    event Distributed(address poolAddress, uint _amount);
    event Received(address, uint256);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20Upgradeable grandmaToken_,
        IFeeAggregator feeAggregator_,
        ISwapRouter swapRouter_,
        IWETH weth_
    ) public initializer {
        __OperatorRole_init(msg.sender);
        __UUPSUpgradeable_init();

        grandmaToken = grandmaToken_;
        feeAggregator = feeAggregator_;
        swapRouter = swapRouter_;
        weth = weth_;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyUpgrader {}

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Set the fee aggregator contract address
     * @param feeAggregator_  the fee aggregator contract address
     */
    function setFeeAggregator(IFeeAggregator feeAggregator_) public onlyOperator {
        feeAggregator = feeAggregator_;
    }

    /**
     * @dev Set the wrapped ethereum contract
     * @param weth_ the wrapped ethereum contract
     */
    function setWETH(IWETH weth_) public onlyOperator {
        weth = weth_;
    }

    /**
     * @dev Add a pool with the specified boost factor
     * @param poolAddress the address of the pool
     * @param boost the boost factor
     */
    function addPool(address payable poolAddress, uint96 boost) public onlyOperator {
        require(poolAddress != address(0), "RewardDispatcher: poolAddress should be defined");
        require(boost != 0, "RewardDispatcher: boost should be defined (100 is 1x)");
        _pools.add(poolAddress);
        _poolsBoost[poolAddress] = boost;
    }

    /**
     * Remove the specified pool
     * @param poolAddress the pool address
     */
    function removePool(address payable poolAddress) public onlyOperator {
        require(_pools.contains(poolAddress), "RewardDispatcher: Reward pool not found");
        _pools.remove(poolAddress);
        delete _poolsBoost[poolAddress];
    }

    /**
     * Get the defined pools addresses
     */
    function getPools() public view returns (address[] memory) {
        return _pools.values();
    }

    /**
     * Get the pool boost for the specified pool address
     * @param poolAddress the pool address
     */
    function getPoolBoost(address payable poolAddress) public view returns (uint96) {
        require(_pools.contains(poolAddress), "RewardDispatcher: Reward pool not found");
        return _poolsBoost[poolAddress];
    }

    /**
     * Collect ETH fees from the fee aggregator.
     * Ethers are deposited on the wrapped ethereum contract.
     * WETH are swapped through Uniswap V3 router.
     */
    function collectFees() external {
        // collect ETH from fee aggregator
        feeAggregator.release(payable(address(this)));

        // swap ETH to GMA
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            // deposit ETH to WETH contract
            weth.deposit{value: ethBalance}();
            // swap WETH to GMA
            _swapTokenForGMA(address(weth), ethBalance);
        }
    }

    /**
     * Collect tokens fees from fee aggregator and swap them to GMA thought Uniswap V3 router.
     * @param tokens the array of tokens to collect
     */
    function collectFees(IERC20Upgradeable[] calldata tokens) external {
        // collect tokens from fee aggregator
        for (uint i = 0; i < tokens.length; ++i) {
            _collectTokenFees(tokens[i]);
        }
    }

    function _collectTokenFees(IERC20Upgradeable token) internal {
        feeAggregator.release(token, address(this));

        if (address(token) != address(grandmaToken)) {
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                _swapTokenForGMA(address(token), balance);
            }
        }
    }

    function _swapTokenForGMA(address token, uint256 amount) private returns (uint256 amountOut) {
        require(amount > 0, "Amount must not be 0");

        TransferHelper.safeApprove(token, address(swapRouter), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: token,
            tokenOut: address(grandmaToken),
            fee: UNISWAP_POOL_FEE, // 0.3% fee
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        return swapRouter.exactInputSingle(params);
    }

    /**
     * Dispach fees through defined pools.
     * see grandma whitepaper for the distribution formula
     */
    function dispatchFees() external nonReentrant {
        uint256 amount = grandmaToken.balanceOf(address(this));

        // compute new reward supplies
        // ignore closed pools
        uint256 sumSkBk = 0;

        uint256[] memory poolsBalance = new uint256[](_pools.length());

        for (uint i = 0; i < _pools.length(); i++) {
            address poolAddress = _pools.at(i);
            uint96 poolBoost = _poolsBoost[poolAddress];

            // retreive GMA balance and store it
            poolsBalance[i] = grandmaToken.balanceOf(poolAddress);

            // compute SkBk. see Grandma-Factory whitepaper for calculation formulas
            uint256 skBk = poolsBalance[i].mul(poolBoost);
            sumSkBk = sumSkBk.add(skBk);
        }
        require(sumSkBk > 0, "RewardDispatcher: Sum of supply times boost must be greater than zero");

        for (uint i = 0; i < _pools.length(); i++) {
            address poolAddress = _pools.at(i);

            // compute reward for each pools and execute transfer
            uint256 siBi = poolsBalance[i].mul(_poolsBoost[poolAddress]);
            uint256 poolReward = amount.mul(siBi).div(sumSkBk);

            grandmaToken.transfer(poolAddress, poolReward);
            emit Distributed(poolAddress, poolReward);
        }
    }
}
