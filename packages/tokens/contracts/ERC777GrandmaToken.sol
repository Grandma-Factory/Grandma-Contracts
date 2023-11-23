// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";


/// @title Grandma-Token
/// @dev Grandma-Factory platform utility token
/// @custom:security-contact security@grandma.digital
///
/// CAUTION: This GMA contract is no longuer up to date. See ERC20GrandmaToken. 
///
contract ERC777GrandmaToken is ERC777 {
    string public constant NAME = "Grandma-Token";
    string public constant SYMBOL = "GMA";
    uint256 public constant SUPPLY = 10 ** 28;

    constructor(address[] memory defaultOperators
    ) ERC777(NAME, SYMBOL, defaultOperators) {
        _mint(msg.sender, SUPPLY, "", "");
    }

}
