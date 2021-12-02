#!/usr/bin/env bash
#
# Create the genesis file for the Sophie testnet, and the different keys that
# the nodes use.
#
# Keys and genesis files are placed in the `keys` directory.
#
# This script requires the following environment variables to be defined:
#
# - NB_BFT_NODES: number of BFT nodes
# - NB_POOL_NODES: number of staking pool nodes
# - K: the security parameter for the network
# - F: the active slot coefficient
# - MAX_SUPPLY: total entropic supply
#
set -euo pipefail

cd "$(dirname "$0")/.."

[ -z ${NB_BFT_NODES+x} ] && (echo "Environment variable NB_BFT_NODES must be defined"; exit 1)
[ -z ${NB_POOL_NODES+x} ] && (echo "Environment variable NB_POOL_NODES must be defined"; exit 1)
[ -z ${K+x} ] && (echo "Environment variable K must be defined"; exit 1)
[ -z ${F+x} ] && (echo "Environment variable F must be defined"; exit 1)
[ -z ${MAX_SUPPLY+x} ] && (echo "Environment variable MAX_SUPPLY must be defined"; exit 1)
[ -z ${SLOT_LENGTH+x} ]&& ( echo "Environment variable SLOT_LENGTH must be defined"; exit 1)
[ -z ${NETWORK_MAGIC+x} ]&& ( echo "Environment variable NETWORK_MAGIC must be defined"; exit 1)

export NB_CORE_NODES=$(($NB_BFT_NODES + $NB_POOL_NODES))
DELAY="${DELAY:-30}"
UTXO_KEYS="${UTXO_KEYS:-3}"
DPARAM="${DPARAM:-$(awk "BEGIN{print 1.0 - 1.0 * $NB_POOL_NODES / $NB_CORE_NODES}")}"

echo "Generating new genesis and keys using following environments variables:

 NB_BFT_NODES=$NB_BFT_NODES (number of bft core nodes)
 NB_POOL_NODES=$NB_POOL_NODES (number of staking pool nodes)
 K=$K (Security parameter)
 F=$F (Active slots coefficient)
 MAX_SUPPLY=$MAX_SUPPLY (Max Entropic supply)
 SLOT_LENGTH=$SLOT_LENGTH
 NETWORK_MAGIC=$NETWORK_MAGIC
 DELAY=$DELAY (delay in minutes before genesis systemStart)
 DPARAM=$DPARAM (decentralization parameter)
 DOMAIN=$DOMAIN
 RELAYS=$RELAYS
"

mkdir -p keys
cd keys

if [ -f "$GENESIS_PATH" ]; then
  cat $GENESIS_PATH > ./genesis.spec.json
fi

SYSTEM_START=`date -u -d "today + $DELAY minutes" +'%Y-%m-%dT%H:%M:%SZ'`

# Customize the genesis template file
#
# The epoch length must satisfy:
#
#    10 * securityParam / activeSlotsCoeff <= epochLength
#
# so we set the epoch length to exactly the value of the left hand side of the
# inequality.
EPOCH_LENGTH=`perl -E "say ((10 * $K) / $F)"`

if [ $NB_BFT_NODES -lt 1 ]; then
  GENKEYS=1
else
  GENKEYS=$NB_BFT_NODES
fi


# jq will convert the big nunbers to scientific notation, and old versions of
# nix cannot handle this. Hence we need to use sed.
sed -Ei "s/^([[:blank:]]*\"updateQuorum\":)([[:blank:]]*[^,]*,)$/\1 $GENKEYS,/" genesis.spec.json
sed -Ei "s/^([[:blank:]]*\"epochLength\":)([[:blank:]]*[^,]*,)$/\1 $EPOCH_LENGTH,/" genesis.spec.json
sed -Ei "s/^([[:blank:]]*\"slotLength\":)([[:blank:]]*[^,]*,)$/\1 $SLOT_LENGTH,/" genesis.spec.json
sed -Ei "s/^([[:blank:]]*\"securityParam\":)([[:blank:]]*[^,]*)$/\1 $K/" genesis.spec.json
sed -Ei "s/^([[:blank:]]*\"activeSlotsCoeff\":)([[:blank:]]*[^,]*,)$/\1 $F,/" genesis.spec.json
sed -Ei "s/^([[:blank:]]*\"networkMagic\":)([[:blank:]]*[^,]*,)$/\1 $NETWORK_MAGIC,/" genesis.spec.json
sed -Ei "s/^([[:blank:]]*\"decentralisationParam\":)([[:blank:]]*[^,]*)$/\1 $DPARAM/" genesis.spec.json

