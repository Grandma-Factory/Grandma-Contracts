// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@grandma/tokens/contracts/ERC721Grandma.sol";
import "@grandma/access-upgradeable/contracts/OperatorRoleUpgradeable.sol";
import "@grandma/transfers/contracts/TransferExecutor.sol";
import "@grandma/royalties/contracts/interfaces/IRoyaltiesProvider.sol";
import "./interfaces/IExchange.sol";
import "./libraries/LibraryFill.sol";
import "./libraries/LibraryFeeSide.sol";

/// @title Exchange
/// @dev Exchange is the marketplace contract of the Grandma-Factory plateform.
/// @custom:security-contact security@grandma.digital
contract Exchange is IExchange, Initializable, OperatorRoleUpgradeable, TransferExecutor, UUPSUpgradeable {
    using SafeMathUpgradeable for uint;
    using LibraryTransfer for address;

    uint256 private constant UINT256_MAX = type(uint256).max;
    uint96 private constant _100_FEES_BASE_POINT = 10000;

    mapping(bytes32 => uint) public fills;

    IRoyaltiesProvider public royaltiesProvider;

    event Canceled(bytes32 hash);
    event Executed(bytes32 leftHash, bytes32 rightHash, uint newLeftFill, uint newRightFill);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IRoyaltiesProvider royaltiesProvider_) public initializer {
        __OperatorRole_init(msg.sender);
        __UUPSUpgradeable_init();

        royaltiesProvider = royaltiesProvider_;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyUpgrader {}

    /// Update royalties provider
    function setRoyaltiesProvider(IRoyaltiesProvider royaltiesProvider_) external onlyOperator {
        royaltiesProvider = royaltiesProvider_;
    }

    /// accept ETH
    receive() external payable {
        // nothin to do here
    }

    /// pass an order regarding the specified bid
    function executeOrders(
        LibraryOrder.Order memory taker,
        bytes memory signatureTaker,
        LibraryOrder.Order memory maker,
        bytes memory signatureMaker
    ) external {
        _validateOrders(taker, signatureTaker, maker, signatureMaker);
        _matchOrders(taker, maker);
        _executeOrders(taker, maker);
        _cleanExecutedOrder();
    }

    /// cancel an order
    function cancelOrder(LibraryOrder.Order memory order) external {
        require(_msgSender() == order.maker, "Marketplace: you are not the maker");
        bytes32 orderKeyHash = LibraryOrder.hashKey(order);
        fills[orderKeyHash] = UINT256_MAX;
        emit Canceled(orderKeyHash);
    }

    /// validate both orders
    function _validateOrders(
        LibraryOrder.Order memory orderLeft,
        bytes memory signatureA,
        LibraryOrder.Order memory orderRight,
        bytes memory signatureB
    ) internal view {
        _validateOrder(orderLeft, signatureA);
        _validateOrder(orderRight, signatureB);
    }

    /// validate an order
    function _validateOrder(LibraryOrder.Order memory order, bytes memory signature) internal view {
        LibraryOrder.validateOrderTime(order);

        // validate signature only if sender is not the actual caller
        if (order.maker != _msgSender()) {
            LibraryOrder.validateSignature(order, signature);
        }
    }

    function _matchOrders(LibraryOrder.Order memory orderLeft, LibraryOrder.Order memory orderRight) internal pure {
        require(
            LibraryAsset.equalsAssetTypes(orderLeft.makeAsset.assetType, orderRight.takeAsset.assetType),
            "Exchange: left asset make and right asset take doesn't match"
        );
        require(
            LibraryAsset.equalsAssetTypes(orderLeft.takeAsset.assetType, orderRight.makeAsset.assetType),
            "Exchange: left asset take and right asset make doesn't match"
        );
    }

    function _executeOrders(LibraryOrder.Order memory orderLeft, LibraryOrder.Order memory orderRight) internal {
        bytes32 orderLeftKey = LibraryOrder.hashKey(orderLeft);
        bytes32 orderRightKey = LibraryOrder.hashKey(orderRight);
        uint orderLeftFill = _getOrderFill(orderLeftKey);
        uint orderRightFill = _getOrderFill(orderRightKey);

        LibraryFill.FillResult memory fillResult = LibraryFill.fillOrder(orderLeft, orderRight, orderLeftFill, orderRightFill);
        require(fillResult.rightValue > 0 && fillResult.leftValue > 0, "Exchange: nothing to fill");

        fills[orderLeftKey] = orderLeftFill.add(fillResult.leftValue);
        fills[orderRightKey] = orderRightFill.add(fillResult.rightValue);

        _transferAssets(orderLeft, orderRight, fillResult);

        emit Executed(orderLeftKey, orderRightKey, fillResult.rightValue, fillResult.leftValue);
    }

    function _transferAssets(
        LibraryOrder.Order memory orderLeft,
        LibraryOrder.Order memory orderRight,
        LibraryFill.FillResult memory fillResult
    ) internal {
        LibraryTransferData.TransferData memory leftTransfer;
        LibraryTransferData.TransferData memory rightTransfer;

        LibraryFeeSide.FeeSide feeSide = LibraryFeeSide.getFeeSide(
            orderLeft.makeAsset.assetType.assetClass,
            orderLeft.takeAsset.assetType.assetClass
        );

        if (feeSide == LibraryFeeSide.FeeSide.NONE) {
            leftTransfer = _buildTransfer(orderLeft, orderRight, fillResult.leftValue);
            rightTransfer = _buildTransfer(orderRight, orderLeft, fillResult.rightValue);
        } else if (feeSide == LibraryFeeSide.FeeSide.LEFT) {
            leftTransfer = _buildTransferWithFees(orderLeft, orderRight, fillResult.leftValue);
            rightTransfer = _buildTransfer(orderRight, orderLeft, fillResult.rightValue);
        } else if (feeSide == LibraryFeeSide.FeeSide.RIGHT) {
            leftTransfer = _buildTransfer(orderLeft, orderRight, fillResult.leftValue);
            rightTransfer = _buildTransferWithFees(orderRight, orderLeft, fillResult.rightValue);
        }

        transfer(leftTransfer);
        transfer(rightTransfer);
    }

    function _buildTransfer(
        LibraryOrder.Order memory orderPayer,
        LibraryOrder.Order memory orderPayee,
        uint256 value
    ) internal pure returns (LibraryTransferData.TransferData memory) {
        LibraryPart.Part[] memory payouts = new LibraryPart.Part[](1);
        payouts[0] = LibraryPart.Part(payable(orderPayee.maker), _100_FEES_BASE_POINT);

        return
            LibraryTransferData.TransferData({
                asset: LibraryAsset.Asset({assetType: orderPayer.makeAsset.assetType, value: value}),
                payouts: payouts,
                from: orderPayer.maker
            });
    }

    function _buildTransferWithFees(
        LibraryOrder.Order memory orderPayer,
        LibraryOrder.Order memory orderPayee,
        uint256 value
    ) internal returns (LibraryTransferData.TransferData memory) {

        return
            LibraryTransferData.TransferData({
                asset: LibraryAsset.Asset({assetType: orderPayer.makeAsset.assetType, value: value}),
                payouts: _buildPayoutsWithRoyalties(orderPayee),
                from: orderPayer.maker
            });
    }

    function _buildPayoutsWithRoyalties(
        LibraryOrder.Order memory orderPayee
    ) internal returns (LibraryPart.Part[] memory) {
        LibraryAsset.Asset memory asset = orderPayee.makeAsset;
        bytes4 assetClass = asset.assetType.assetClass;

        LibraryPart.Part[] memory royalties;

        if (assetClass == LibraryAsset.ERC721_ASSET_CLASS) {
            LibraryAsset.AssetTypeDataERC721 memory assetData = LibraryAsset.getAssetTypeDataERC721(asset.assetType);
            royalties = royaltiesProvider.getRoyalties(assetData.contractAddress, assetData.tokenId);
        } else if (assetClass == LibraryAsset.ERC1155_ASSET_CLASS) {
            LibraryAsset.AssetTypeDataERC1155 memory assetData = LibraryAsset.getAssetTypeDataERC1155(asset.assetType);
            royalties = royaltiesProvider.getRoyalties(assetData.contractAddress, assetData.tokenId);
        }

        LibraryPart.Part[] memory payouts = new LibraryPart.Part[](royalties.length + 1);
        uint96 royaltiesSumBP = 0;
        for (uint i = 0; i < royalties.length; i++) {
            payouts[i] = royalties[i];
            royaltiesSumBP += royalties[i].value;
        }

        payouts[royalties.length] = LibraryPart.Part(payable(orderPayee.maker), _100_FEES_BASE_POINT - royaltiesSumBP);
        return payouts;
    }

    function _cleanExecutedOrder() internal {
        // ensure to refund the rest of ETH to sender
        _msgSender().transferEth(address(this).balance);
    }

    function _getOrderFill(bytes32 orderHashKey) internal view returns (uint) {
        return fills[orderHashKey];
    }
}
