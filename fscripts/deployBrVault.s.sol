// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Script} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {brVault} from "../contracts/brVault.sol";

contract MyScript is Script {
    function run() external {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        address _proxyAdmin = vm.envAddress("PROXY_ADMIN");
        console.log("[Env] PROXY_ADMIN:", address(_proxyAdmin));
        address _brBTC = vm.envAddress("BRBTC");
        console.log("[Env] BRBTC:", address(_brBTC));

        vm.startBroadcast(deployer);
        console.log("[Signer] deployer:", deployer);

        address _defaultAdmin = deployer;
        console.log("[Signer] defaultAdmin:", address(_defaultAdmin));

        brVault impl = new brVault();

        bytes memory initializeData = abi.encodeWithSelector(brVault.initialize.selector, _defaultAdmin, _brBTC);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _proxyAdmin, initializeData);
        console.log("[Contract] brVault:", address(proxy));

        vm.stopBroadcast();
    }
}
