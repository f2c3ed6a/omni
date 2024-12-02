// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {omniBTC} from "../contracts/omniBTC.sol";

contract OmniBTCTest is Test {
    address private constant _PROXY_ADMIN = address(0x1);
    address private constant _DEFAULT_ADMIN = address(0x2);
    address private constant _DEFAULT_MINTER = address(0x3);

    omniBTC public omniBTCInstance;

    function setUp() public {
        setUpOmniBTC();
    }

    function setUpOmniBTC() public {
        omniBTC impl = new omniBTC();

        bytes memory initializeData =
            abi.encodeWithSelector(omniBTC.initialize.selector, _DEFAULT_ADMIN, _DEFAULT_MINTER, new address[](0));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _PROXY_ADMIN, initializeData);
        omniBTCInstance = omniBTC(address(proxy));

        assertEq(omniBTCInstance.name(), "omniBTC");
        assertEq(omniBTCInstance.decimals(), 8);
        assert(omniBTCInstance.hasRole(omniBTCInstance.DEFAULT_ADMIN_ROLE(), _DEFAULT_ADMIN));
        assert(omniBTCInstance.hasRole(omniBTCInstance.MINTER_ROLE(), _DEFAULT_MINTER));
    }

    function testMint() public {
        vm.startPrank(_DEFAULT_MINTER);
        omniBTCInstance.mint(_DEFAULT_MINTER, 1);
        vm.stopPrank();

        assertEq(omniBTCInstance.totalSupply(), 1);
        assertEq(omniBTCInstance.balanceOf(_DEFAULT_MINTER), 1);
    }

    function testBurn() public {
        vm.startPrank(_DEFAULT_MINTER);
        omniBTCInstance.mint(_DEFAULT_MINTER, 1);
        omniBTCInstance.burn(1);
        vm.stopPrank();

        assertEq(omniBTCInstance.totalSupply(), 0);
    }

    function testTransfer() public {
        address _alice = address(0xdeadbeef);

        vm.startPrank(_DEFAULT_MINTER);
        omniBTCInstance.mint(_DEFAULT_MINTER, 1);
        omniBTCInstance.transfer(_alice, 1);
        vm.stopPrank();

        assertEq(omniBTCInstance.balanceOf(_alice), 1);
    }
}
