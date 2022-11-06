# Chaos Farm - Composable Chainlink VRF Client

Chaos Farm implements the Chainlink VRF client and keeps record of VRF call results and the account the call results belong to. The original use case for this contract is inspired by blockchain gaming; the data stored in Chaos farm may be used as a basis for NFT generation with random properties to be used in game systems. With that said, Chaos Farm aims to be a general tool and is not intended to offer any abstractions specific to gaming.

Chaos farm is designed to be used as a service by other contracts. This service is intended to preserve the integrity of the recorded VRF results so the dependent contract may rely upon the data received from Chainlink to be auditable and authentic. The design of Chaos Farm aims to protect the quality of the VRF output data through immutable patterns wherever possible and auditable events where restrictive patterns are less favorable than the features they disable (the ability to change the allowed caller account is a good example of this).

### Tools
- [Foundry](https://github.com/foundry-rs/foundry)
- [Chainlink Brownie Contracts](https://github.com/smartcontractkit/chainlink-brownie-contracts)
