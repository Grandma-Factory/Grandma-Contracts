// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/// @title ERC20RewardPool
/// @author Grandma-Factory
/// @notice ERC4626 implementation used to redistribute plateform fees to GMA stackers. A mincap is defined to enter the pool.
contract ERC20RewardPool is ERC4626 {
    using SafeMath for uint256;
    uint256 public _minCap;

    constructor(string memory name_, string memory symbol_, IERC20 asset_, uint256 minCap_) ERC20(name_, symbol_) ERC4626(asset_) {
        _minCap = minCap_;
    }

    /** 
     * Add mincap validation on deposit
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override virtual {
        require(assets >=_minCap, "ERC20RewardPool: Mincap not reached");
        return super._deposit(caller, receiver, assets, shares);
    }

    /**
     * Add mincap validation on withdraw
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override virtual {
        uint256 ownerAssetsAfter = maxWithdraw(owner).sub(assets);
        require(ownerAssetsAfter == 0 || ownerAssetsAfter == 0, "ERC20RewardPool: Mincap not preserved");

        super._withdraw(caller, receiver, owner, assets, shares);
    }
}