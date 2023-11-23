// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/escrow/ConditionalEscrow.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICrowdfundingEscrow.sol";

/// @title Incubator
/// @dev Incubator is the incubator contract of the Grandma-Factory plateform. Implementation tuned from Openzeppelin RefundEscrow contract.
/// @custom:security-contact security@grandma.digital
contract CrowdfundingEscrow is ICrowdfundingEscrow, ConditionalEscrow {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Closed();
    event Canceled();

    State private _state;
    address payable private immutable _beneficiary;

    uint256 public _totalDeposits;
    EnumerableSet.AddressSet private _depositors;

    /**
     * @dev Constructor.
     * @param beneficiary_ The beneficiary of the deposits.
     */
    constructor(address payable beneficiary_) {
        require(beneficiary_ != address(0), "CrowdfundingEscrow: beneficiary is the zero address");
        _beneficiary = beneficiary_;
        _state = State.Active;
    }

    /**
     * @return The current state of the escrow.
     */
    function state() public view returns (State) {
        return _state;
    }

    /**
     * @return The beneficiary of the escrow.
     */
    function beneficiary() public view returns (address payable) {
        return _beneficiary;
    }

    /**
     * @dev Stores funds that may later be refunded.
     * @param refundee The address funds will be sent to if a refund occurs.
     */
    function deposit(address refundee) public payable override(ICrowdfundingEscrow, Escrow) {
        require(state() == State.Active, "CrowdfundingEscrow: can only deposit while active");

        super.deposit(refundee);
        _totalDeposits += msg.value;

        if (msg.value > 0) {
            _depositors.add(refundee);
        }
    }

    /**
     * @dev Allows for the beneficiary to withdraw their funds, rejecting
     * further deposits.
     */
    function close() public onlyOwner {
        require(state() == State.Active, "CrowdfundingEscrow: can only close while active");
        _state = State.Closed;
        emit Closed();
    }

    /**
     * @dev Allows for refunds to take place, rejecting further deposits.
     */
    function cancel() public onlyOwner {
        require(state() == State.Active, "CrowdfundingEscrow: can only cancel while active");
        _state = State.Canceled;
        emit Canceled();
    }

    /**
     * @dev Withdraws the beneficiary's funds.
     */
    function beneficiaryWithdraw() public {
        require(state() == State.Closed, "CrowdfundingEscrow: beneficiary can only withdraw while closed");
        beneficiary().sendValue(address(this).balance);
    }

    /**
     * @dev Returns whether refundees can withdraw their deposits (be refunded).
     *  We override to allow refund at any time until crowdfuncing is closed.
     */
    function withdrawalAllowed(address) public view override(ICrowdfundingEscrow, ConditionalEscrow) returns (bool) {
        return state() != State.Closed;
    }

    /**
     * Withdraw an participation.
     * Only possible if the payee is the caller.
     * 
     * @param payee the payee to refund
     */
    function withdraw(address payable payee) public override(ICrowdfundingEscrow, ConditionalEscrow) {
        require(msg.sender == payee, "CrowdfundingEscrow: Only deposit owner can withdraw his funds");
        _totalDeposits -= super.depositsOf(payee);
        _depositors.remove(payee);

        super.withdraw(payee);
    }

    /**
     * Get the depositors addresses and participations
     * @return addresses depositors addresses
     * @return amounts depositors participations
     */
    function getDepositors() external view returns (address[] memory, uint256[] memory) {
        address[] memory depositors = new address[](_depositors.length());
        uint256[] memory amounts = new uint256[](_depositors.length());

        for (uint256 i = 0; i < _depositors.length(); i++) {
            amounts[i] = super.depositsOf(_depositors.at(i));
        }
        return (depositors, amounts);
    }

    /**
     * Get the totals deposits on the escrow
     */
    function getTotalDeposits() external view returns (uint256) {
        return _totalDeposits;
    }
}
