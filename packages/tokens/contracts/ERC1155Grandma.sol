// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @title ERC1155Grandma
/// @dev ERC1155Grandma contract used to store grandma digital assets
/// @custom:security-contact security@grandma.digital
contract ERC1155Grandma is ERC1155, AccessControl, Pausable, ERC1155Supply, ERC2981 {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROYALTIES_ROLE = keccak256("ADMIN_ROYALTIES_ROLE");

    constructor()
        ERC1155(
            string.concat("https://api.grandma.digital/token/", Strings.toHexString(uint256(uint160(address(this))), 20), "/{id}")
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROYALTIES_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(ADMIN_ROYALTIES_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyRole(ADMIN_ROYALTIES_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyRole(ADMIN_ROYALTIES_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    function deleteDefaultRoyalty() public onlyRole(ADMIN_ROYALTIES_ROLE) {
        deleteDefaultRoyalty();
    }

    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _resetTokenRoyalty(id);
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            _resetTokenRoyalty(id);
        }
        _burnBatch(account, ids, values);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
