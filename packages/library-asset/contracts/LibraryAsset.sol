// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibraryAsset {
    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 constant public COLLECTION = bytes4(keccak256("COLLECTION"));

    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );

    bytes32 constant ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    struct AssetTypeDataERC20 {
        address contractAddress;
    }

    struct AssetTypeDataERC721 {
        address contractAddress;
        uint256 tokenId;
    }

    struct AssetTypeDataERC1155 {
        address contractAddress;
        uint256 tokenId;
    }

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPE_TYPEHASH,
                assetType.assetClass,
                keccak256(assetType.data)
            ));
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPEHASH,
                hash(asset.assetType),
                asset.value
            ));
    }

    function getAssetTypeDataERC20(AssetType memory assetType) internal pure returns (AssetTypeDataERC20 memory) { 
        return abi.decode(assetType.data, (AssetTypeDataERC20));
    }

    function getAssetTypeDataERC721(AssetType memory assetType) internal pure returns (AssetTypeDataERC721 memory) { 
        return abi.decode(assetType.data, (AssetTypeDataERC721));
    }

    function getAssetTypeDataERC1155(AssetType memory assetType) internal pure returns (AssetTypeDataERC1155 memory) { 
        return abi.decode(assetType.data, (AssetTypeDataERC1155));
    }

    function equalsAssetTypes(AssetType memory typeA, AssetType memory typeB) internal pure returns (bool) {
        return hash(typeA) == hash(typeB);
    }


}