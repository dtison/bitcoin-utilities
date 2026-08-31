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
FILENAME="keys.txt"
CONTENTS=""
WALLET=""
REQUEST=""
BLOCK_HEIGHT=""
DEBUG=0
USAGE_STRING="[-w] wallet [-f] filename [-p] Bitcoin path [-P] passphrase [-t] block height [-h] help"

HandleArguments "$@"

if (( DEBUG ))
then    
	echo "Debug is enabled."
fi


# Setup timestamp from BLOCK_HEIGHT
if [ -z $BLOCK_HEIGHT ]
then
    BLOCK_HEIGHT=0
    TIMESTAMP=0
else
#    BLOCK_HEIGHT=$2
    # Set up timestamp based on BLOCK_HEIGHT
    HASH=$(${BITCOIN_PATH}/bitcoin-cli getblockhash ${BLOCK_HEIGHT})
    TIMESTAMP=$(${BITCOIN_PATH}/bitcoin-cli getblockheader ${HASH} true | jq -r .time)
fi	

CheckImportParameters $WALLET $FILENAME $PASSPHRASE 

if (( DEBUG ))
then    
	DisplayValues
fi

echo "Creating new wallet $WALLET, HEIGHT: ${BLOCK_HEIGHT} TIMESTAMP: ${TIMESTAMP}"

# Create a new wallet
if ! ${BITCOIN_PATH}/bitcoin-cli -named createwallet \
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
${BITCOIN_PATH}/bitcoin-cli -rpcwallet=${WALLET} walletpassphrase ${PASSPHRASE} 120


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
        checksum=$(echo $(${BITCOIN_PATH}/bitcoin-cli -rpcwallet=${WALLET} getdescriptorinfo  "combo(${line})") | jq -r '.checksum')

        if [ -z "$CONTENTS" ]; then

            CONTENTS=$(cat <<EOF
            {
                "desc": "combo(${line})#${checksum}",
                "timestamp": ${TIMESTAMP} 
            }
EOF
        )
        else
            CONTENTS+=','
            CONTENTS+=$(cat <<EOF
            {
                "desc": "combo(${line})#${checksum}",
                "timestamp": ${TIMESTAMP}
            }
EOF
        )
        fi

    done < "$FILENAME"

    # Add the JSON array brackets
    CONTENTS=$(cat <<EOF
    [
    ${CONTENTS}
    ]
EOF
    )

fi

#echo "$CONTENTS"
#exit

"${BITCOIN_PATH}/bitcoin-cli" \
    -rpcwallet="${WALLET}" \
    -rpcclienttimeout=0 \
    importdescriptors "$CONTENTS"


