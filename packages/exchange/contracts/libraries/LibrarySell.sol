// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@grandma/library-asset/contracts/LibraryAsset.sol";

library LibrarySell {
    
    struct Sell {
        address bidMaker;
        uint256 bidNftAmount;
        bytes4 nftAssetClass;
        bytes nftData;
        uint256 bidPaymentAmount;
        address paymentToken;
        uint256 bidSalt;
        uint bidStart;
        uint bidEnd;
        bytes4 bidDataType;
        bytes bidData;
        bytes bidSignature;

        uint256 sellOrderPaymentAmount;
        uint256 sellOrderNftAmount;
        bytes sellOrderData;
    }
}
