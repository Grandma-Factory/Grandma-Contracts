// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRewardDispatcher {

    function collectFees() external;
    function collectFees(IERC20Upgradeable[] calldata tokens) external;
    function dispatchFees() external;
    
}
