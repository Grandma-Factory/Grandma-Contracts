// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibraryRole {
    
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

}