// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20VaultFactory {
    function createERC20Vault(string memory name_, string memory symbol_, address[] memory tokenHolders_, uint256[] memory tokenAmounts_) external returns (IERC20);
}