// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IMintableContract.sol";

contract omniVault is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice The address of the native BTC token.
     */
    address private constant NATIVE_BTC = address(0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF);

    /**
     * @notice The base exchange rate for tokens with 18 decimals.
     */
    uint256 public constant EXCHANGE_RATE_BASE = 1e10;

    /**
     * @notice The address of the ERC20 omniBTC token.
     */
    address public omniBTC;

    /**
     * @notice Mapping to store the used cap for each type of wrapped BTC.
     */
    mapping(address => uint256) public tokenUsedCaps;

    /**
     * @notice Mapping to store the cap for each type of wrapped BTC.
     */
    mapping(address => uint256) public tokenCaps;

    /**
     * @notice Mapping to store the paused status for each type of wrapped BTC.
     */
    mapping(address => bool) public pausedTokens;

    /**
     * @notice Mapping to store the allowed status for each type of wrapped BTC.
     */
    mapping(address => bool) public allowedTokens;

    /**
     * @notice Mapping to store the allowed status for each target address.
     */
    mapping(address => bool) public allowedTargets;

    /**
     * @notice The out of service status.
     */
    bool public outOfService;

    /**
     * @notice Allow users to send native tokens to this contract.
     */
    receive() external payable {}

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
     * MODIFIERS
     *
     * ======================================================================================
     */

    /**
     * @notice Modifier to check if the service is normal.
     */
    modifier serviceNormal() {
        require(!outOfService, "SYS011");
        _;
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
     * @param _omniBTC The address of the omniBTC token.
     */
    function initialize(address _defaultAdmin, address _omniBTC) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        require(_omniBTC != address(0x0), "SYS001");

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(PAUSER_ROLE, _defaultAdmin);

        omniBTC = _omniBTC;
    }

    /**
     * @notice Allow token to mint omniBTC.
     * @param _tokens The address of the token.
     */
    function allowToken(address[] memory _tokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens[_tokens[i]] = true;
        }
        emit TokenAllowed(_tokens);
    }

    /**
     * @notice Deny token to mint omniBTC.
     * @param _tokens The address of the token.
     */
    function denyToken(address[] memory _tokens) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens[_tokens[i]] = false;
        }
        emit TokenDenied(_tokens);
    }

    /**
     * @notice Allow target which can be called by this contract.
     * @param _targets The address of the target.
     */
    function allowTarget(address[] memory _targets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _targets.length; i++) {
            allowedTargets[_targets[i]] = true;
        }
        emit TargetAllowed(_targets);
    }

    /**
     * @notice Deny target which can be called by this contract.
     * @param _targets The address of the target.
     */
    function denyTarget(address[] memory _targets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _targets.length; i++) {
            allowedTargets[_targets[i]] = false;
        }
        emit TargetDenied(_targets);
    }

    /**
     * @notice Set the cap for each type of wrapped BTC.
     * @param _token The address of the token.
     * @param _cap The cap for the token.
     */
    function setCap(address _token, uint256 _cap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != NATIVE_BTC, "SYS012");
        require(_token != address(0x0), "SYS003");
        require(_cap > 0, "USR017");

        uint8 decs = ERC20(_token).decimals();

        require(decs == 8 || decs == 18, "SYS004");

        tokenCaps[_token] = _cap;
    }

    /**
     * ======================================================================================
     *
     * PAUSER
     *
     * ======================================================================================
     */

    /**
     * @notice Pause token to mint omniBTC.
     * @param _tokens The address of the token.
     */
    function pauseToken(address[] memory _tokens) external onlyRole(PAUSER_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            pausedTokens[_tokens[i]] = true;
        }
        emit TokenPaused(_tokens);
    }

    /**
     * @notice Unpause token to mint omniBTC.
     * @param _tokens The address of the token.
     */
    function unpauseToken(address[] memory _tokens) external onlyRole(PAUSER_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            pausedTokens[_tokens[i]] = false;
        }
        emit TokenUnpaused(_tokens);
    }

    /**
     * @notice Start all service.
     */
    function startService() external onlyRole(PAUSER_ROLE) {
        outOfService = false;
        emit StartService();
    }

    /**
     * @notice Stop all service.
     */
    function stopService() external onlyRole(PAUSER_ROLE) {
        outOfService = true;
        emit StopService();
    }

    /**
     * ======================================================================================
     *
     * OPERATOR
     *
     * ======================================================================================
     */

    /**
     * @notice Execute a contract call that also transfers '_value' wei to '_target'.
     * @param _target The address of the target contract.
     * @param _data The data to be executed.
     * @param _value The value to be sent.
     */
    function execute(address _target, bytes memory _data, uint256 _value)
        external
        nonReentrant
        onlyRole(OPERATOR_ROLE)
        serviceNormal
        returns (bytes memory)
    {
        require(allowedTargets[_target], "SYS001");
        return _target.functionCallWithValue(_data, _value);
    }

    /**
     * ======================================================================================
     *
     * USER INTERACTION
     *
     * ======================================================================================
     */

    /**
     * @notice Mint omniBTC by sending token to this contract.
     * @param _token The address of the token.
     * @param _amount The amount of token to mint.
     */
    function mint(address _token, uint256 _amount) external serviceNormal {
        require(allowedTokens[_token] && !pausedTokens[_token], "SYS002");
        _mint(msg.sender, _token, _amount);
    }

    /**
     * ======================================================================================
     *
     * INTERNAL FUNCTIONS
     *
     * ======================================================================================
     */

    /**
     * @notice Mint omniBTC by sending token to this contract. internal only.
     * @param _sender The address of the sender.
     * @param _token The address of the token.
     * @param _amount The amount of token to mint.
     */
    function _mint(address _sender, address _token, uint256 _amount) internal {
        (, uint256 omniBTCAmount) = _amounts(_token, _amount);
        require(omniBTCAmount > 0, "USR010");

        uint256 tokenUsedCap = tokenUsedCaps[_token];
        require((tokenUsedCap + _amount < tokenCaps[_token]) && tokenCaps[_token] != 0, "USR003");
        tokenUsedCaps[_token] = tokenUsedCap + _amount;

        IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
        IMintableContract(omniBTC).mint(_sender, omniBTCAmount);

        emit Minted(_token, _amount);
    }

    /**
     * @notice Convert the amount to omniBTC amount.
     * @param _token The address of the token.
     * @param _amount The amount of token.
     */
    function _amounts(address _token, uint256 _amount) internal view returns (uint256, uint256) {
        uint8 decs = ERC20(_token).decimals();
        if (decs == 8) return (_amount, _amount);
        if (decs == 18) {
            uint256 omniBTCAmt = _amount / EXCHANGE_RATE_BASE;
            return (omniBTCAmt * EXCHANGE_RATE_BASE, omniBTCAmt);
        }
        return (0, 0);
    }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */

    /**
     * @notice Event emitted when omniBTC is minted.
     */
    event Minted(address token, uint256 amount);

    /**
     * @notice Event emitted when tokens are added to the paused token list.
     */
    event TokenPaused(address[] token);

    /**
     * @notice Event emitted when tokens are removed from the paused token list.
     */
    event TokenUnpaused(address[] token);

    /**
     * @notice Event emitted when tokens are added to the allowed token list.
     */
    event TokenAllowed(address[] token);

    /**
     * @notice Event emitted when tokens are removed from the allowed token list.
     */
    event TokenDenied(address[] token);

    /**
     * @notice Event emitted when targets are added to the allowed target list.
     */
    event TargetAllowed(address[] token);

    /**
     * @notice Event emitted when targets are removed from the allowed target list.
     */
    event TargetDenied(address[] token);

    /**
     * @notice Event emitted when the service is started.
     */
    event StartService();

    /**
     * @notice Event emitted when the service is stopped.
     */
    event StopService();
}
