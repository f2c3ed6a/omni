## deploy steps

1. prepare .env file

```plain
DEPLOYER=<deployer-account-name>
DEPLOYER_ADDRESS=<deployer-address>

# edit manually later
PROXY_ADMIN=
BRBTC=
BRVAULT=

EVM_RPC=<evm-rpc>
ETHERSCAN_API_URL=<etherscan-api-url> # https://api.etherscan.io/api , https://api.bscscan.com/api
ETHERSCAN_API_KEY=<etherscan-api-key>
```

2. ProxyAdmin

```bash
source .env

forge script -vvvv --account $DEPLOYER --sender $DEPLOYER_ADDRESS -f $EVM_RPC --broadcast --verify --verifier custom --verifier-api-key $ETHERSCAN_API_KEY --verifier-url $ETHERSCAN_API_URL fscripts/deployProxyAdmin.s.sol

# copy ProxyAdmin address to .env
```

3. brBTC

```bash
source .env

forge script -vvvv --account $DEPLOYER --sender $DEPLOYER_ADDRESS -f $EVM_RPC --broadcast --verify --verifier custom --verifier-api-key $ETHERSCAN_API_KEY --verifier-url $ETHERSCAN_API_URL fscripts/deployBrBTC.s.sol

# copy brBTC address to .env
```

4. brVault

```bash
source .env

forge script -vvvv --account $DEPLOYER --sender $DEPLOYER_ADDRESS -f $EVM_RPC --broadcast --verify --verifier custom --verifier-api-key $ETHERSCAN_API_KEY --verifier-url $ETHERSCAN_API_URL fscripts/deployBrVault.s.sol

# copy brVault address to .env
```

5. config brVault & brBTC

```bash
source .env

forge script -vvvv --account $DEPLOYER --sender $DEPLOYER_ADDRESS -f $EVM_RPC --broadcast --verify --verifier custom --verifier-api-key $ETHERSCAN_API_KEY --verifier-url $ETHERSCAN_API_URL fscripts/configBrVault.s.sol
```
