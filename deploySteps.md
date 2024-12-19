## deploy steps

1. prepare .env file

```plain
DEPLOYER=<deployer-account-name>
DEPLOYER_ADDRESS=<deployer-address>

# edit manually later
PROXY_ADMIN=
BRBTC=
BRVAULT=

# eth rpc or bsc rpc
EVM_RPC=<evm-rpc>
```

2. ProxyAdmin

```bash
source .env

forge script -vvvv --account $DEPLOYER --sender $DEPLOYER_ADDRESS -f $ETH_RPC --broadcast --verify fscripts/deployProxyAdmin.s.sol

# copy ProxyAdmin address to .env
```

3. brBTC

```bash
source .env

forge script -vvvv --account $DEPLOYER --sender $DEPLOYER_ADDRESS -f $ETH_RPC --broadcast --verify fscripts/deployBrBTC.s.sol

# copy brBTC address to .env
```

4. brVault

```bash
source .env

forge script -vvvv --account $DEPLOYER --sender $DEPLOYER_ADDRESS -f $ETH_RPC --broadcast --verify fscripts/deployBrVault.s.sol

# copy brVault address to .env
```

5. config brVault & brBTC

```bash
source .env

forge script -vvvv --account $DEPLOYER --sender $DEPLOYER_ADDRESS -f $ETH_RPC --broadcast --verify fscripts/configBrVault.s.sol
```
