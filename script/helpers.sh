#
# Environment
#

RED='\033[0;31m'
LT_BLUE='\033[1;34m'
LT_GREEN='\033[1;32m'
NC='\033[0m'

# Anvil node
RPC_URL='http://127.0.0.1:8545'
# Max Gas per VRF service call
GAS_LIMIT=1000000
# First default address and private key from Anvil
OWNER_ADDRESS='0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
# Default flags for sending transactions via Cast
TX_FLAGS="--from ${OWNER_ADDRESS} --gas-limit ${GAS_LIMIT} --rpc-url ${RPC_URL} --json"
# Success value for transaction output
TX_SUCCESS='0x1'

# Deploy a contract.
#
# Input parameters:
#   1. The URL of the network to deploy upon: 'http://127.0.0.1:8545'
#   2. The arguments for the contract constructor. These can be a string with spaces
#      like '0x...ef 1 0x...E5 6 10000000 3'
#   3. The private key for the transaction: 0x...80
#   4. The path and contract name to deploy: 'src/Chaos.sol:Chaos'
#
deploy_contract() {
  readarray -t contract_deploy < <(
    forge create \
    --rpc-url $1 \
    --constructor-args $2 \
    --private-key $3 \
    $4
  )

  echo "$(contract_address "${contract_deploy[@]}")"
}

# Send a transaction.
#
# Input parameters:
#   1. The address of the contract to call: 0x..27
#   2. The contract method to call: 'rolldice(address)'
#   3. The contract method parameters collected as overloaded inputs: '1 $SOME_VAR [1,2,3]'
send_tx() {
  local result=$(cast send "$1" "$2" "${@:3}" ${TX_FLAGS} | jq -r '.status')

  if [ $result != ${TX_SUCCESS} ]
  then
    echo -e "${RED}ERROR: tx failed. ${LT_BLUE}cast send ${VRF_CONTRACT} ${LT_GREEN}${@}${NC}"
    exit 1
  fi
}

# Verify script dependencies are installed
check_dependencies() {
  if [ $(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo -e "This script requires ${LT_BLUE}jq${NC}, install it and try again."
    exit 1
  fi
}

#
# Private Functions
#

# Extracts the contract address from forge deployment terminal output
contract_address() {
  for line in "$@";
  do
    if grep -q 'Deployed to: ' <<< $line; then

      # Remove the prefix from the deployed contract address
      echo "${line#'Deployed to: '}"
    fi
  done
}
