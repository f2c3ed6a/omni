// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {brBTC} from "../contracts/brBTC.sol";

contract brBTCTest is Test {
    address private constant _PROXY_ADMIN = address(0x1);
    address private constant _DEFAULT_ADMIN = address(0x2);
    address private constant _DEFAULT_MINTER = address(0x3);

    brBTC public brBTCInstance;

    function setUp() public {
        setUpbrBTC();
    }

    function setUpbrBTC() public {
        brBTC impl = new brBTC();

        bytes memory initializeData = abi.encodeWithSelector(brBTC.initialize.selector, _DEFAULT_ADMIN, _DEFAULT_MINTER);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _PROXY_ADMIN, initializeData);
        brBTCInstance = brBTC(address(proxy));

        assertEq(brBTCInstance.name(), "brBTC");
        assertEq(brBTCInstance.decimals(), 8);
        assert(brBTCInstance.hasRole(brBTCInstance.DEFAULT_ADMIN_ROLE(), _DEFAULT_ADMIN));
        assert(brBTCInstance.hasRole(brBTCInstance.MINTER_ROLE(), _DEFAULT_MINTER));
    }

    function testMint() public {
        vm.startPrank(_DEFAULT_MINTER);
        brBTCInstance.mint(_DEFAULT_MINTER, 1);
        vm.stopPrank();

        assertEq(brBTCInstance.totalSupply(), 1);
        assertEq(brBTCInstance.balanceOf(_DEFAULT_MINTER), 1);
    }

    function testBurn() public {
        vm.startPrank(_DEFAULT_MINTER);
        brBTCInstance.mint(_DEFAULT_MINTER, 1);
        brBTCInstance.burn(1);
        vm.stopPrank();

        assertEq(brBTCInstance.totalSupply(), 0);
    }

    function testTransfer() public {
        address _alice = address(0xdeadbeef);

        vm.startPrank(_DEFAULT_MINTER);
        brBTCInstance.mint(_DEFAULT_MINTER, 1);
        brBTCInstance.transfer(_alice, 1);
        vm.stopPrank();

        assertEq(brBTCInstance.balanceOf(_alice), 1);
    }

    function testFreeze() public {
        address _alice = address(0xdeadbeef);

        vm.startPrank(_DEFAULT_MINTER);
        brBTCInstance.mint(_alice, 3);
        vm.stopPrank();

        assertEq(brBTCInstance.balanceOf(_alice), 3);

        vm.startPrank(_alice);
        brBTCInstance.transfer(address(0x1), 1);
        vm.stopPrank();

        assertEq(brBTCInstance.balanceOf(_alice), 2);

        vm.startPrank(_DEFAULT_ADMIN);
        brBTCInstance.setFreezeToRecipient(_DEFAULT_ADMIN);

        address[] memory users = new address[](1);
        users[0] = _alice;

        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000002 is missing role 0x92de27771f92d6942691d73358b3a4673e4880de8356f8f2cf452be87e02d363"
        );
        brBTCInstance.freezeUsers(users);

        brBTCInstance.grantRole(brBTCInstance.FREEZER_ROLE(), _DEFAULT_ADMIN);
        brBTCInstance.freezeUsers(users);
        vm.stopPrank();

        assertEq(brBTCInstance.frozenUsers(_alice), true);

        vm.startPrank(_alice);
        vm.expectRevert("USR016");
        brBTCInstance.transfer(address(0xbabecafe0001), 1);

        vm.expectRevert("USR016");
        brBTCInstance.transfer(address(0xbabecafe0002), 1);

        vm.expectRevert("USR016");
        brBTCInstance.transfer(_alice, 1);

        brBTCInstance.transfer(_DEFAULT_ADMIN, 1);
        vm.stopPrank();

        vm.startPrank(_DEFAULT_ADMIN);
        brBTCInstance.unfreezeUsers(users);
        vm.stopPrank();

        assertEq(brBTCInstance.frozenUsers(_alice), false);

        vm.startPrank(_alice);
        brBTCInstance.transfer(address(0xbabecafe0001), 1);
        vm.stopPrank();

        assertEq(brBTCInstance.balanceOf(_alice), 0);
    }
}
