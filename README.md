## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Minimal Lending Protocol
A minimal decentralized lending and borrowing protocol built for educational purposes and security research. This protocol demonstrates core decentralized finance lending mechanics including collaterallized borrowing, interest accrual and liquidations.

## Overview
The Minimal lending protocol allows users to:
- Deposit `ERC20` tokens as collateral.
- Borrow tokens against their collateral
- Repay borrowed amount with accrued interest
- Withdraw collateral when health conditions are met
- Liquidate undercollaterized positions

## Architecture
**The core components**
- Single Token System: The protocol operates with one `ERC20` token that serves both as collateral and borrowing asset.
- Overcollaterized Lending: Borrowers must maintain a 150% collateralization ration