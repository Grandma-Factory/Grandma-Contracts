// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibrarySale.sol";

interface IIncubator {
    function getSaleCrowdfundingEscrow(LibrarySale.Sale memory sale) external view returns (address);
    function postSale(LibrarySale.Sale memory sale) external;
    function cancelSale(LibrarySale.Sale memory sale) external;
    function directBuy(LibrarySale.Sale memory sale) external payable;
    function finalizeCrowdfunding(LibrarySale.Sale memory sale) external;
}