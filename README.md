# Chaos Farm - Composable Chainlink VRF Client

Chaos Farm implements a client for the [Chainlink VRF V2 service](https://chain.link/vrf) and keeps record of the VRF call results along with the account the call results belong to. This allows instances of Chaos Farm to manage a [Programmatic Subscription](https://docs.chain.link/vrf/v2/subscription/examples/programmatic-subscription) to Chainlink for use by other contracts that need to assign and keep track of VRF results to addresses.

## How to Use

Chaos Farm may be deployed to local EVM development blockchains like [Anvil](https://github.com/foundry-rs/foundry/tree/master/anvil), [Hardhat Network](https://hardhat.org/hardhat-network/docs/overview) or [Ganache](https://trufflesuite.com/ganache/) and testnet/mainnet on networks that are [compatible](https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/) with Chainlink VRF.

### Local Demo

Start an Anvil instance in a terminal:

```
anvil
```

In a new terminal at the project root, run the demo script:

```
./demo.sh
```

### Tools

- [Foundry](https://github.com/foundry-rs/foundry)
- [Chainlink Brownie Contracts](https://github.com/smartcontractkit/chainlink-brownie-contracts)
