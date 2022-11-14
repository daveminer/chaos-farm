#!/bin/bash

# First default address and private key from Anvil
OWNER_ADDRESS=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
OWNER_SECRET=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Match the prefix of the forge deployment output that contains
# the contract address.
#FORGE_DEPLOY_ADDRESS_KEY='Deployed to: '
# Fee for a VRF service request: .1 LINK
BASE_FEE=100000000000000
# Max Gas per VRF service call
GAS_PRICE_LINK=10000000000

RPC_URL=http://127.0.0.1:8545

contract_address() {
  for line in "$@";
  do
    if grep -q 'Deployed to: ' <<< $line; then

      # Remove the prefix from the deployed contract address
      echo "${line#'Deployed to: '}"
    fi
  done
}

# Set the owner account variables
#read -p "Enter the owner address you wish to use : " OWNER_ADDRESS
#read -p "Enter the private key for the previous address:" OWNER_SECRET

#IFS=$'\n'

# Deploy the VRF contract and save the output for the contract address
readarray -t vrf_deploy < <(
  forge create \
  --rpc-url $RPC_URL \
  --constructor-args $BASE_FEE $GAS_PRICE_LINK \
  --private-key $OWNER_SECRET \
  test/mocks/MockVRFCoordinatorV2.sol:VRFCoordinatorV2Mock
)

# for deploy_line in ${vrf_deploy[@]}
# do
#   if grep -q $FORGE_DEPLOY_ADDRESS_KEY <<< $deploy_line; then
#     # Remove the prefix from the deployed contract address
#     VRF_CONTRACT=${deploy_line#"$FORGE_DEPLOY_ADDRESS_KEY"}
#   fi
# done
VRF_CONTRACT=$(contract_address "${vrf_deploy[@]}")

cast send $VRF_CONTRACT "createSubscription()(uint64)" --from $OWNER_ADDRESS --gas-limit 1000000 --rpc-url $RPC_URL

cast send $VRF_CONTRACT "fundSubscription(uint64, uint96)" 1 1000000000000000000 --from $OWNER_ADDRESS --gas-limit 1000000 --rpc-url $RPC_URL

readarray -t chaos_deploy < <(
  forge create \
  --rpc-url $RPC_URL \
  --constructor-args "0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef" \
  1 \
  $VRF_CONTRACT \
  6 \
  10000000 \
  3 \
  --private-key $OWNER_SECRET \
  src/Chaos.sol:Chaos
)

echo "CHAOS DEPLOY"
echo ${chaos_deploy[3]}

CHAOS_CONTRACT=$(contract_address "${chaos_deploy[@]}")
# for deploy_line in ${chaos_deploy[@]}
# do
#   if grep -q $FORGE_DEPLOY_ADDRESS_KEY <<< $deploy_line; then
#     # Remove the prefix from the deployed contract address
#     CHAOS_CONTRACT=${deploy_line#"$FORGE_DEPLOY_ADDRESS_KEY"}
#   fi
# done
echo "CHAOSSSSS"
echo $CHAOS_CONTRACT

cast send $VRF_CONTRACT "addConsumer(uint64, address)" 1 $CHAOS_CONTRACT --from $OWNER_ADDRESS --gas-limit 1000000 --rpc-url $RPC_URL

cast send $CHAOS_CONTRACT "setAllowedCaller(address)" $OWNER_ADDRESS --from $OWNER_ADDRESS --gas-limit 1000000 --rpc-url $RPC_URL

cast send $CHAOS_CONTRACT "rollDice(address)" $OWNER_ADDRESS --from $OWNER_ADDRESS --gas-limit 1000000 --rpc-url $RPC_URL

# readarray -t roll_result < <(
#   cast send $CHAOS_CONTRACT "rollDice(address)" $OWNER_ADDRESS --from $OWNER_ADDRESS --gas-limit 1000000 --rpc-url $RPC_URL
# )

# for deploy_line in ${readarray[@]}
# do
#   echo $deploy_line
#   if grep -q $FORGE_DEPLOY_ADDRESS_KEY <<< $deploy_line; then
#     # Remove the prefix from the deployed contract address
#     CHAOS_CONTRACT=${ploy_line#"$FORGE_DEPLOY_ADDRESS_KEY"}
#   fi
# done

cast call $CHAOS_CONTRACT "lastRoll(address)(uint[])" $OWNER_ADDRESS --rpc-url $RPC_URL

#cast send $VRF_CONTRACT --from $OWNER_ADDRESS --value 1ether --rpc-url $RPC_URL
#cast send $VRF_CONTRACT "" --from $OWNER_ADDRESS --value 1ether --rpc-url $RPC_URL


#cast call $VRF_CONTRACT "fulfillRandomWords(uint256)(address)" 1 $OWNER_ADDRESS --rpc-url $RPC_URL
cast send $VRF_CONTRACT "fulfillRandomWordsWithOverride(uint256, address, uint256[])" 1 $CHAOS_CONTRACT [1,2,3,4,5,6] --from $OWNER_ADDRESS --gas-limit 1000000 --rpc-url $RPC_URL

cast call $CHAOS_CONTRACT "lastRoll(address)(uint[])" $OWNER_ADDRESS --rpc-url $RPC_URL
