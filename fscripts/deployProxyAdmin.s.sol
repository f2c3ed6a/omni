// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Script} from "forge-std/Script.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract MyScript is Script {
    function run() external {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        vm.startBroadcast(deployer);
        console.log("[Signer] deployer:", deployer);

        ProxyAdmin pm = new ProxyAdmin();
        console.log("[Contract] ProxyAdmin:", address(pm));

        vm.stopBroadcast();
    }
}
