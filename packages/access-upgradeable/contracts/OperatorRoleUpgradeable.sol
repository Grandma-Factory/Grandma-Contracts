// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@grandma/library-role/contracts/LibraryRole.sol";


abstract contract OperatorRoleUpgradeable is Initializable, AccessControlUpgradeable {

    function __OperatorRole_init(address initialAdmin) internal onlyInitializing {
        __OperatorRole_init_unchained(initialAdmin);
    }

    function __OperatorRole_init_unchained(address initialAdmin) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(LibraryRole.UPGRADER_ROLE, initialAdmin);
        _grantRole(LibraryRole.OPERATOR_ROLE, initialAdmin);
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    modifier onlyUpgrader() {
        _checkUpgrader();
        _;
    }

    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    function _checkAdmin() internal view virtual onlyRole(DEFAULT_ADMIN_ROLE) {}

    function _checkUpgrader() internal view virtual onlyRole(LibraryRole.UPGRADER_ROLE) {}

    function _checkOperator() internal view virtual onlyRole(LibraryRole.OPERATOR_ROLE) {}

    uint256[49] private __gap;
}
