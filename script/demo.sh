#!/bin/bash

###############
# Demo Script #
###############

# Run this script to see an example of the contract in action. This script deploys
# the mock VRF and Chaos Farm contracts to a running instance of Anvil. Afterwards
# it will interact with the contract in the terminal via cast.

# Import helpers
HELPERS_PATH=$(find . -name "helpers.sh")
source ${HELPERS_PATH}

#
# Environment
#

# Anvil node
RPC_URL='http://127.0.0.1:8545'

# The number of words to request with each service call
VRF_WORD_COUNT=6
# Wait this many confirmations for a deployment to be considered completed.
DEPLOYMENT_CONFIRMATIONS=3
# The base cost for a VRF call in LINK. The subscription must be loaded with enough
# LINK to pay at least this amount for each service request.
GAS_PRICE_LINK=10000000000
# Max Gas per VRF service call
GAS_LIMIT=1000000
# The the key hash of the gas lane  to use. This value is unused in the mock but
# must be set correctly for networks with a real VRF coordinator. Check the Chainlink
# documentation to choose the appropriate value per chain and gas priority.
GAS_LANE_KEY_HASH='0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef'
# The call will fail if it requires more gas than this
CALLBACK_GAS_LIMIT=10000000
# Fee for a VRF service request: .1 LINK
BASE_FEE=100000000000000
# Arbitrary amount of LINK to fund the subscription with for VRF requests.
LINK_FUND_AMT=1000000000000000000

# First default address and private key from Anvil
OWNER_ADDRESS='0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
OWNER_SECRET='0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

# The local path to the contract
VRF_CONTRACT_PATH='test/mocks/MockVRFCoordinatorV2.sol:VRFCoordinatorV2Mock'
CHAOS_FARM_CONTRACT_PATH='src/Chaos.sol:Chaos'

# Default flags for sending transactions via Cast
TX_FLAGS="--from ${OWNER_ADDRESS} --gas-limit ${GAS_LIMIT} --rpc-url ${RPC_URL} --json"


#
# Script
#

check_dependencies

echo "Deploying the VRF contract..."
VRF_CONTRACT_ARGS="${BASE_FEE} ${GAS_PRICE_LINK}"
VRF_CONTRACT=$(
  deploy_contract \
  $RPC_URL \
  "$VRF_CONTRACT_ARGS" \
  $OWNER_SECRET \
  $VRF_CONTRACT_PATH
)
echo "VRF contract deployed to: ${VRF_CONTRACT}"

echo "Creating a subscription on the VRF contract."
SUBSCRIPTION_ID=$(
  cast send \
  $VRF_CONTRACT \
    "createSubscription()(uint64)" \
    $TX_FLAGS |
      jq -r '.logs[0].topics[1]' |
      sed -e 's/0x//' -e 's/^[0]*//'
)

echo "Funding the VRF Subscription with LINK. Amt: ${LINK_FUND_AMT}"
send_tx $VRF_CONTRACT \
  "fundSubscription(uint64, uint96)" \
  $SUBSCRIPTION_ID \
  $LINK_FUND_AMT

echo "Deploying Chaos Farm..."
CHAOS_CONTRACT_ARGS="${GAS_LANE_KEY_HASH} \
                     ${SUBSCRIPTION_ID} \
                     ${VRF_CONTRACT} \
                     ${VRF_WORD_COUNT} \
                     ${CALLBACK_GAS_LIMIT} \
                     ${DEPLOYMENT_CONFIRMATIONS}"
CHAOS_CONTRACT=$(
  deploy_contract \
  $RPC_URL \
  "$CHAOS_CONTRACT_ARGS" \
  $OWNER_SECRET \
  $CHAOS_FARM_CONTRACT_PATH
)
echo "Chaos Farm contract deployed to: ${CHAOS_CONTRACT}"

echo "Adding the Chaos Farm contract as a Consumer on the VRF contract."
send_tx $VRF_CONTRACT \
  "addConsumer(uint64, address)" \
  $SUBSCRIPTION_ID \
  $CHAOS_CONTRACT

echo "Setting the owner address ${OWNER_ADDRESS} as the allowed caller."
send_tx $CHAOS_CONTRACT "setAllowedCaller(address)" $OWNER_ADDRESS

# Owner initiates a VRF request via Chaos Farm API
echo "Requesting VRF..."
send_tx $CHAOS_CONTRACT "rollDice(address)" $OWNER_ADDRESS

# Verify the last roll is in progress, i.e. [0,0,0,0,0,0]
echo "Roll is in progress: " \
  `cast call $CHAOS_CONTRACT \
    "lastRoll(address)(uint[])" \
    $OWNER_ADDRESS \
  --rpc-url $RPC_URL`

# Simulate the callback returning the random numbers; pass in fixed values
echo "Fulfilling VRF request through the Coordinator mock..."
send_tx $VRF_CONTRACT \
  "fulfillRandomWordsWithOverride(uint256, address, uint256[])" \
  1 \
  $CHAOS_CONTRACT \
  [1,2,3,4,5,6]

# Output the last roll again to show it's complete and
# contains the fixed values from the previous step.
echo "Roll is finished: " \
  `cast call $CHAOS_CONTRACT \
    "lastRoll(address)(uint[])" \
    $OWNER_ADDRESS \
  --rpc-url $RPC_URL`
