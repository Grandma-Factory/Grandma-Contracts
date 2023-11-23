// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title Grandma-Token
/// @dev Grandma-Factory platform utility token
/// @custom:security-contact security@grandma.digital
contract ERC20GrandmaToken is ERC20, ERC20Permit {
    string public constant NAME = "Grandma-Token";
    string public constant SYMBOL = "GMA";
    uint256 public constant SUPPLY = 10 ** 28;

    constructor() ERC20(NAME, SYMBOL) ERC20Permit(NAME)  {
        _mint(msg.sender, SUPPLY);
    }

}

