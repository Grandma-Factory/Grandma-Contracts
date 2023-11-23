// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibraryTransferData.sol";

abstract contract ITransferExecutor {
    function transfer(LibraryTransferData.TransferData memory data) internal virtual;

    function transfer(LibraryAsset.Asset memory asset, address from, address to) internal virtual;
}
