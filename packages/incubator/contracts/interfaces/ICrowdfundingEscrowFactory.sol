// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICrowdfundingEscrow.sol";

interface ICrowdfundingEscrowFactory {
    function createEscrow(address payable beneficiary_) external returns (ICrowdfundingEscrow);
}