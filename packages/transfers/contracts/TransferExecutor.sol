// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@grandma/access-upgradeable/contracts/OperatorRoleUpgradeable.sol";
import "@grandma/library-asset/contracts/LibraryAsset.sol";
import "@grandma/library-basepoint/contracts/LibraryBasePoint.sol";
import "./interfaces/ITransferExecutor.sol";
import "./interfaces/ITransferProxy.sol";
import "./libraries/LibraryTransfer.sol";

abstract contract TransferExecutor is ITransferExecutor, Initializable, OperatorRoleUpgradeable {
    using SafeMathUpgradeable for uint;
    using LibraryBasePoint for uint;
    using LibraryTransfer for address;

    mapping(bytes4 => ITransferProxy) internal proxies;

    event ProxyChange(bytes4 indexed assetType, ITransferProxy proxy);

    function __TransferExecutor_init(bytes4[] memory assetClasses_, ITransferProxy[] memory proxies_) internal onlyInitializing {
        __TransferExecutor_init_unchained(assetClasses_, proxies_);
    }

    function __TransferExecutor_init_unchained(
        bytes4[] memory assetClasses_,
        ITransferProxy[] memory proxies_
    ) internal onlyInitializing {
        require(assetClasses_.length == proxies_.length, "TransferExecutor: bad constructor arguments");

        for (uint i = 0; i < assetClasses_.length; i++) {
            proxies[assetClasses_[i]] = proxies_[i];
        }
    }

    function setTransferProxy(bytes4 assetType, ITransferProxy proxy) external onlyOperator {
        proxies[assetType] = proxy;
        emit ProxyChange(assetType, proxy);
    }

    function transfer(LibraryAsset.Asset memory asset, address from, address to) internal override {
        if (asset.assetType.assetClass == LibraryAsset.ETH_ASSET_CLASS) {
            // ETH cannot be proxyfied
            require(from == address(this), "TransferExecutor: only ETH owned can be spent");
            to.transferEth(asset.value);
        }

        require(address(proxies[asset.assetType.assetClass]) != address(0), "TransferExecutor: Unhandled asset type");
        ITransferProxy proxy = proxies[asset.assetType.assetClass];
        proxy.transfer(asset, from, to);
    }

    function transfer(LibraryTransferData.TransferData memory data
    ) internal override{
        transferPayouts(data.asset.assetType, data.asset.value, data.from, data.payouts);
    }

    /**
        @notice transfers main part of the asset (payout)
        @param assetType Asset Type to transfer
        @param amount Amount of the asset to transfer
        @param from Current owner of the asset
        @param payouts List of payouts - receivers of the Asset
    */
    function transferPayouts(
        LibraryAsset.AssetType memory assetType,
        uint amount,
        address from,
        LibraryPart.Part[] memory payouts
    ) internal {
        require(payouts.length > 0, "TransferExecutor: nothing to transfer");
        uint sumBps = 0;
        uint rest = amount;
        for (uint256 i = 0; i < payouts.length - 1; ++i) {
            uint currentAmount = amount.bp(payouts[i].value);
            sumBps = sumBps.add(payouts[i].value);
            if (currentAmount > 0) {
                rest = rest.sub(currentAmount);
                transfer(LibraryAsset.Asset(assetType, currentAmount), from, payouts[i].account);
            }
        }
        LibraryPart.Part memory lastPayout = payouts[payouts.length - 1];
        sumBps = sumBps.add(lastPayout.value);
        require(sumBps == 10000, "TransferExecutor: Sum payouts Bps not equal 100%");
        if (rest > 0) {
            transfer(LibraryAsset.Asset(assetType, rest), from, lastPayout.account);
        }
    }

    uint256[49] private __gap;
}
