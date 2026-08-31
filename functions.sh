CheckArguments() {
	if [ $# -eq 0 ]
	then
		Usage;
	fi
}

DisplayConfigRequired() {
    echo
    echo "Create a file named .bitcoin-utilities.sh with contents:"
    echo
    echo "BITCOIN_PATH='path/to/bitcoin-executables'"
    echo "PASSPHRASE='<wallet-passphrase>'"
    echo
}

Usage() {
	echo
	#echo "Usage: $0 [-w] wallet [-f] filename [-p] Bitcoin path [-P] passphrase [-t] block height [-h] help " 
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
	FILENAME=$2
	PASSPHRASE=$3

	if [ -z $WALLET ]
	then
		echo " Error: Wallet name is required for import. Use -w <wallet>"
		exit 1
	fi 
	if [ -z $FILENAME ]
	then
		echo " Error: File name is required for import."
		exit 1
	fi 
	if [ -z $PASSPHRASE ]
	then
		echo " Error: Passphrase is required for import."
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
