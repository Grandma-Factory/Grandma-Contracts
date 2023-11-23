// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrowdfundingEscrow {
    enum State {
        Active,
        Closed,
        Canceled
    }

    function state() external view returns (State);
    function beneficiary() external view returns (address payable);
    function deposit(address refundee) external payable;
    function close() external;
    function cancel() external;
    function beneficiaryWithdraw() external;
    function withdrawalAllowed(address) external view returns (bool);
    function withdraw(address payable payee) external;
    function getDepositors() external view returns (address[] memory, uint256[] memory);
    function getTotalDeposits() external view returns (uint256);
}