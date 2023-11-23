// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@grandma/access-upgradeable/contracts/OperatorRoleUpgradeable.sol";
import "./interfaces/IFeeAggregator.sol";

/// @title FeeAggregator
/// @author Grandma-Factory
/// @notice This contract is used to collect all the platform fees (ETH or ERC20). It implements PaymentSplitterUpgradeable so fees can be redistributed regarding defined shares.
/// @custom:security-contact security@grandma.digital
contract FeeAggregator is IFeeAggregator, PaymentSplitterUpgradeable, OperatorRoleUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory payees_, uint256[] memory shares_) public initializer {
        __PaymentSplitter_init(payees_, shares_);
        __OperatorRole_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyUpgrader {}

    function release(address payable account) public override(IFeeAggregator, PaymentSplitterUpgradeable) {
        super.release(account);
    }

    function release(IERC20Upgradeable token, address account) public override(IFeeAggregator, PaymentSplitterUpgradeable) {
        super.release(token, account);
    }

    function releaseBatch(address payable[] memory accounts) external override {
        for (uint256 i = 0; i < accounts.length; ++i) {
            release(accounts[i]);
        }
    }

    function releaseBatch(IERC20Upgradeable token, address[] memory accounts) external override {
        for (uint256 i = 0; i < accounts.length; ++i) {
            release(token, accounts[i]);
        }
    }
}
