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

deploy_contract() {
  #echo "HERE"
  #echo "$4"
  readarray -t contract_deploy < <(
    forge create \
    --rpc-url "$1" \
    --constructor-args "$2" "$3" \
    --private-key "$4" \
    test/mocks/MockVRFCoordinatorV2.sol:VRFCoordinatorV2Mock
  )

  echo "$(contract_address "${contract_deploy[@]}")"
}

# Sends a transaction. First parameter in the expansion is the contract,
# second parameter is the method to call and the others are the method params.
send_tx() {
  local result=$(cast send "$1" "$2" "${@:3}" ${TX_FLAGS} | jq -r '.status')

  if [ $result != ${TX_SUCCESS} ]
  then
    echo -e "${RED}ERROR: tx failed. ${LT_BLUE}cast send ${VRF_CONTRACT} ${LT_GREEN}${@}${NC}"
    exit 1
  fi
}
