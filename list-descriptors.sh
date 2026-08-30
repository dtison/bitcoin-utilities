#!/bin/bash

source functions.sh

CONFIG_FILE=".bitcoin-utilities.sh"
if [ ! -e "${CONFIG_FILE}" ]
then
    DisplayConfigRequired
    exit
fi

source "${CONFIG_FILE}"
CheckArguments $1

# Set default values
DEBUG=0
USAGE_STRING="[-w] wallet  [-p] Bitcoin path [-P] passphrase  [-h] help"
HandleArguments "$@"

## Check if wallet is loaded, and load if not
if ! ${BITCOIN_PATH}/bitcoin-cli listwallets | jq -e --arg wallet "$WALLET" 'index($wallet) != null' >/dev/null
then    
	if ! ${BITCOIN_PATH}/bitcoin-cli loadwallet "$WALLET" >&2
	then
		echo "Error loading wallet ${WALLET}" >&2
		exit 1
	fi
fi

# Send wallet passphrase 
${BITCOIN_PATH}/bitcoin-cli -rpcwallet=${WALLET} walletpassphrase ${PASSPHRASE} 120

# Display descriptors
printf "%s\n" "$(${BITCOIN_PATH}/bitcoin-cli -rpcwallet=${WALLET} listdescriptors true | jq -r '.descriptors') "




