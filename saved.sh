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




"${BITCOIN_PATH}/bitcoin-cli" \
    ${RPC_CONF} \
    -rpcwallet="${WALLET}" \
    -rpcclienttimeout=0 \
    importdescriptors "$CONTENTS"

