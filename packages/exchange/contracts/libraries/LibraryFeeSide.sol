// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@grandma/library-asset/contracts/LibraryAsset.sol";

library LibraryFeeSide {

    enum FeeSide {NONE, LEFT, RIGHT}

    function getFeeSide(bytes4 leftClass, bytes4 rightClass) internal pure returns (FeeSide) {
        if (leftClass == LibraryAsset.ETH_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibraryAsset.ETH_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        if (leftClass == LibraryAsset.ERC20_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibraryAsset.ERC20_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        if (leftClass == LibraryAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibraryAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        return FeeSide.NONE;
    }
}