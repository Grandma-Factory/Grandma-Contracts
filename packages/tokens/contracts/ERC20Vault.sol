// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Grandma-Vault
/// @dev Grandma-Valut, Grandma contract used to fractionnalize Grandma assets
/// @custom:security-contact security@grandma.digital
contract ERC20Vault is ERC20, ERC20Permit, ERC20Burnable, Pausable, Ownable, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event ERC20TokenTransferred(IERC20 token, address to, uint256 amount);
    event ERC721TokenTransferred(IERC721 token, address to, uint256 amount);
    event ERC1155TokenTransferred(IERC1155 token, address to, uint256[] ids, uint256[] amounts);
    event Claimed(address owner);

    constructor(string memory name_, string memory symbol_, address[] memory tokenHolders_, uint256[] memory tokenAmounts) 
            ERC20(name_, symbol_) ERC20Permit(name_) {
        require(tokenHolders_.length == tokenAmounts.length);

        for (uint256 i = 0; i < tokenHolders_.length; i++)
            _mint(tokenHolders_[i], tokenAmounts[i] * 10 ** decimals());
        
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function withdrawERC20(address tokenAddress, address to, uint256 amount) public whenNotPaused onlyOwner {
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit ERC20TokenTransferred(IERC20(tokenAddress), to, amount);
    }

    function withdrawERC721(address tokenAddress, address to, uint256 tokenId) public whenNotPaused onlyOwner {
        IERC721(tokenAddress).transferFrom(address(this), to, tokenId);
        emit ERC721TokenTransferred(IERC721(tokenAddress), to, tokenId);
    }

    function withdrawERC1155Batch(
        address tokenAddress,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public whenNotPaused onlyOwner {
        IERC1155(tokenAddress).safeBatchTransferFrom(address(this), to, ids, amounts, "");
        emit ERC1155TokenTransferred(IERC1155(tokenAddress), to, ids, amounts);
    }

    function claimAssets() public whenNotPaused {
        require(balanceOf(msg.sender) == totalSupply(), "ERC20Vault: you don't own the entire supply");

        _burn(msg.sender, totalSupply());
        _transferOwnership(msg.sender);

        emit Claimed(msg.sender);
    }
   
}
