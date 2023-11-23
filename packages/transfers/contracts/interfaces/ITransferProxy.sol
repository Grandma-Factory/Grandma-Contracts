// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@grandma/library-asset/contracts/LibraryAsset.sol";
import "./ITransferExecutor.sol";

interface ITransferProxy {
    
    function isAssetClassHandled(bytes4 assetClass) external returns(bool);

    function transfer(LibraryAsset.Asset calldata asset, address from, address to) external;

}