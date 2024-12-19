// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Script} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {brBTC} from "../contracts/brBTC.sol";
import {brVault} from "../contracts/brVault.sol";

contract MyScript is Script {
    function run() external {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        address _brBTCAddr = vm.envAddress("BRBTC");
        console.log("[Env] BRBTC:", _brBTCAddr);
        address _brVaultAddr = vm.envAddress("BRVAULT");
        console.log("[Env] BRVAULT:", _brVaultAddr);

        vm.startBroadcast(deployer);
        console.log("[Signer] deployer:", deployer);

        brVault _brVault = brVault(_brVaultAddr);
        if (block.chainid == 17000) {
            console.log("[Chain] Ethereum Mainnet");

            address _uniBTC = address(0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568); // 8
            address _WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // 8
            address _FBTC = address(0xC96dE26018A54D51c097160568752c4E3BD6C364); // 8
            address _cbBTC = address(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf); // 8
            address _MBTC = address(0x2F913C820ed3bEb3a67391a6eFF64E70c4B20b19); // 18

            address[] memory allowedToken = new address[](5);
            allowedToken[0] = _uniBTC;
            allowedToken[1] = _WBTC;
            allowedToken[2] = _FBTC;
            allowedToken[3] = _cbBTC;
            allowedToken[4] = _MBTC;
            _brVault.allowToken(allowedToken);

            _brVault.setCap(_uniBTC, 3000 * (10 ** ERC20(_uniBTC).decimals()));
            _brVault.setCap(_WBTC, 500 * (10 ** ERC20(_WBTC).decimals()));
            _brVault.setCap(_FBTC, 500 * (10 ** ERC20(_FBTC).decimals()));
            _brVault.setCap(_cbBTC, 500 * (10 ** ERC20(_cbBTC).decimals()));
            _brVault.setCap(_MBTC, 500 * (10 ** ERC20(_MBTC).decimals()));
        } else if (block.chainid == 56) {
            console.log("[Chain] Binance Smart Chain");

            address _uniBTC = address(0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a); // 8
            address _BTCB = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c); // 18
            address _FBTC = address(0xC96dE26018A54D51c097160568752c4E3BD6C364); // 8
            // address _MBTC = address(0x0);

            address[] memory allowedToken = new address[](3);
            allowedToken[0] = _uniBTC;
            allowedToken[1] = _BTCB;
            allowedToken[2] = _FBTC;
            // allowedToken[3] = _MBTC;
            _brVault.allowToken(allowedToken);

            _brVault.setCap(_uniBTC, 3000 * (10 ** ERC20(_uniBTC).decimals()));
            _brVault.setCap(_BTCB, 500 * (10 ** ERC20(_BTCB).decimals()));
            _brVault.setCap(_FBTC, 500 * (10 ** ERC20(_FBTC).decimals()));
            // _brVault.setCap(_MBTC, 90 * (10 ** ERC20(_MBTC).decimals()));
        }

        brBTC _brBTC = brBTC(_brBTCAddr);
        _brBTC.grantRole(_brBTC.MINTER_ROLE(), _brVaultAddr);

        vm.stopBroadcast();
    }
}
