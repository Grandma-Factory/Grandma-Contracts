// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibraryPair {
    bytes32 public constant TYPE_HASH = keccak256("Part(address addressA,address addressB");

    struct AddressPair {
        address addressA;
        address addressB;
    }

    function hash(AddressPair memory pair) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, pair.addressA, pair.addressB));
    }
}