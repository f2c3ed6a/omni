// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Script} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {brBTC} from "../contracts/brBTC.sol";

contract MyScript is Script {
    function run() external {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        address _proxyAdmin = vm.envAddress("PROXY_ADMIN");
        console.log("[Env] PROXY_ADMIN:", address(_proxyAdmin));

        vm.startBroadcast(deployer);
        console.log("[Signer] deployer:", deployer);

        address _defaultAdmin = deployer;
        console.log("[Signer] defaultAdmin:", address(_defaultAdmin));

        brBTC impl = new brBTC();

        bytes memory initializeData = abi.encodeWithSelector(brBTC.initialize.selector, _defaultAdmin, address(0x0));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), _proxyAdmin, initializeData);
        console.log("[Contract] brBTC:", address(proxy));

        vm.stopBroadcast();
    }
}
