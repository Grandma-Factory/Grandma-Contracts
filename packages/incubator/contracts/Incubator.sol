// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@grandma/tokens/contracts/factories/IERC20VaultFactory.sol";
import "@grandma/access-upgradeable/contracts/OperatorRoleUpgradeable.sol";
import "@grandma/transfers/contracts/TransferExecutor.sol";
import "./interfaces/IIncubator.sol";
import "./interfaces/ICrowdfundingEscrowFactory.sol";
import "./libraries/LibrarySale.sol";

/// @title Incubator
/// @dev Incubator is the incubator contract of the Grandma-Factory plateform.
/// @custom:security-contact security@grandma.digital
contract Incubator is
    IIncubator,
    Initializable,
    OperatorRoleUpgradeable,
    ReentrancyGuardUpgradeable,
    TransferExecutor,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint;
    using LibrarySale for LibrarySale.Sale;

    uint256 private constant UINT256_MAX = type(uint256).max;
    uint8 private constant DEFAULT_VAULT_SUPPLY = 100;

    IERC20VaultFactory public vaultFactory;
    ICrowdfundingEscrowFactory public escrowFactory;
    mapping(bytes32 => ICrowdfundingEscrow) public escrows;

    event Created(bytes32 hash);
    event Canceled(bytes32 hash);
    event Bought(bytes32 hash);
    event Crowdfunded(bytes32 hash);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(ICrowdfundingEscrowFactory escrowFactory_, IERC20VaultFactory vaultFactory_) public initializer {
        __OperatorRole_init(msg.sender);
        __UUPSUpgradeable_init();

        escrowFactory = escrowFactory_;
        vaultFactory = vaultFactory_;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyUpgrader {}

    /**
     * Accept Ethers
     */
    receive() external payable {
        // nothin to do here
    }

    /**
     * @dev Update escrow factory
     * Only operators can call this function.
     * @param escrowFactory_ The new factory.
     */
    function setEscrowFactory(ICrowdfundingEscrowFactory escrowFactory_) external onlyOperator {
        escrowFactory = escrowFactory_;
    }

    /**
     * @dev Update vault factory
     * Only operators can call this function.
     * @param vaultFactory_ The new factory.
     */
    function setVaultFactory(IERC20VaultFactory vaultFactory_) external onlyOperator {
        vaultFactory = vaultFactory_;
    }


    /**
     * @dev Create an asset sale.
     * Only operators can call this function.
     * Validates the sale and creates a dedicated escrow for the sale.
     * @param sale The details of the sale to be created.
     */

    function postSale(LibrarySale.Sale memory sale) external onlyOperator {
        _validateSale(sale);
        bytes32 saleHash = sale.hash();

        // verify that a sale is not currently openned
        require(address(escrows[saleHash]) == address(0), "Incubator: sale already exist");

        // create an dedicated escrow for the sale
        escrows[saleHash] = escrowFactory.createEscrow(sale.maker);
        emit Created(saleHash);
    }

    /**
     * @dev Get the address of the crowdfunding escrow associated with a sale.
     * @param sale The details of the sale.
     * @return The address of the crowdfunding escrow contract associated with the sale.
     */
    function getSaleCrowdfundingEscrow(LibrarySale.Sale memory sale) external view returns (address) {
        bytes32 saleHash = sale.hash();
        return address(_getSaleEscrow(saleHash));
    }

    /**
     * @dev Cancel an asset sale.
     * @param sale The details of the sale to be canceled.
     * Only operators can call this function.
     * Cancels the sale by enabling refund on the escrow contract.
     */

    function cancelSale(LibrarySale.Sale memory sale) external onlyOperator {
        bytes32 saleHash = sale.hash();
        ICrowdfundingEscrow escrow = _getSaleEscrow(saleHash);

        // enable refund on the escrow contract
        escrow.cancel();
        emit Canceled(saleHash);
    }

    /**
     * @dev Purchase the entire asset directly, bypassing the crowdfunding process.
     * @param sale The details of the sale to be purchased.
     * Requires a payment that exceeds the remaining funding amount.
     */
    function directBuy(LibrarySale.Sale memory sale) external payable nonReentrant {
        // first validate the sale
        _validateSale(sale);

        // check if the sale it currently active
        bytes32 saleHash = sale.hash();
        ICrowdfundingEscrow escrow = _getSaleEscrow(saleHash);
        require(escrow.state() == ICrowdfundingEscrow.State.Active, "Incubator: sale is not active");

        // check if the payment is enough
        uint256 amountWithFees = sale.calculRemainingFunding(0);
        require(amountWithFees < msg.value, "Incubator: insufficient payment");

        // process the payment
        (bool successPayment, ) = sale.maker.call{value: amountWithFees}("");
        require(successPayment, "Incubator: payment transaction failed");

        // process assetTransfert
        transfer(sale.asset, sale.maker, msg.sender);

        // cancel the escrow
        escrow.cancel();

        // refund any ether rest
        uint256 rest = address(this).balance;
        if (rest > 0) {
            (bool successRest, ) = msg.sender.call{value: rest}("");
            require(successRest, "Incubator: refund rest transaction failed");
        }
        emit Bought(saleHash);
    }

    /**
     * @dev Finalize the crowdfunding process for an asset sale.
     * @param sale The details of the sale to be finalized.
     * Only operators can call this function.
     * Validates the crowdfunding status and executes the crowdfunding process.
     */

    function finalizeCrowdfunding(LibrarySale.Sale memory sale) external onlyOperator {
        _validateCrowdfunding(sale);
        _executeCrowdfunding(sale);
    }

    function _getSaleEscrow(bytes32 saleHash) internal view returns (ICrowdfundingEscrow) {
        ICrowdfundingEscrow escrow = escrows[saleHash];
        require(address(escrow) == address(0), "Incubator: sale not found");
        return escrow;
    }

    /// validate a sale
    function _validateSale(LibrarySale.Sale memory sale) internal view {
        sale.validateSaleTime();
    }

    function _validateCrowdfunding(LibrarySale.Sale memory sale) internal view {
        bytes32 saleHash = sale.hash();
        ICrowdfundingEscrow escrow = _getSaleEscrow(saleHash);
        require(escrow.state() == ICrowdfundingEscrow.State.Active, "Incubator: sale is not active");

        uint256 remainingFundingWithFees = sale.calculRemainingFunding(address(escrow).balance);
        require(remainingFundingWithFees == 0, "Incubator: sale not filled");
    }

    function _executeCrowdfunding(LibrarySale.Sale memory sale) internal {
        // Close the sale
        bytes32 saleHash = sale.hash();
        ICrowdfundingEscrow escrow = _getSaleEscrow(saleHash);
        escrow.close();

        // calculate initial shares distribution
        (address[] memory depositors, uint256[] memory amounts) = escrow.getDepositors();
        uint256 totalDeposits = escrow.getTotalDeposits();
        for (uint256 i = 0; i < depositors.length; i++) {
            amounts[i] = amounts[i].mul(DEFAULT_VAULT_SUPPLY).div(totalDeposits);
        }

        // Create the vault
        IERC20 vault = vaultFactory.createERC20Vault(sale.vaultName, sale.vaultSymbole, depositors, amounts);

        // Transfer the asset to the new ERC20Vault contract
        transfer(sale.asset, sale.maker, address(vault));

        emit Crowdfunded(saleHash);
    }
}
