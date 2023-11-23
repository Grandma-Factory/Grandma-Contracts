// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@grandma/library-pair/contracts/LibraryPair.sol";

//
// ! Only for testing purpose
//

contract SwapRouterMock is ISwapRouter {
    using SafeMath for uint;
    mapping(bytes32 => uint96) private rates;

    constructor(IERC20[] memory from_, IERC20[] memory to_, uint96[] memory rates_) {
        require(from_.length == to_.length);
        require(from_.length == rates_.length);
        for (uint i = 0; i < from_.length; i++) {
            LibraryPair.AddressPair memory pair = LibraryPair.AddressPair(address(from_[i]), address(to_[i]));
            bytes32 hashPair = LibraryPair.hash(pair);
            rates[hashPair] = rates_[i];
        }
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        LibraryPair.AddressPair memory pair = LibraryPair.AddressPair(params.tokenIn, params.tokenOut);
        bytes32 hashPair = LibraryPair.hash(pair);
        require(rates[hashPair] != 0, "SwapRouterMock: pair not mocked.");

        amountOut = params.amountIn.mul(rates[hashPair]);
        require(IERC20(params.tokenOut).balanceOf(address(this)) >= amountOut, "SwapRouterMock: not enough tokenOut on mock");

        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        IERC20(params.tokenOut).transfer(msg.sender, amountOut);

        return amountOut;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut) {
        require(false, "Not implemented");
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn) {
        require(false, "Not implemented");
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn) {
        require(false, "Not implemented");
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        require(false, "Not implemented");
    }
}
