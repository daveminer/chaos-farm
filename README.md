# Chaos Farm - Composable Chainlink VRF Client

Chaos Farm implements the Chainlink VRF client and keeps record of VRF call results and the account the call results belong to. The original use case for this contract is inspired by blockchain gaming; the data stored in Chaos farm may be used as a basis for NFT generation with random properties to be used in game systems. With that said, Chaos Farm aims to be a general tool and is not intended to offer any abstractions specific to gaming.

This service is intended to preserve the integrity of the recorded VRF results so the dependent contract may rely upon the data received from Chainlink to be auditable and authentic. The design of Chaos Farm aims to protect the quality of the VRF output data through immutable patterns wherever possible and auditable events where restrictive patterns are less favorable than the features they disable (the ability to change the allowed caller account, for example).

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
