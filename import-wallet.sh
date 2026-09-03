#!/bin/bash

source functions.sh

CONFIG_FILE=".bitcoin-utilities.sh"
if [ -e "${CONFIG_FILE}" ]
then
	source "${CONFIG_FILE}"
fi

# Set default values
FILENAME="keys.txt"
CONTENTS=""
WALLET=""
REQUEST=""
BLOCK_HEIGHT=""
DEBUG=0
RPC_CONF=""
USAGE_STRING="[-w] wallet [-f] filename [-p] Bitcoin path [-P] passphrase [-t] block height [-h] help"

HandleArguments "$@"
CheckRPC

if (( DEBUG ))
then    
	echo "Debug is enabled."
fi

CheckImportParameters "$WALLET" "$PASSPHRASE"

# Setup timestamp from BLOCK_HEIGHT
if [ -z $BLOCK_HEIGHT ]
then
    BLOCK_HEIGHT=0
    TIMESTAMP=0
else
#    BLOCK_HEIGHT=$2
    # Set up timestamp based on BLOCK_HEIGHT
    HASH=$(${BITCOIN_PATH}/bitcoin-cli ${RPC_CONF}  getblockhash ${BLOCK_HEIGHT})
    TIMESTAMP=$(${BITCOIN_PATH}/bitcoin-cli ${RPC_CONF} getblockheader ${HASH} true | jq -r .time)
fi	

if (( DEBUG ))
then    
	DisplayValues
fi

echo "Creating new wallet $WALLET, HEIGHT: ${BLOCK_HEIGHT} TIMESTAMP: ${TIMESTAMP}"

# Create a new wallet
if ! ${BITCOIN_PATH}/bitcoin-cli ${RPC_CONF} -named createwallet \
  wallet_name="${WALLET}" \
  disable_private_keys=false \
  blank=false \
  passphrase="${PASSPHRASE}" \
  avoid_reuse=false \
  descriptors=true \
  load_on_startup=true \
  external_signer=false
then
	echo 
	echo "Unable to create wallet ${WALLET}. Import unsuccessful." >&2
	exit 1
fi

# Send the wallet passphrase 
${BITCOIN_PATH}/bitcoin-cli ${RPC_CONF} -rpcwallet=${WALLET} walletpassphrase ${PASSPHRASE} 120

# Check if the file contains a JSON array
if grep -qE '^\s*\[\s*([^{[]|[^}])*$' "$FILENAME" 2>/dev/null; then
    # If JSON array, try to validate
    if jq empty "$FILENAME" >/dev/null 2>&1; then
        # Read the entire file into CONTENTS variable and pass to doSomething
        CONTENTS=$(cat "$FILENAME")
    fi
else
    # Process each line of file
    while IFS= read -r line || [[ -n "$line" ]]; do

		if [ -z "$line" ]
		then
			echo "Skipping blank line in ${FILENAME}" >&2
			continue
		fi

		# Get checksum
        checksum=$(echo $(${BITCOIN_PATH}/bitcoin-cli ${RPC_CONF} -rpcwallet=${WALLET} getdescriptorinfo \
			"combo(${line})") | jq -r '.checksum')

        if [ -n "$CONTENTS" ]
        then
            CONTENTS+=','
        fi
        CONTENTS+=$(printf '{"desc":"combo(%s)#%s","timestamp":%s}' "$line" "$checksum" "$TIMESTAMP")

    done < "$FILENAME"

    CONTENTS="[${CONTENTS}]"

fi

"${BITCOIN_PATH}/bitcoin-cli" \
	${RPC_CONF} \
    -rpcwallet="${WALLET}" \
    -rpcclienttimeout=0 \
    importdescriptors "$CONTENTS"


