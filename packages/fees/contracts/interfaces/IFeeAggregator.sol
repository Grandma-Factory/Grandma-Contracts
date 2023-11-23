// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

abstract contract IFeeAggregator {
    
    function release(address payable account) public virtual;
    function release(IERC20Upgradeable token, address account) public virtual;
    function releaseBatch(address payable[] memory accounts) external virtual;
    function releaseBatch(IERC20Upgradeable token, address[] memory accounts) external virtual;

}
