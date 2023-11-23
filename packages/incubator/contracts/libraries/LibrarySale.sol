// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@grandma/library-asset/contracts/LibraryAsset.sol";

library LibrarySale {
    using SafeMathUpgradeable for uint;

    bytes32 constant SALE_TYPEHASH =
        keccak256(
            "Sale(address maker,Asset asset,uint256 amount,uint256 fee,uint256 start,uint256 end,string vaultName,string vaultSymbole,uint256 salt)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
        );

    uint16 constant FEE_DENOMINATOR = 10000;

    struct Sale {
        address payable maker;
        LibraryAsset.Asset asset;
        uint256 amount;
        uint256 fee; // base point, ex: 125 = 1,25%
        uint256 start;
        uint256 end;
        string vaultName;
        string vaultSymbole;
        uint256 salt;
    }

    function hash(Sale memory sale) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SALE_TYPEHASH,
                    sale.maker,
                    LibraryAsset.hash(sale.asset),
                    sale.amount,
                    sale.fee,
                    sale.start,
                    sale.end,
                    sale.vaultName,
                    sale.vaultSymbole,
                    sale.salt
                )
            );
    }

    function validateSaleTime(Sale memory sale) internal view {
        require(sale.start == 0 || sale.start < block.timestamp, "Sale start validation failed");
        require(sale.end == 0 || sale.end > block.timestamp, "Sale end validation failed");
    }

    function calculRemainingFunding(Sale memory sale, uint256 raisedWithFees) internal pure returns (uint256) {
        uint256 amountWithFees = sale.amount.mul(sale.fee).div(FEE_DENOMINATOR).add(sale.amount);
        return amountWithFees.sub(raisedWithFees);
    }
}
