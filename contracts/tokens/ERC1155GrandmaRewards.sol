// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/////////////////////////////////////////
/// ! WIP. DO NOT USE IN PRODUCTION ! ///
/////////////////////////////////////////

/// Structure used to store the reward pool data.
struct RewardData { 
    // the reward pool name
    string name; 
    // Is the reward pool currently open to new stackers
    bool isOpened; 
    // The minimum ok Grandma-Tokens to stack
    uint256 minCap; 
    // The boost multiplier (multiplied by * 100) applied to the pool 
    uint256 boost; 
    // The current supply in Grandma-Tokens
    uint256 supply; 
}

/// @title ERC1155GrandmaRewards
/// @dev ERC1155GrandmaRewards is muliple pool contract used to collect and redistribute Grandma-Factory platform fees.
/// @custom:security-contact security@grandma.digital
contract ERC1155GrandmaRewards is ERC1155, ERC1155Burnable, ERC1155Supply, IERC777Recipient {
    using SafeMath for uint256;

    // interface of the GrandmaToken
    IERC777 public grandmaToken;
    IERC1820Registry public registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    // keccak256('ERC1155GrandmaRewards')
    bytes32 private constant CONTRACT_HASH = 0x8152f45e1ca9fa4b6e1bf29cdf1f71176c37c5fd50a0a0b5ab7a2f6c6c2e3149;

    // track allowed tokens ids
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // reward tokens datas
    mapping(uint256 => RewardData) private _tokenRewardDatas;

    event Distributed(address indexed _from, uint256 indexed _tokenId, uint _amount);

    // constructor
    constructor(IERC777 grandmaToken_) ERC1155("") {
        // define the GrandmaToken
        grandmaToken = grandmaToken_;

        // Register the current contract to the IERC1820 registry 
        registry.setInterfaceImplementer(address(this), CONTRACT_HASH, address(this));
    }

    // Enter the reward program. Pay some GrandmaToken. Earn some shares.
    // Locks GrandmaToken and mints reward tokens.
    function enter(uint256 tokenId_, uint256 amount_) public {
        require(_tokenRewardDatas[tokenId_].isOpened , "ERC1155GrandmaRewards: Token id not allowed");
        require(balanceOf(msg.sender, tokenId_) > 0 || amount_ >= _tokenRewardDatas[tokenId_].minCap, "ERC1155GrandmaRewards: Minimum cap not reached");

        // Gets the amount of GrandmaToken locked in the contract for the specified tokenId
        uint256 totalGma = _tokenRewardDatas[tokenId_].supply;
        // Gets the amount of reward token in existence
        uint256 totalShares = totalSupply(tokenId_);

        // If no reward token exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalGma == 0) {
            _mint(msg.sender, tokenId_, amount_, "");
        }
        // Calculate and mint the amount of reward tokens the GrandmaToken is worth. The ratio will change overtime, as the reward token is burned/minted and GrandmaToken deposited + gained from fees / withdrawn.
        else {
            uint256 what = amount_.mul(totalShares).div(totalGma);
            _mint(msg.sender, tokenId_, what, "");
        }

        // Lock the GrandmaToken in the contract
        grandmaToken.operatorSend(msg.sender, address(this), amount_, "enter", abi.encodePacked(CONTRACT_HASH));
    }

    // Leave the reward program. Claim back your GrandmaToken.
    // Unlocks the staked + gained GrandmaToken and burns reward tokens
    function leave(uint256 tokenId_, uint256 _share) public {
        require(balanceOf(msg.sender, tokenId_) >= share, "ERC1155GrandmaRewards: Not enough token shares")
        // Gets the amount of reward token in existence
        uint256 totalShares = totalSupply(tokenId_);
        uint256 gmaBalance = _tokenRewardDatas[tokenId_].supply;

        // Calculates the amount of GrandmaToken the reward token is worth
        uint256 what = _share.mul(gmaBalance).div(totalShares);
        _burn(msg.sender, tokenId_, _share);

        // Lock the GrandmaToken in the contract
        grandmaToken.send(msg.sender, what, "leave");
    }

    // Callback received when a token is received
    // Used this callback to redistribute the supply to each reward pool.
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(msg.sender == address(grandmaToken), "ERC1155GrandmaRewards: Unexpected token received");

        // Ignore if operator data is the current CONTRACT_HASH
        if (keccak256(operatorData) == CONTRACT_HASH) {
            return;
        }

        // compute new reward supplies 
        uint256 tokenId = 0;
        uint256 sumSkBk = 0;
        for (tokenId=0; tokenId < _tokenIds.current(); tokenId++) {
            sumSkBk = sumSkBk.add(_tokenRewardDatas[tokenId].supply.mul(_tokenRewardDatas[tokenId].boost));
        }
        require(sumSkBk > 0, "ERC1155GrandmaRewards: Sum of supply times boost must be greater than zero");

        for (tokenId=0; tokenId < _tokenIds.current(); tokenId++) {
            uint256 siBi = _tokenRewardDatas[tokenId].supply.mul(_tokenRewardDatas[tokenId].boost);
            uint256 rewardFactor = siBi.div(sumSkBk);
            uint256 poolReward = amount.mul(rewardFactor);
            _tokenRewardDatas[tokenId].supply = _tokenRewardDatas[tokenId].supply.add(poolReward);
            
            emit Distributed(msg.sender, tokenId, poolReward);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
