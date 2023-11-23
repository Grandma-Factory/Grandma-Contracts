// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@grandma/library-role/contracts/LibraryRole.sol";
import "@grandma/library-asset/contracts/LibraryAsset.sol";
import "@grandma/access-upgradeable/contracts/OperatorRoleUpgradeable.sol";
import "./interfaces/ITransferProxy.sol";
import "./libraries/LibraryTransfer.sol";

contract TransferProxy is
    ITransferProxy,
    Initializable,
    OperatorRoleUpgradeable,
    UUPSUpgradeable
{
    using LibraryTransfer for address;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __OperatorRole_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyUpgrader {}

    function isAssetClassHandled(bytes4 assetClass) external pure override returns (bool) {
        return _isAssetClassHandled(assetClass);
    }

    function _isAssetClassHandled(bytes4 assetClass) internal pure returns (bool) {
        return
            assetClass == LibraryAsset.ERC721_ASSET_CLASS ||
            assetClass == LibraryAsset.ERC20_ASSET_CLASS ||
            assetClass == LibraryAsset.ERC1155_ASSET_CLASS;
    }

    function transfer(LibraryAsset.Asset calldata asset, address from, address to) external override onlyOperator {
        require(_isAssetClassHandled(asset.assetType.assetClass), "TransferProxy: unhandled asset type");

        if (asset.assetType.assetClass == LibraryAsset.ERC721_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            require(asset.value == 1, "TransferProxy: ERC721 value error");
            _erc721safeTransferFrom(IERC721Upgradeable(token), from, to, tokenId);
        } else if (asset.assetType.assetClass == LibraryAsset.ERC20_ASSET_CLASS) {
            address token = abi.decode(asset.assetType.data, (address));
            _erc20safeTransferFrom(IERC20Upgradeable(token), from, to, asset.value);
        } else if (asset.assetType.assetClass == LibraryAsset.ERC1155_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            _erc1155safeTransferFrom(IERC1155Upgradeable(token), from, to, tokenId, asset.value, "");
        }
    }

    function _erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        if (from == address(this)) {
            require(token.transfer(to, value), "failure while transferring");
        } else {
            require(token.transferFrom(from, to, value), "failure while transferring");
        }
    }

    function _erc721safeTransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) internal {
        token.safeTransferFrom(from, to, tokenId);
    }

    function _erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        token.safeTransferFrom(from, to, id, value, data);
    }
}
