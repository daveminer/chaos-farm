# Chaos Farm - Composable Chainlink VRF Client

Chaos Farm implements the Chainlink VRF client and keeps record of VRF call results and the account the call results belong to. The original use case for this contract is inspired by blockchain gaming; the data stored in Chaos farm may be used as a basis for NFT generation with random properties to be used in game systems. With that said, Chaos Farm aims to be a general tool and is not intended to offer any abstractions specific to gaming.

Chaos farm is designed to be used as a service by other contracts. This service is intended to preserve the integrity of the recorded VRF results so the dependent contract may rely upon the data received from Chainlink to be auditable and authentic. The design of Chaos Farm aims to protect the quality of the VRF output data through immutable patterns wherever possible and auditable events where restrictive patterns are less favorable than the features they disable (the ability to change the allowed caller account, for example).

## How to Use

Chaos Farm may be deployed to local EVM development blockchains like [Anvil](https://github.com/foundry-rs/foundry/tree/master/anvil), [Hardhat Network](https://hardhat.org/hardhat-network/docs/overview) or [Ganache](https://trufflesuite.com/ganache/) or testnet/mainnet on [networks that are compatible with Chainlink VRF](https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/).


### Local Development with [Anvil](https://github.com/foundry-rs/foundry/tree/master/anvil) and [Cast](https://book.getfoundry.sh/cast/)

Start an Anvil instance in a terminal:
```
anvil
```

Choose one of the private keys in the Anvil instance and set it as an environment variable in a new terminal:

```
ANVIL_PKEY=<<any-private-key-from-anvil>>
```

...along with the other environment variables below:

```
# .1 LINK
BASE_FEE=10000000000000000
# Max Gas per VRF service call
GAS_PRICE_LINK=1000000000000
```

If deploying to a local blockchain, the [MockVRFCoordinatorV2.sol](https://github.com/daveminer/chaos-farm/blob/df20ac2f0479653d60429655e5362434331f05bf/test/mocks/MockVRFCoordinatorV2.sol) contract must be deployed before Chaos Farm:

```
forge create --rpc-url http://127.0.0.1:8545 --constructor-args $BASE_FEE $GAS_PRICE_LINK --private-key $ANVIL_PKEY src/mocks/MockVRFCoordinatorV2.sol:VRFCoordinatorV2Mock
```

Find the `Deployed to:` address from the contract deployment and set it as another environment variable:
```
VRF_CONTRACT=<address-from-mock-vrf-depoloy>
```


###

### Tools
- [Foundry](https://github.com/foundry-rs/foundry)
- [Chainlink Brownie Contracts](https://github.com/smartcontractkit/chainlink-brownie-contracts)
