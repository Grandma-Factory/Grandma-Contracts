// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
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
    // The boost multiplier (multiplied by 100) applied to the pool 
    uint256 boost; 
    // The current supply in Grandma-Tokens
    uint256 supply; 
}

/// @title ERC1155GrandmaReward
/// @dev ERC1155GrandmaReward is muliple pool contract used to collect and redistribute Grandma-Factory platform fees.
/// @custom:security-contact security@grandma.digital
contract ERC1155GrandmaReward is ERC1155, AccessControl, Pausable, ERC1155Burnable, ERC1155Supply, IERC777Recipient {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    using SafeMath for uint256;

    // interface of the GrandmaToken
    IERC777 public grandmaToken;
    IERC1820Registry public registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 private constant _CONTRACT_HASH = keccak256('ERC1155GrandmaRewards');
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // track allowed tokens ids
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCounter;

    // amount of token to distribute
    uint256 private _pending_distribution;

    // reward tokens datas
    mapping(uint256 => RewardData) private _tokenRewardDatas;

    event Distributed(uint256 indexed _tokenId, uint _amount);

    // Constructor
    constructor(IERC777 grandmaToken_) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        // define the GrandmaToken
        grandmaToken = grandmaToken_;

        // Register the current contract to the IERC1820 registry 
        registry.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
        
    // Create a new pool with the specified name, minimum cap and boost.
    function createPool(string calldata name_, bool isOpened_, uint256 minCap_, uint256 boost_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenId = _tokenCounter.current();
        _tokenCounter.increment();
        _tokenRewardDatas[tokenId] = RewardData(name_, isOpened_, minCap_, boost_, 0);
    }

    // Update the reward pool corresponding the specified tokenId. 
    // Configure the pool with the following name, minimum cap and the boost multiplier.
    function updatePool(uint256 tokenId_, string calldata name_, bool isOpened_, uint256 minCap_, uint256 boost_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenId_ < _tokenCounter.current() , "ERC1155GrandmaRewards: Unexpected token id");

        RewardData storage rd = _tokenRewardDatas[tokenId_];
        rd.name = name_;
        rd.isOpened = isOpened_;
        rd.minCap = minCap_;
        rd.boost = boost_;
    }
      
    // Get pool reward data
    function getPoolData(uint256 tokenId_) public view returns (string memory, bool, uint256, uint256, uint256) {
        require(tokenId_ < _tokenCounter.current() , "ERC1155GrandmaRewards: Unexpected token id");

        RewardData memory rd = _tokenRewardDatas[tokenId_];
        return (rd.name, rd.isOpened, rd.minCap, rd.boost, rd.supply);
    }

    // Get the number of existing pools
    function getPoolCount() public view returns (uint256) {
        return _tokenCounter.current();
    }

    // Enter the reward program. Pay some GrandmaToken. Earn some shares.
    // Locks GrandmaToken and mints reward tokens.
    function enter(uint256 tokenId_, uint256 amount_) public {
        require(tokenId_ < _tokenCounter.current() , "ERC1155GrandmaRewards: Unexpected token id");
        require(_tokenRewardDatas[tokenId_].isOpened , "ERC1155GrandmaRewards: Token id not opened");
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
        grandmaToken.operatorSend(msg.sender, address(this), amount_, "", abi.encodePacked(_CONTRACT_HASH));//abi.encodePacked(_CONTRACT_HASH));
        // Add locked tokens to the supply
        _tokenRewardDatas[tokenId_].supply = _tokenRewardDatas[tokenId_].supply.add(amount_);
    }

    // Leave the reward program. Claim back your GrandmaToken.
    // Unlocks the staked + gained GrandmaToken and burns reward tokens
    function leave(uint256 tokenId_, uint256 share_) public {
        require(tokenId_ < _tokenCounter.current() , "ERC1155GrandmaRewards: Unexpected token id");
        require(balanceOf(msg.sender, tokenId_) >= share_, "ERC1155GrandmaRewards: Not enough token shares");

        // Gets the amount of reward token in existence
        uint256 totalShares = totalSupply(tokenId_);
        uint256 gmaBalance = _tokenRewardDatas[tokenId_].supply;

        // Calculates the amount of GrandmaToken the reward token is worth
        uint256 what = share_.mul(gmaBalance).div(totalShares);
        _burn(msg.sender, tokenId_, share_);

        // Withdraw the GrandmaToken from the contract
        grandmaToken.send(msg.sender, what, "");
        _tokenRewardDatas[tokenId_].supply = gmaBalance.sub(what);
    }

     // Process to token distribution
    function distribute() public {
        uint256 amount = _pending_distribution;
        _pending_distribution = 0;

        // compute new reward supplies 
        // ignore closed pools
        uint256 tokenId = 0;
        uint256 sumSkBk = 0;
        for (tokenId=0; tokenId < _tokenCounter.current(); tokenId++) {
            if (_tokenRewardDatas[tokenId].isOpened) {
                uint256 skBk = _tokenRewardDatas[tokenId].supply.mul(_tokenRewardDatas[tokenId].boost);
                sumSkBk = sumSkBk.add(skBk);
            }
        }
        require(sumSkBk > 0, "ERC1155GrandmaRewards: Sum of supply times boost must be greater than zero");

        for (tokenId=0; tokenId < _tokenCounter.current(); tokenId++) {
            if (_tokenRewardDatas[tokenId].isOpened) {
                uint256 siBi = _tokenRewardDatas[tokenId].supply.mul(_tokenRewardDatas[tokenId].boost);
                uint256 poolReward = amount.mul(siBi).div(sumSkBk);
                _tokenRewardDatas[tokenId].supply = _tokenRewardDatas[tokenId].supply.add(poolReward);
                emit Distributed(tokenId, poolReward);
            }
        }
    }

    // Get the amount of token pending for distribution
    function getPendingDistribution() public view returns (uint256) {
        return _pending_distribution;
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
        if (keccak256(operatorData) == keccak256(abi.encodePacked(_CONTRACT_HASH))) {
            return;
        }

        _pending_distribution = _pending_distribution.add(amount);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
