// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {brBTC} from "../contracts/brBTC.sol";
import {brVault} from "../contracts/brVault.sol";

contract MyScript is Script {
    brBTC public brBTCInstance;
    brVault public brVaultInstance;

    function run() external {
        address _proxyAdmin = address(0x1);
        address sender = msg.sender;

        vm.startBroadcast();

        setUpbrBTC(_proxyAdmin, sender, sender);
        setUpbrVault(_proxyAdmin, sender, sender);

        vm.stopBroadcast();
    }

    function setUpbrVault(address _proxyAdmin, address _defaultAdmin, address _operator) public {
        brVault impl = new brVault();

        bytes memory initializeData =
            abi.encodeWithSelector(brVault.initialize.selector, _defaultAdmin, address(brBTCInstance));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _proxyAdmin, initializeData);
        brVaultInstance = brVault(payable(address(proxy)));

        brVaultInstance.grantRole(brVaultInstance.OPERATOR_ROLE(), _operator);
        brBTCInstance.grantRole(brBTCInstance.MINTER_ROLE(), address(brVaultInstance));
    }

    function setUpbrBTC(address _proxyAdmin, address _defaultAdmin, address _minter) public {
        brBTC impl = new brBTC();

        bytes memory initializeData = abi.encodeWithSelector(brBTC.initialize.selector, _defaultAdmin, _minter);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _proxyAdmin, initializeData);
        brBTCInstance = brBTC(address(proxy));
    }
}
