// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CrowdfundingEscrow.sol";
import "./interfaces/ICrowdfundingEscrowFactory.sol";


contract CrowdfundingEscrowFactory is ICrowdfundingEscrowFactory {

    function createEscrow(address payable beneficiary_) external returns (ICrowdfundingEscrow) {
        CrowdfundingEscrow escrow = new CrowdfundingEscrow(beneficiary_);
        escrow.transferOwnership(msg.sender);
        return escrow;
    }
    
}
