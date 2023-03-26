// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/////////////////////////////////////////
/// ! WIP. DO NOT USE IN PRODUCTION ! ///
/////////////////////////////////////////

/// @title Grandma-NFT
/// @dev Grandma-NFT, the Grandma NFT ERC721 token
/// @custom:security-contact security@grandma.digital
contract ERC721Grandma is ERC721, Pausable, AccessControl, ERC721Burnable, ERC2981 {
    using Counters for Counters.Counter;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    string private _chainBaseURI;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _chainBaseURI = string.concat("https://api.grandma.digital/token/", Strings.toHexString(uint256(uint160(address(this))), 20), "/");
    }
    
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _chainBaseURI = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _chainBaseURI;
    }

    // root baseURI is used as contract URI
    function contractURI() public view returns (string memory) {
        return _chainBaseURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
