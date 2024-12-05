// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {omniBTC} from "../contracts/omniBTC.sol";
import {omniVault} from "../contracts/omniVault.sol";

contract MyScript is Script {
    omniBTC public omniBTCInstance;
    omniVault public omniVaultInstance;

    function run() external {
        address _proxyAdmin = address(0x1);
        address sender = msg.sender;

        vm.startBroadcast();

        setUpOmniBTC(_proxyAdmin, sender, sender);
        setUpOmniVault(_proxyAdmin, sender, sender);

        vm.stopBroadcast();
    }

    function setUpOmniVault(address _proxyAdmin, address _defaultAdmin, address _operator) public {
        omniVault impl = new omniVault();

        bytes memory initializeData =
            abi.encodeWithSelector(omniVault.initialize.selector, _defaultAdmin, address(omniBTCInstance));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _proxyAdmin, initializeData);
        omniVaultInstance = omniVault(payable(address(proxy)));

        omniVaultInstance.grantRole(omniVaultInstance.OPERATOR_ROLE(), _operator);
        omniBTCInstance.grantRole(omniBTCInstance.MINTER_ROLE(), address(omniVaultInstance));
    }

    function setUpOmniBTC(address _proxyAdmin, address _defaultAdmin, address _minter) public {
        omniBTC impl = new omniBTC();

        bytes memory initializeData = abi.encodeWithSelector(omniBTC.initialize.selector, _defaultAdmin, _minter);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _proxyAdmin, initializeData);
        omniBTCInstance = omniBTC(address(proxy));
    }
}
