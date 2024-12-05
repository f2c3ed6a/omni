// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {omniBTC} from "../contracts/omniBTC.sol";
import {omniVault} from "../contracts/omniVault.sol";
import {WBTC} from "../contracts/mocks/WBTC.sol";
import {WBTC18} from "../contracts/mocks/WBTC18.sol";

contract OmniVaultTest is Test {
    address private constant _PROXY_ADMIN = address(0x1);
    address private constant _DEFAULT_ADMIN = address(0x2);
    address private constant _DEFAULT_MINTER = address(0x3);

    Utils public utils;
    omniBTC public omniBTCInstance;
    omniVault public omniVaultInstance;

    function setUp() public {
        utils = new Utils();
        utils.setUp(_DEFAULT_MINTER);

        setUpOmniBTC();
        setUpOmniVault();
    }

    function setUpOmniVault() public {
        omniVault impl = new omniVault();

        bytes memory initializeData =
            abi.encodeWithSelector(omniVault.initialize.selector, _DEFAULT_ADMIN, address(omniBTCInstance));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _PROXY_ADMIN, initializeData);
        omniVaultInstance = omniVault(payable(address(proxy)));

        assert(omniVaultInstance.hasRole(omniVaultInstance.DEFAULT_ADMIN_ROLE(), _DEFAULT_ADMIN));
        assert(omniVaultInstance.hasRole(omniVaultInstance.PAUSER_ROLE(), _DEFAULT_ADMIN));

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.grantRole(omniVaultInstance.OPERATOR_ROLE(), _DEFAULT_MINTER);
        vm.stopPrank();
        assert(omniVaultInstance.hasRole(omniVaultInstance.OPERATOR_ROLE(), _DEFAULT_MINTER));

        vm.startPrank(_DEFAULT_ADMIN);
        omniBTCInstance.grantRole(omniBTCInstance.MINTER_ROLE(), address(omniVaultInstance));
        vm.stopPrank();
        assert(omniBTCInstance.hasRole(omniBTCInstance.MINTER_ROLE(), address(omniVaultInstance)));
    }

    function setUpOmniBTC() public {
        omniBTC impl = new omniBTC();

        bytes memory initializeData =
            abi.encodeWithSelector(omniBTC.initialize.selector, _DEFAULT_ADMIN, _DEFAULT_MINTER);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _PROXY_ADMIN, initializeData);
        omniBTCInstance = omniBTC(address(proxy));

        assertEq(omniBTCInstance.name(), "omniBTC");
        assertEq(omniBTCInstance.decimals(), 8);
        assert(omniBTCInstance.hasRole(omniBTCInstance.DEFAULT_ADMIN_ROLE(), _DEFAULT_ADMIN));
        assert(omniBTCInstance.hasRole(omniBTCInstance.MINTER_ROLE(), _DEFAULT_MINTER));
    }

    function testSimpleMint() public {
        WBTC wbtc = new WBTC();
        IERC20 omniBTCToken = IERC20(omniVaultInstance.omniBTC());

        address[] memory allowedToken = new address[](1);
        allowedToken[0] = address(wbtc);

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        omniVaultInstance.setCap(address(wbtc), 100 * 1e8);
        vm.stopPrank();

        address _alice = address(0x123123);
        wbtc.mint(_alice, 1 * 1e8);
        assertEq(wbtc.balanceOf(_alice), 1 * 1e8);

        vm.startPrank(_alice);
        wbtc.approve(address(omniVaultInstance), 1 * 1e8);
        omniVaultInstance.mint(address(wbtc), 1 * 1e8);
        vm.stopPrank();

        assertEq(wbtc.balanceOf(_alice), 0);
        assertEq(omniBTCToken.balanceOf(_alice), 1 * 1e8);
    }

    function testTokenNotAllowed() public {
        WBTC wbtc = new WBTC();
        IERC20 omniBTCToken = IERC20(omniVaultInstance.omniBTC());

        vm.startPrank(_DEFAULT_ADMIN);
        // omniVaultInstance.allowToken(allowedToken);
        omniVaultInstance.setCap(address(wbtc), 100 * 1e8);
        vm.stopPrank();

        address _alice = address(0x123123);
        wbtc.mint(_alice, 1 * 1e8);
        assertEq(wbtc.balanceOf(_alice), 1 * 1e8);

        vm.startPrank(_alice);
        wbtc.approve(address(omniVaultInstance), 1 * 1e8);
        vm.expectRevert("SYS002");
        omniVaultInstance.mint(address(wbtc), 1 * 1e8);
        vm.stopPrank();

        assertEq(wbtc.balanceOf(_alice), 1 * 1e8);
        assertEq(omniBTCToken.balanceOf(_alice), 0 * 1e8);
    }

    function testTokenWithoutCap() public {
        WBTC wbtc = new WBTC();
        IERC20 omniBTCToken = IERC20(omniVaultInstance.omniBTC());

        address[] memory allowedToken = new address[](1);
        allowedToken[0] = address(wbtc);

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        // omniVaultInstance.setCap(address(wbtc), 100 * 1e8);
        vm.stopPrank();

        address _alice = address(0x123123);
        wbtc.mint(_alice, 1 * 1e8);
        assertEq(wbtc.balanceOf(_alice), 1 * 1e8);

        vm.startPrank(_alice);
        wbtc.approve(address(omniVaultInstance), 1 * 1e8);
        vm.expectRevert("USR003");
        omniVaultInstance.mint(address(wbtc), 1 * 1e8);
        vm.stopPrank();

        assertEq(wbtc.balanceOf(_alice), 1 * 1e8);
        assertEq(omniBTCToken.balanceOf(_alice), 0 * 1e8);
    }

    function testUtils() public {
        vm.startPrank(_DEFAULT_MINTER);
        utils.MockWBTC8().mint(address(this), 100 * 1e8);
        vm.stopPrank();

        assertEq(utils.MockWBTC8().balanceOf(address(this)), 100 * 1e8);
    }

    function testMint() public {
        address[] memory allowedToken = new address[](2);
        allowedToken[0] = address(utils.MockWBTC8());
        allowedToken[1] = address(utils.MockWBTC18());

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        omniVaultInstance.setCap(address(utils.MockWBTC8()), 8 * 1e8 + 1);
        omniVaultInstance.setCap(address(utils.MockWBTC18()), 18 * 1e18 + 1);
        vm.stopPrank();

        address _alice = address(0xdeadbeef);

        vm.startPrank(_DEFAULT_MINTER);
        utils.MockWBTC8().mint(_alice, 100 * 1e8);
        utils.MockWBTC10().mint(_alice, 100 * 1e10);
        utils.MockWBTC18().mint(_alice, 100 * 1e18);
        utils.MockDecimalToken8().mint(_alice, 100 * 1e8);
        utils.MockDecimalToken10().mint(_alice, 100 * 1e10);
        utils.MockDecimalToken18().mint(_alice, 100 * 1e18);
        vm.stopPrank();

        vm.startPrank(_alice);
        utils.MockWBTC8().approve(address(omniVaultInstance), 100 * 1e8);
        utils.MockWBTC10().approve(address(omniVaultInstance), 100 * 1e10);
        utils.MockWBTC18().approve(address(omniVaultInstance), 100 * 1e18);
        utils.MockDecimalToken8().approve(address(omniVaultInstance), 100 * 1e8);
        utils.MockDecimalToken10().approve(address(omniVaultInstance), 100 * 1e10);
        utils.MockDecimalToken18().approve(address(omniVaultInstance), 100 * 1e18);

        // mint by 1 WBTC
        omniVaultInstance.mint(address(utils.MockWBTC8()), 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        // mint by 7 WBTC
        omniVaultInstance.mint(address(utils.MockWBTC8()), 7 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 8 * 1e8);

        // mint by 1 WBTC, should revert
        address _wbtc8 = address(utils.MockWBTC8());
        vm.expectRevert("USR003");
        omniVaultInstance.mint(_wbtc8, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 8 * 1e8);

        // mint by 0 WBTC, should revert
        vm.expectRevert("USR010");
        omniVaultInstance.mint(_wbtc8, 0);
        assertEq(omniBTCInstance.balanceOf(_alice), 8 * 1e8);

        // mint by 1 WBTC10, should revert
        address _wbtc10 = address(utils.MockWBTC10());
        vm.expectRevert("SYS002");
        omniVaultInstance.mint(_wbtc10, 1 * 1e10);
        assertEq(omniBTCInstance.balanceOf(_alice), 8 * 1e8);

        // mint by 8 WBTC18
        omniVaultInstance.mint(address(utils.MockWBTC18()), 8 * 1e18);
        assertEq(omniBTCInstance.balanceOf(_alice), 16 * 1e8);
        // mint by 10 WBTC18
        omniVaultInstance.mint(address(utils.MockWBTC18()), 10 * 1e18);
        assertEq(omniBTCInstance.balanceOf(_alice), 26 * 1e8);

        // mint by 1 WBTC18, should revert
        address _wbtc18 = address(utils.MockWBTC18());
        vm.expectRevert("USR003");
        omniVaultInstance.mint(_wbtc18, 1 * 1e18);
        assertEq(omniBTCInstance.balanceOf(_alice), 26 * 1e8);

        // mint by 1 DecimalToken8
        address _decimalToken8 = address(utils.MockDecimalToken8());
        vm.expectRevert("SYS002");
        omniVaultInstance.mint(_decimalToken8, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 26 * 1e8);

        // mint by 1 DecimalToken10
        address _decimalToken10 = address(utils.MockDecimalToken10());
        vm.expectRevert("SYS002");
        omniVaultInstance.mint(_decimalToken10, 1 * 1e10);
        assertEq(omniBTCInstance.balanceOf(_alice), 26 * 1e8);

        // mint by 1 DecimalToken18
        address _decimalToken18 = address(utils.MockDecimalToken18());
        vm.expectRevert("SYS002");
        omniVaultInstance.mint(_decimalToken18, 1 * 1e18);
        assertEq(omniBTCInstance.balanceOf(_alice), 26 * 1e8);

        vm.stopPrank();
    }

    function testOutOfService() public {
        address[] memory allowedToken = new address[](1);
        allowedToken[0] = address(utils.MockWBTC8());

        address _pauser = address(0x1000001);

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        omniVaultInstance.setCap(address(utils.MockWBTC8()), 100 * 1e8);
        omniVaultInstance.grantRole(omniVaultInstance.PAUSER_ROLE(), _pauser);
        vm.stopPrank();

        address _alice = address(0x2123123);

        vm.startPrank(_DEFAULT_MINTER);
        utils.MockWBTC8().mint(_alice, 100 * 1e8);
        vm.stopPrank();

        vm.startPrank(_alice);
        utils.MockWBTC8().approve(address(omniVaultInstance), 100 * 1e8);
        omniVaultInstance.mint(address(utils.MockWBTC8()), 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        vm.stopPrank();

        vm.startPrank(_pauser);
        omniVaultInstance.stopService();
        vm.stopPrank();

        address _wbtc8 = address(utils.MockWBTC8());

        vm.startPrank(_alice);
        vm.expectRevert("SYS011");
        omniVaultInstance.mint(_wbtc8, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        vm.stopPrank();

        vm.startPrank(_pauser);
        omniVaultInstance.startService();
        vm.stopPrank();

        vm.startPrank(_alice);
        omniVaultInstance.mint(_wbtc8, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 2 * 1e8);
        vm.stopPrank();
    }

    function testPauseToken() public {
        address[] memory allowedToken = new address[](1);
        allowedToken[0] = address(utils.MockWBTC8());

        address _pauser = address(0x1000001);

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        omniVaultInstance.setCap(address(utils.MockWBTC8()), 100 * 1e8);
        omniVaultInstance.grantRole(omniVaultInstance.PAUSER_ROLE(), _pauser);
        vm.stopPrank();

        address _alice = address(0xaabb);

        vm.startPrank(_DEFAULT_MINTER);
        utils.MockWBTC8().mint(_alice, 100 * 1e8);
        vm.stopPrank();

        vm.startPrank(_alice);
        utils.MockWBTC8().approve(address(omniVaultInstance), 100 * 1e8);
        omniVaultInstance.mint(address(utils.MockWBTC8()), 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        vm.stopPrank();

        vm.startPrank(_pauser);
        omniVaultInstance.pauseToken(allowedToken);
        vm.stopPrank();

        address _wbtc8 = address(utils.MockWBTC8());

        vm.startPrank(_alice);
        vm.expectRevert("SYS002");
        omniVaultInstance.mint(_wbtc8, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        vm.stopPrank();

        vm.startPrank(_pauser);
        omniVaultInstance.unpauseToken(allowedToken);
        vm.stopPrank();

        vm.startPrank(_alice);
        omniVaultInstance.mint(_wbtc8, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 2 * 1e8);
        vm.stopPrank();
    }

    function testDenyToken() public {
        address[] memory allowedToken = new address[](1);
        allowedToken[0] = address(utils.MockWBTC8());

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        omniVaultInstance.setCap(address(utils.MockWBTC8()), 100 * 1e8);
        vm.stopPrank();

        address _alice = address(0xaabbccdd);

        vm.startPrank(_DEFAULT_MINTER);
        utils.MockWBTC8().mint(_alice, 100 * 1e8);
        vm.stopPrank();

        vm.startPrank(_alice);
        utils.MockWBTC8().approve(address(omniVaultInstance), 100 * 1e8);
        omniVaultInstance.mint(address(utils.MockWBTC8()), 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        vm.stopPrank();

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.denyToken(allowedToken);
        vm.stopPrank();

        address _wbtc8 = address(utils.MockWBTC8());

        vm.startPrank(_alice);
        vm.expectRevert("SYS002");
        omniVaultInstance.mint(_wbtc8, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        vm.stopPrank();

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        vm.stopPrank();

        vm.startPrank(_alice);
        omniVaultInstance.mint(_wbtc8, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 2 * 1e8);
        vm.stopPrank();
    }

    function testExecuteTarget() public {
        address[] memory allowedToken = new address[](1);
        allowedToken[0] = address(utils.MockWBTC8());

        address _operator = address(0x1000002);

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        omniVaultInstance.setCap(address(utils.MockWBTC8()), 100 * 1e8);
        omniVaultInstance.grantRole(omniVaultInstance.OPERATOR_ROLE(), _operator);
        vm.stopPrank();

        address _alice = address(0x1111);

        vm.startPrank(_DEFAULT_MINTER);
        utils.MockWBTC8().mint(_alice, 100 * 1e8);
        vm.stopPrank();

        vm.startPrank(_alice);
        utils.MockWBTC8().approve(address(omniVaultInstance), 100 * 1e8);
        omniVaultInstance.mint(address(utils.MockWBTC8()), 2 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 2 * 1e8);
        omniBTCInstance.transfer(address(omniVaultInstance), 2 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 0);
        assertEq(omniBTCInstance.balanceOf(address(omniVaultInstance)), 2 * 1e8);
        vm.stopPrank();

        address[] memory allowedTarget = new address[](1);
        allowedTarget[0] = address(omniBTCInstance);

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowTarget(allowedTarget);
        vm.stopPrank();

        bytes memory _calldata = abi.encodeWithSelector(IERC20.transfer.selector, address(_alice), 1 * 1e8);

        vm.startPrank(_operator);
        omniVaultInstance.execute(address(omniBTCInstance), _calldata, 0);
        vm.stopPrank();
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(address(omniVaultInstance)), 1 * 1e8);

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.denyTarget(allowedTarget);
        vm.stopPrank();

        vm.startPrank(_operator);
        vm.expectRevert("SYS001");
        omniVaultInstance.execute(address(omniBTCInstance), _calldata, 0);
        vm.stopPrank();
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(address(omniVaultInstance)), 1 * 1e8);
    }

    function testDecimal() public {
        address[] memory allowedToken = new address[](1);
        allowedToken[0] = address(utils.MockDecimalToken8());

        vm.startPrank(_DEFAULT_ADMIN);
        omniVaultInstance.allowToken(allowedToken);
        omniVaultInstance.setCap(address(utils.MockDecimalToken8()), 100 * 1e8);
        vm.stopPrank();

        address _alice = address(0xdeadbeefaa);
        utils.MockDecimalToken8().mint(_alice, 100 * 1e8);

        vm.startPrank(_alice);
        utils.MockDecimalToken8().approve(address(omniVaultInstance), 100 * 1e8);
        omniVaultInstance.mint(address(utils.MockDecimalToken8()), 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        vm.stopPrank();

        IResetDecimal(address(utils.MockDecimalToken8())).resetDecimals(10);

        vm.startPrank(_alice);
        address _tk = address(utils.MockDecimalToken8());
        vm.expectRevert("USR010");
        omniVaultInstance.mint(_tk, 1 * 1e8);
        assertEq(omniBTCInstance.balanceOf(_alice), 1 * 1e8);
        vm.stopPrank();
    }
}

interface IMintableToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IResetDecimal {
    function resetDecimals(uint8 _decimals) external;
}

contract Utils {
    IMintableToken public MockWBTC8;
    IMintableToken public MockWBTC10;
    IMintableToken public MockWBTC18;
    IMintableToken public MockDecimalToken8;
    IMintableToken public MockDecimalToken10;
    IMintableToken public MockDecimalToken18;

    function setUp(address _minter) public {
        WBTC wbtc = new WBTC();
        wbtc.setMintable(_minter, true);
        MockWBTC8 = IMintableToken(address(wbtc));

        MockWBTC10 = new DecimalToken(10);

        WBTC18 wbtc18 = new WBTC18();
        wbtc18.setMintable(_minter, true);
        MockWBTC18 = IMintableToken(address(wbtc18));

        MockDecimalToken8 = new DecimalToken(8);
        MockDecimalToken10 = new DecimalToken(10);
        MockDecimalToken18 = new DecimalToken(18);
    }
}

contract DecimalToken is ERC20, IMintableToken {
    uint8 public customDecimals;

    constructor(uint8 _decimals) ERC20("DecimalToken", string.concat("DT", Strings.toString(_decimals))) {
        customDecimals = _decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return customDecimals;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function resetDecimals(uint8 _decimals) public {
        customDecimals = _decimals;
    }
}
