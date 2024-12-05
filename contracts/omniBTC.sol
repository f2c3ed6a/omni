// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract omniBTC is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * ======================================================================================
     *
     * CONSTRUCTOR
     *
     * ======================================================================================
     */

    /**
     * @notice Disables the ability to call any additional initializer functions.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * ======================================================================================
     *
     * VIEW FUNCTIONS
     *
     * ======================================================================================
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * ======================================================================================
     *
     * ADMIN
     *
     * ======================================================================================
     */

    /**
     * @notice Initializes the contract with admin and token settings.
     * @param _defaultAdmin The default admin address (RBAC).
     * @param _minter The address of the omniBTC minter.
     */
    function initialize(address _defaultAdmin, address _minter) public initializer {
        __ERC20_init("omniBTC", "omniBTC");
        __ERC20Burnable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(MINTER_ROLE, _minter);
    }

    /**
     * ======================================================================================
     *
     * MINTER
     *
     * ======================================================================================
     */

    /**
     * @notice Mints omniBTC to the specified address.
     * @param to The omniBTC will be minted to this address.
     * @param amount The amount of omniBTC to mint.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @notice Burns omniBTC.
     * @param amount The amount of omniBTC to burn.
     */
    function burn(uint256 amount) public override onlyRole(MINTER_ROLE) {
        _burn(_msgSender(), amount);
    }

    /**
     * @notice Burns omniBTC from the specified address.
     * @param account The address of the account to burn from.
     * @param amount The amount of omniBTC to burn.
     */
    function burnFrom(address account, uint256 amount) public override onlyRole(MINTER_ROLE) {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * ======================================================================================
     *
     * USER INTERACTION
     *
     * ======================================================================================
     */
    /**
     * @notice Batch transfer amount to recipients.
     * @param recipients The addresses of the recipients.
     * @param amounts The amounts to transfer to the recipients.
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length > 0, "USR001");
        require(recipients.length == amounts.length, "USR002");

        for (uint256 i = 0; i < recipients.length; ++i) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
    }

    /**
     * ======================================================================================
     *
     * OVERRIDE
     *
     * ======================================================================================
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        super._transfer(sender, recipient, amount);
    }
}
