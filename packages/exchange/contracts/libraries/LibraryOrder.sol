// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@grandma/library-asset/contracts/LibraryAsset.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./LibraryMath.sol";

library LibraryOrder {

    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address maker,Asset makeAsset,Asset takeAsset,uint256 start,uint256 end,bytes4 dataType,bytes data)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
        );

    bytes4 constant DEFAULT_ORDER_TYPE = 0xffffffff;

    struct Order {
        address maker;
        LibraryAsset.Asset makeAsset;
        LibraryAsset.Asset takeAsset;
        uint start;
        uint end;
        bytes4 dataType;
        bytes data;
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        //order.data is in hash for V2, V3 and all new order
        return
            keccak256(
                abi.encode(
                    order.maker,
                    LibraryAsset.hash(order.makeAsset.assetType),
                    LibraryAsset.hash(order.takeAsset.assetType),
                    order.data
                )
            );
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    LibraryAsset.hash(order.makeAsset),
                    LibraryAsset.hash(order.takeAsset),
                    order.start,
                    order.end,
                    order.dataType,
                    keccak256(order.data)
                )
            );
    }

    function validateOrderTime(LibraryOrder.Order memory order) internal view {
        require(order.start == 0 || order.start < block.timestamp, "Order start validation failed");
        require(order.end == 0 || order.end > block.timestamp, "Order end validation failed");
    }

    function validateSignature(LibraryOrder.Order memory order, bytes memory signature) internal view {
        require(SignatureChecker.isValidSignatureNow(order.maker, hash(order), signature), "order signature verification error");
    }
}
