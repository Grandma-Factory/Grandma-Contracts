// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library LibraryBasePoint {
    using SafeMathUpgradeable for uint;
    uint96 private constant BASEPOINT_100_00 = 10000;

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(BASEPOINT_100_00);
    }
}