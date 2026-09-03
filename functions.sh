Usage() {
	echo
	echo "Usage: $0 ${USAGE_STRING} " 
	echo
	exit 1
}

HandleArguments() {
    local OPTIND OPTARG OPTION

    while getopts 'w:f:p:P:t:hd' OPTION; do
        case "$OPTION" in
            w) WALLET=$OPTARG ;;
            f) FILENAME=$OPTARG ;;
            P) PASSPHRASE=$OPTARG ;;
            p) BITCOIN_PATH=$OPTARG ;;
            t) BLOCK_HEIGHT=$OPTARG ;;
			d) DEBUG=1 ;;
            h) Usage  ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument" >&2
                return 1
                ;;
        esac
    done

    # Optional: arguments after the options
    shift "$((OPTIND - 1))"
    remaining_args=( "$@" )
}

CheckImportParameters() {
	WALLET=$1
	PASSPHRASE=$2
	HELP_STRING="Use $0 -h for help"

	if [ -z "$WALLET" ]
	then
		printf "\n%s\n%s\n\n" "Error: Wallet name is required for import." "${HELP_STRING}" 
		exit 1
	fi 

	if [ -z "$PASSPHRASE" ]
	then
		printf "\n%s\n%s\n\n" "Error: Passphrase is required for import." "${HELP_STRING}" 
		exit 1
	fi 
}

CheckListDescriptorParameters() {
	WALLET=$1
	PASSPHRASE=$2
	HELP_STRING="Use $0 -h for help"

	if [ -z "$WALLET" ]
	then
		printf "\n%s\n%s\n\n" "Error: Wallet name is required for export." "${HELP_STRING}" 
		exit 1
	fi 

    if [ -z "$PASSPHRASE" ]
    then
        printf "\n%s\n%s\n\n" "Error: Passphrase is required for export." "${HELP_STRING}"
        exit 1
    fi
}

DisplayValues() {

	echo "Wallet [${WALLET}]"
	echo "Filename [${FILENAME}]"
	echo "Passphrase [${PASSPHRASE}]"
	echo "Bitcoin Path [${BITCOIN_PATH}]"
	echo "Block Height [${BLOCK_HEIGHT}]"
	echo "Timestamp [${TIMESTAMP}]"
}

CheckRPC() {
	# Support rpc via rpc.conf if file exists
	if [ -f rpc.conf ]
	then
    	RPC_CONF="-conf=$(pwd)/rpc.conf"
	fi
}
