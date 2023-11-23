// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20VaultFactory.sol";
import "../ERC20Vault.sol";

contract ERC20VaultFactory {

    function createERC20Vault(string memory name_, string memory symbol_, address[] memory tokenHolders_, uint256[] memory tokenAmounts_) external returns (IERC20){
        ERC20Vault vault= new ERC20Vault(name_, symbol_, tokenHolders_, tokenAmounts_);
        vault.transferOwnership(msg.sender);
        return vault;
    }

}