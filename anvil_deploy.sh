#!/bin/bash

# Anvil node
RPC_URL=http://127.0.0.1:8545

DEPLOYMENT_CONFIRMATIONS=3
# Max Gas per VRF service call
GAS_PRICE_LINK=10000000000
GAS_LIMIT=1000000
# Fee for a VRF service request: .1 LINK
BASE_FEE=100000000000000
# Arbitrary amount of LINK to fund the subscription with for VRF requests.
LINK_FUND_AMT=1000000000000000000
# First default address and private key from Anvil
OWNER_ADDRESS=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
OWNER_SECRET=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

TX_FLAGS="--from ${OWNER_ADDRESS} --gas-limit ${GAS_LIMIT} --rpc-url ${RPC_URL} --json"

echo FLAGS
echo $TX_FLAGS

# Helper function extracts the contract address from forge deployment terminal output
contract_address() {
  for line in "$@";
  do
    if grep -q 'Deployed to: ' <<< $line; then

      # Remove the prefix from the deployed contract address
      echo "${line#'Deployed to: '}"
    fi
  done
}

# First parameter in the expansion is the contract method to call,
# the others are the method params.

send_tx() {
  local result=$(cast send ${VRF_CONTRACT} ${@} ${TX_FLAGS} | jq -r '.status')
  echo RESULT
  echo $result

  if [ $result != "0x1" ]
  then
    echo ERROR: tx failed. \"cast send "$VRF_CONTRACT" "$@"\"
  fi
}

echo "Deploying the VRF contract..."

readarray -t vrf_deploy < <(
  forge create \
  --rpc-url $RPC_URL \
  --constructor-args $BASE_FEE $GAS_PRICE_LINK \
  --private-key $OWNER_SECRET \
  test/mocks/MockVRFCoordinatorV2.sol:VRFCoordinatorV2Mock
)
VRF_CONTRACT=$(contract_address "${vrf_deploy[@]}")

echo "VRF contract deployed to: ${VRF_CONTRACT}"

# Create a subscription on the deployed VRF contract
send_tx "createSubscription()(uint64)"

#cast send $VRF_CONTRACT "createSubscription()(uint64)" $TX_FLAGS

# # Fund the subsciption with test LINK
cast send $VRF_CONTRACT "fundSubscription(uint64, uint96)" 1 $LINK_FUND_AMT $TX_FLAGS

# Deploy Chaos Farm
readarray -t chaos_deploy < <(
  forge create \
  --rpc-url $RPC_URL \
  --constructor-args "0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef" \
  1 \
  $VRF_CONTRACT \
  6 \
  10000000 \
  $DEPLOYMENT_CONFIRMATIONS \
  --private-key $OWNER_SECRET \
  src/Chaos.sol:Chaos
)
CHAOS_CONTRACT=$(contract_address "${chaos_deploy[@]}")

# # Add the Chaos Farm contract as a consumer address to the VRF contract
add_consumer_result = cast send $VRF_CONTRACT "addConsumer(uint64, address)" 1 $CHAOS_CONTRACT $TX_FLAGS | jq -r '.status'
if add_consumer_result


# # Set the Owner address as the Allowed Caller for the Chaos Farm contract
# cast send $CHAOS_CONTRACT "setAllowedCaller(address)" $OWNER_ADDRESS $TX_FLAGS

# # Owner initiates a VRF request via Chaos Farm API
# cast send $CHAOS_CONTRACT "rollDice(address)" $OWNER_ADDRESS $TX_FLAGS

# # Output the last roll to verify it's a roll in progress, i.e. [0,0,0,0,0,0]
# cast call $CHAOS_CONTRACT "lastRoll(address)(uint[])" $OWNER_ADDRESS --rpc-url $RPC_URL

# # Simulate the callback returning the random numbers; pass in fixed values
# cast send $VRF_CONTRACT "fulfillRandomWordsWithOverride(uint256, address, uint256[])" 1 $CHAOS_CONTRACT [1,2,3,4,5,6] $TX_FLAGS

# # Output the last roll again to show it's complete and contains the fixed values from the previous step.
# cast call $CHAOS_CONTRACT "lastRoll(address)(uint[])" $OWNER_ADDRESS --rpc-url $RPC_URL
