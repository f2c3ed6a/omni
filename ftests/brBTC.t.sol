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
}
