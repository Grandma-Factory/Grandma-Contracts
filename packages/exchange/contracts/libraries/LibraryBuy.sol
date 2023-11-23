// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@grandma/library-asset/contracts/LibraryAsset.sol";


library LibraryBuy {

    struct Buy {
        address sellOrderMaker;
        uint256 sellOrderNftAmount;
        bytes4 nftAssetClass;
        bytes nftData;
        uint256 sellOrderPaymentAmount;
        address paymentToken;
        uint256 sellOrderSalt;
        uint sellOrderStart;
        uint sellOrderEnd;
        bytes4 sellOrderDataType;
        bytes sellOrderData;
        bytes sellOrderSignature;

        uint256 buyOrderPaymentAmount;
        uint256 buyOrderNftAmount;
        bytes buyOrderData;
    }
}
