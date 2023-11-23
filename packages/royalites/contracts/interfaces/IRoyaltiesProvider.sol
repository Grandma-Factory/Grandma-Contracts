// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@grandma/library-part/contracts/LibraryPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint256 tokenId) external returns (LibraryPart.Part[] memory);
}