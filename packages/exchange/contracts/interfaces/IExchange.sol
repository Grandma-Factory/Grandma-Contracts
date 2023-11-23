// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibraryOrder.sol";
import "../libraries/LibraryBuy.sol";
import "../libraries/LibrarySell.sol";

interface IExchange {

    function executeOrders(
            LibraryOrder.Order memory order,
            bytes memory signatureOrder, 
            LibraryOrder.Order memory bid, 
            bytes memory signatureBid) external;
            
    function cancelOrder(LibraryOrder.Order memory order) external;
}
