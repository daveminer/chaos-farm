# Chaos Farm - Composable Chainlink VRF Client

Chaos Farm implements the Chainlink VRF client and keeps record of VRF call results and the account the call results belong to. The original use case for this contract is inspired by blockchain gaming; the data stored in Chaos farm may be used as a basis for NFT generation with random properties to be used in game systems. With that said, Chaos Farm aims to be a general tool and is not intended to offer any abstractions specific to gaming.

This service is intended to preserve the integrity of the recorded VRF results so the dependent contract may rely upon the data received from Chainlink to be auditable and authentic. The design of Chaos Farm aims to protect the quality of the VRF output data through immutable patterns wherever possible and auditable events where restrictive patterns are less favorable than the features they disable (the ability to change the allowed caller account, for example).

## How to Use

Chaos Farm may be deployed to local EVM development blockchains like [Anvil](https://github.com/foundry-rs/foundry/tree/master/anvil), [Hardhat Network](https://hardhat.org/hardhat-network/docs/overview) or [Ganache](https://trufflesuite.com/ganache/) or testnet/mainnet on [networks that are compatible with Chainlink VRF](https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/).

### Local Demo

Start an Anvil instance in a terminal:

```
anvil
```

In a new terminal at the project root, run the demo script:

```
./script/demo.sh
```

### Polygon Demo

A simple use case is demonstrated on the Polygon Mumbai Testnet.

#### Prerequisites

Add Polygon Testnet Mumbai: https://mumbai.polygonscan.com/
Set up VRF subscription: https://vrf.chain.link/
Test MATIC; get from faucet here: https://faucet.polygon.technology/
Test LINK; get here: https://faucets.chain.link/mumbai
Send LINK to VRF subscription with the token address here: https://docs.chain.link/resources/link-token-contracts/

#### Environment Preparation

Set the following environment variables for contract creation:

```
# Max price for a request; this hash is for max 500 Gwei on Mumbai Testnet.
GAS_LANE_KEY_HASH=0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
# Put your unique subscription ID here.
SUBSCRIPTION_ID=1234
# The Coordinator address for Mumbai Testnet.
VRF_COORDINATOR=0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
# CardExample expects an array even though it only uses the first value.
NUM_WORDS=2
# This is the maximum gas limit; it may be reduced from here. Setting it any higher will cause errors.
CALLBACK_GAS_LIMIT=2500000
# How long Chainlink will wait to respond. Longer wait = more secure.
REQUEST_CONFIRMATIONS=3

GAS_LIMIT=1000000
RPC_URL=https://rpc-mumbai.matic.today

```

Set the wallet values:

```
WALLET_ADDRESS=<your-wallet-address-goes-here>
PRIVATE_KEY=<private-key-goes-here>
```

#### Creating an Instance of Chaos Farm

```
forge create --constructor-args ${GAS_LANE_KEY_HASH} ${SUBSCRIPTION_ID} ${VRF_COORDINATOR} ${NUM_WORDS} ${CALLBACK_GAS_LIMIT} ${REQUEST_CONFIRMATIONS} --private-key ${PRIVATE_KEY} --rpc-url ${RPC_URL} --gas-limit ${GAS_LIMIT} src/Chaos.sol:Chaos
```

Save the contract address from the terminal output to the `CHAOS_FARM_DEMO` environment variable:

```
CHAOS_FARM_DEMO=0x...
```

Set the contract address as a Consumer in the VRF Dashboard as well.

#### Deploy Card Example to use Chaos Farm

We'll use the [Card Example](https://github.com/daveminer/chaos-farm/blob/main/src/examples/CardExample.sol) as the implementation contract.

Deploy the CardExample contract to Mumbai as well (make sure the CHAOS_FARM_DEMO env var is set to your contract address):

```
forge create --constructor-args ${CHAOS_FARM_DEMO} --private-key ${PRIVATE_KEY}  --rpc-url ${RPC_URL} --gas-limit ${GAS_LIMIT} src/examples/CardExample.sol:CardExample
```

```
CARD_EXAMPLE_DEMO=0x...
```

Set CardExample as the authorized caller on the Chaos Farm deployment:
```
cast send ${CHAOS_FARM_DEMO} "setAllowedCaller(address)" ${CARD_EXAMPLE_DEMO} --private-key ${PRIVATE_KEY} --rpc-url ${RPC_URL} --gas-limit ${GAS_LIMIT}
```


#### Use Card Example (draw a card)

```
cast send ${CARD_EXAMPLE_DEMO} "requestNewCard()(uint)" --private-key ${PRIVATE_KEY} --rpc-url ${RPC_URL} --gas-limit ${GAS_LIMIT}
```

```
cast send ${CARD_EXAMPLE_DEMO} "completeNewCard()(uint)" --private-key ${PRIVATE_KEY} --rpc-url ${RPC_URL} --gas-limit ${GAS_LIMIT}
```

See the card that was drawn:

```
cast call ${CARD_EXAMPLE_DEMO} "lastCard(address)" ${WALLET_ADDRESS} --rpc-url https://rpc-mumbai.matic.today
```

### Tools

- [Foundry](https://github.com/foundry-rs/foundry)
- [Chainlink Brownie Contracts](https://github.com/smartcontractkit/chainlink-brownie-contracts)
