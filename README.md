# Testing CreateX contract

Original github repo: https://github.com/pcaversaccio/createx

Testing Create and predict address for :
* Simple contract with/without constructor arugments.
* Contract with `_init_()` functions (proxy).
* Cloning already deployed contract.


Testing Create2 and predict address for :
* Simple contract deployment.
* Deploy contrat with Permissioned Deploy Protection and Cross-Chain Redeploy Protection.


## How to use
- First: install and build.
```
forge install
forge build
```

- Second: create two different local blockchain with `anvil` on two different port with two different chainId.
```
anvil --port 8545 --chain-id 1
anvil --port 8546 --chain-id 2
```

- Third: Run tests.
```
make test
```
