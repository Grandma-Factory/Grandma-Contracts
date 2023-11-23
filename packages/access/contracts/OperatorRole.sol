// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@grandma/library-role/contracts/LibraryRole.sol";

abstract contract OperatorRole is AccessControl {
    
    constructor(address initialAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(LibraryRole.OPERATOR_ROLE, initialAdmin);
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }
    
    modifier onlyOperator() {
        _checkOperator();
        _;
    }
    
    function _checkAdmin() internal view virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    }
    

    function _checkOperator() internal view virtual onlyRole(LibraryRole.OPERATOR_ROLE) {
    }
}