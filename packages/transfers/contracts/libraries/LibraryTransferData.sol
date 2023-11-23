// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@grandma/library-part/contracts/LibraryPart.sol";
import "@grandma/library-asset/contracts/LibraryAsset.sol";

library LibraryTransferData {
    struct TransferData {
        LibraryAsset.Asset asset;
        LibraryPart.Part[] payouts;
        address from;
    }

    struct TransferContext {
        uint maxFeesBasePoint;
    }
}