bcc-cli genesis create-staked \
            --genesis-dir . \
            --supply $(((2 * $MAX_SUPPLY) / 3 - ($NB_POOL_NODES * $MAX_SUPPLY / 500))) \
            --supply-delegated $(($NB_POOL_NODES * $MAX_SUPPLY / 500)) \
            --gen-genesis-keys $NB_BFT_NODES \
            --gen-pools $NB_POOL_NODES \
            --gen-stake-delegs $NB_POOL_NODES \
            --gen-utxo-keys $UTXO_KEYS \
            --start-time $SYSTEM_START \
            --testnet-magic $NETWORK_MAGIC

sed -Ei "s/^([[:blank:]]*\"maxEntropicSupply\":)([[:blank:]]*[^,]*,)$/\1 $MAX_SUPPLY,/" genesis.json

bcc-cli genesis hash --genesis genesis.json > GENHASH
bcc-cli genesis hash --genesis genesis.aurum.json > AURUMGENHASH


for i in `seq 1 $NB_POOL_NODES`; do

  # Stake addresses registration certs
  bcc-cli stake-address registration-certificate \
    --stake-verification-key-file stake-delegator-keys/staking$i.vkey \
    --out-file stake-delegator-keys/staking$i.reg.cert

  bcc-cli stake-address registration-certificate \
    --stake-verification-key-file pools/staking-reward$i.vkey \
    --out-file pools/staking-reward$i.reg.cert

  # Stake address delegation certs
  bcc-cli stake-address delegation-certificate \
    --stake-verification-key-file stake-delegator-keys/staking$i.vkey  \
    --cold-verification-key-file pools/cold$i.vkey \
    --out-file stake-delegator-keys/staking$i.deleg.cert

  bcc-cli address build \
    --payment-verification-key-file stake-delegator-keys/payment$i.vkey \
    --stake-verification-key-file stake-delegator-keys/staking$i.vkey \
    --out-file stake-delegator-keys/staking$i.addr \
    --testnet-magic $NETWORK_MAGIC

  METADATA="../static/pool-metadata/p/$i.json"
  METADATA_URL="https://monitoring.$DOMAIN/p/$i.json"
  TICKER=$(jq -r '.ticker' < $METADATA)
  RELAY="$(echo "$TICKER" | tr '[:upper:]' '[:lower:]').$RELAYS"

  # stake pool registration cert
  bcc-cli stake-pool registration-certificate \
    --testnet-magic $NETWORK_MAGIC \
    --pool-pledge $(($MAX_SUPPLY / 500)) \
    --pool-cost $(( 1000000000 - ($i * 500000000 / $NB_POOL_NODES))) --pool-margin 0.0$i \
    --cold-verification-key-file             pools/cold$i.vkey \
    --vrf-verification-key-file              pools/vrf$i.vkey \
    --reward-account-verification-key-file   pools/staking-reward$i.vkey \
    --pool-owner-stake-verification-key-file stake-delegator-keys/staking$i.vkey \
    --out-file                               pools/pool$i.reg.cert \
    --single-host-pool-relay $RELAY \
    --pool-relay-port 3001 \
    --metadata-url $METADATA_URL \
    --metadata-hash $(bcc-cli stake-pool metadata-hash --pool-metadata-file $METADATA)
done

for i in `seq 1 $UTXO_KEYS`; do

  bcc-cli address build \
    --payment-verification-key-file utxo-keys/utxo$i.vkey \
    --out-file utxo-keys/utxo$i.addr \
    --testnet-magic $NETWORK_MAGIC

done

