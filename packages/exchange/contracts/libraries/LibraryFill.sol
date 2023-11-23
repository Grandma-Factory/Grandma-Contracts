// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibraryOrder.sol";

library LibraryFill {
    using SafeMathUpgradeable for uint;

    struct FillResult {
        uint leftValue;
        uint rightValue;
    }

    /**
     * @dev Should return filled values
     * @param leftOrder left order
     * @param rightOrder right order
     * @param leftOrderFill current fill of the left order (0 if order is unfilled)
     * @param rightOrderFill current fill of the right order (0 if order is unfilled)
     */
    function fillOrder(
        LibraryOrder.Order memory leftOrder,
        LibraryOrder.Order memory rightOrder,
        uint leftOrderFill,
        uint rightOrderFill
    ) internal pure returns (FillResult memory) {
        (uint leftMakeValue, uint leftTakeValue) = calculateRemaining(leftOrder, leftOrderFill);
        (uint rightMakeValue, uint rightTakeValue) = calculateRemaining(rightOrder, rightOrderFill);

        //We have 3 cases here:
        if (rightTakeValue > leftMakeValue) {
            //1nd: left order should be fully filled
            return fillLeft(leftMakeValue, leftTakeValue, rightOrder.makeAsset.value, rightOrder.takeAsset.value);
        } //2st: right order should be fully filled or 3d: both should be fully filled if required values are the same
        return fillRight(leftOrder.makeAsset.value, leftOrder.takeAsset.value, rightMakeValue, rightTakeValue);
    }

    function fillRight(
        uint leftMakeValue,
        uint leftTakeValue,
        uint rightMakeValue,
        uint rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint makerValue = LibraryMath.safeGetPartialAmountFloor(rightTakeValue, leftMakeValue, leftTakeValue);
        require(makerValue <= rightMakeValue, "fillRight: unable to fill");
        return FillResult(rightTakeValue, makerValue);
    }

    function fillLeft(
        uint leftMakeValue,
        uint leftTakeValue,
        uint rightMakeValue,
        uint rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint rightTake = LibraryMath.safeGetPartialAmountFloor(leftTakeValue, rightMakeValue, rightTakeValue);
        require(rightTake <= leftMakeValue, "fillLeft: unable to fill");
        return FillResult(leftMakeValue, leftTakeValue);
    }

    function calculateRemaining(
        LibraryOrder.Order memory order,
        uint fill
    ) internal pure returns (uint makeValue, uint takeValue) {
        makeValue = order.makeAsset.value.sub(fill);
        takeValue = LibraryMath.safeGetPartialAmountFloor(order.takeAsset.value, order.makeAsset.value, makeValue);
    }
}
