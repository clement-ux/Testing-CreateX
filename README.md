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
