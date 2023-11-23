// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interfaces/IRoyaltiesProvider.sol";

contract RoyaltiesProvider is IRoyaltiesProvider {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint96 private constant _100_FEES_BASE_POINT = 10000;

    function getRoyalties(address token, uint256 tokenId) external view returns (LibraryPart.Part[] memory royalties) {
        if (_checkRoyalties(token)) {
            royalties = new LibraryPart.Part[](1);
            (address receiver, uint256 royaltyAmount) = IERC2981(token).royaltyInfo(tokenId, _100_FEES_BASE_POINT);
            royalties[0] = LibraryPart.Part({account: payable(receiver), value: uint96(royaltyAmount)});
        } 

    }

    function _checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }
}