if [ -f $COLE_GENESIS_PATH ]; then

  jq '.blockVersionData' \
  < $COLE_GENESIS_PATH \
  > ./cole-genesis.spec.json

  sed -Ei "s/^([[:blank:]]*\"slotLength\":)([[:blank:]]*[^,]*,)$/\1 $SLOT_LENGTH,/" genesis.json

  rm -rf cole

  bcc-cli cole genesis genesis \
    --protocol-magic $NETWORK_MAGIC \
    --start-time `date +\%s -d "$SYSTEM_START"` \
    --k $K \
    --n-poor-addresses 0 \
    --n-delegate-addresses $NB_BFT_NODES \
    --total-balance $MAX_SUPPLY \
    --delegate-share $(awk "BEGIN{print 2 / 3}") \
    --avvm-entry-count 0 \
    --avvm-entry-balance 0 \
    --protocol-parameters-file cole-genesis.spec.json \
    --genesis-output-dir cole

  bcc-cli cole genesis print-genesis-hash --genesis-json cole/genesis.json > cole/GENHASH

  # Create keys, addresses and transactions to withdraw the initial UTxO into
  # regular addresses.
  bcc-cli cole key keygen \
    --secret cole/rich.key \

  bcc-cli cole key signing-key-address \
    --testnet-magic $NETWORK_MAGIC \
    --secret cole/rich.key > cole/rich.addr

  bcc-cli key convert-cole-key \
    --cole-signing-key-file cole/rich.key \
    --out-file cole/rich-converted.key \
    --cole-payment-key-type

  for N in `seq 1 $NB_BFT_NODES`; do

    bcc-cli cole key signing-key-address \
      --testnet-magic $NETWORK_MAGIC \
      --secret cole/genesis-keys.00$((${N} - 1)).key > cole/genesis-address-00$((${N} - 1))

    rm -f tx$N.tx

    bcc-cli cole transaction issue-genesis-utxo-expenditure \
      --genesis-json cole/genesis.json \
      --testnet-magic $NETWORK_MAGIC \
      --tx tx$N.tx \
      --wallet-key cole/delegate-keys.00$((${N} - 1)).key \
      --rich-addr-from "$(head -n 1 cole/genesis-address-00$((${N} - 1)))" \
      --txout "(\"$(head -n 1 cole/rich.addr)\", $(($MAX_SUPPLY * 2 / ($NB_BFT_NODES * 3))))"
  done

bcc-cli transaction build-raw \
  --sophie-era \
  --ttl 10000000000 \
  --fee $((100000 * $NB_POOL_NODES)) \
  $(for i in `seq 1 $NB_BFT_NODES`; do
    echo " --tx-in $(bcc-cli cole transaction txid --tx tx$i.tx)#0"
  done) \
  $(for i in `seq 1 $UTXO_KEYS`; do
    echo " --tx-out $(cat utxo-keys/utxo$i.addr)+$((((2 * $MAX_SUPPLY) / 3  - (100000 + 504000000 + $MAX_SUPPLY / 500) * $NB_POOL_NODES) / $UTXO_KEYS))"
  done) \
  $(for i in `seq 1 $NB_POOL_NODES`; do
    echo " --tx-out $(cat stake-delegator-keys/staking$i.addr)+$(($MAX_SUPPLY / 500))"
    echo " --certificate-file pools/staking-reward$i.reg.cert"
    echo " --certificate-file pools/pool$i.reg.cert"
    echo " --certificate-file stake-delegator-keys/staking$i.reg.cert"
    echo " --certificate-file stake-delegator-keys/staking$i.deleg.cert"
  done) \
  --out-file tx2.txbody


bcc-cli transaction sign \
  --signing-key-file cole/rich-converted.key \
  $(for i in `seq 1 $NB_POOL_NODES`; do
    echo " --signing-key-file stake-delegator-keys/payment$i.skey"
    echo " --signing-key-file stake-delegator-keys/staking$i.skey"
    echo " --signing-key-file pools/staking-reward$i.skey"
    echo " --signing-key-file pools/cold$i.skey"
  done) \
  --testnet-magic $NETWORK_MAGIC \
  --tx-body-file  tx2.txbody \
  --out-file      tx2.tx
fi



mkdir -p node-keys
cd node-keys
# Link VRF keys for the BFT nodes.
for i in `seq 1 $NB_BFT_NODES`; do
  ln -sf ../delegate-keys/delegate$i.vrf.skey node-vrf$i.skey
  ln -sf ../delegate-keys/delegate$i.kes.skey node-kes$i.skey
  ln -sf ../delegate-keys/opcert$i.cert node$i.opcert
done
# Link VRF keys for the staking pool nodes.
for p in `seq 1 $NB_POOL_NODES`; do
  i=$(($NB_BFT_NODES+p))
  ln -sf ../pools/vrf$p.skey node-vrf$i.skey
  ln -sf ../pools/kes$p.skey node-kes$i.skey
  ln -sf ../pools/opcert$p.cert node$i.opcert
done
# TODO fix script:
#../../scripts/renew-kes-keys.sh 0
#
