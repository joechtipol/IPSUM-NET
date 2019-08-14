#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts


# verify the result of the end-to-end test
verifyResult () {
  if [ $1 -ne 0 ] ; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
      exit 1
  fi
}

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
        CORE_PEER_LOCALMSPID="OrdererMSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ipsum.io/orderers/orderer.ipsum.io/msp/tlscacerts/tlsca.ipsum.io-cert.pem
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ipsum.io/users/Admin@ipsum.io/msp
}


setGlobals () {
  PEER=$1
  ORG=$2

  if [ ! $PEER -eq 0 ]; then
    echo "================== ERROR !!! Peer Unknown =================="
    exit -1
  fi

  if [ $ORG -eq 1 ] ; then
    CORE_PEER_LOCALMSPID="univ1MSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/univ1.ipsum.io/peers/peer0.univ1.ipsum.io/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/univ1.ipsum.io/users/Admin@univ1.ipsum.io/msp
    CORE_PEER_ADDRESS=peer0.univ1.ipsum.io:7051
  elif [ $ORG -eq 2 ] ; then
    CORE_PEER_LOCALMSPID="univ2MSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/univ2.ipsum.io/peers/peer0.univ2.ipsum.io/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/univ2.ipsum.io/users/Admin@univ2.ipsum.io/msp
    CORE_PEER_ADDRESS=peer0.univ2.ipsum.io:7051
  elif [ $ORG -eq 3 ] ; then
    CORE_PEER_LOCALMSPID="univ3MSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/univ3.ipsum.io/peers/peer0.univ3.ipsum.io/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/univ3.ipsum.io/users/Admin@univ3.ipsum.io/msp
    CORE_PEER_ADDRESS=peer0.univ3.ipsum.io:7051
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi

  env |grep CORE
}


chaincodeInvoke () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
  # lets supply it directly as we know it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
    peer chaincode invoke -o orderer.ipsum.io:7050 -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
    res=$?
                set +x
  else
                set -x
    peer chaincode invoke -o orderer.ipsum.io:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
    res=$?
                set +x
  fi
  cat log.txt
  verifyResult $res "Invoke execution on peer${PEER}.org${ORG} failed "
  echo "===================== Invoke transaction on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
  echo
}

## Sometimes Join takes time hence RETRY at least for 5 times
joinChannelWithRetry () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

        set -x
  peer channel join -b $CHANNEL_NAME.block  >&log.txt
  res=$?
        set +x
  cat log.txt
  if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
    COUNTER=` expr $COUNTER + 1`
    echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
    sleep $DELAY
    joinChannelWithRetry $PEER $ORG
  else
    COUNTER=1
  fi
  verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to Join the Channel"
}

installChaincode () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  VERSION=${3:-1.0}
        set -x
  peer chaincode install -n mycc -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} >&log.txt
  res=$?
        set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has Failed"
  echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
  echo
}

instantiateChaincode () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  VERSION=${3:-1.0}

  # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
  # lets supply it directly as we know it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
    peer chaincode instantiate -o orderer.ipsum.io:7050 -C $CHANNEL_NAME -n mycc -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init","a","100","b","200"]}' -P "OR  ('univ1MSP.peer','univ2MSP.peer','univ3MSP.peer')" >&log.txt
    res=$?
                set +x
  else
                set -x
    peer chaincode instantiate -o orderer.ipsum.io:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -l ${LANGUAGE} -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('univ1MSP.peer','univ2MSP.peer','univ3MSP.peer')" >&log.txt
    res=$?
                set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode Instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
  echo
}

upgradeChaincode () {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    set -x
    peer chaincode upgrade -o orderer.ipsum.io:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('univ1MSP.peer','univ2MSP.peer','univ3MSP.peer')"
    res=$?
  set +x
    cat log.txt
    verifyResult $res "Chaincode upgrade on org${ORG} peer${PEER} has Failed"
    echo "===================== Chaincode is upgraded on org${ORG} peer${PEER} ===================== "
    echo
}

chaincodeQuery () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  EXPECTED_RESULT=$3
  echo "===================== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
     set -x
     peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
   res=$?
     set +x
     test $res -eq 100 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 100 ; then
  echo "===================== Query on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
  else
  echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
  echo
  
  fi
}

chaincodeQuery_noVerify () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  EXPECTED_RESULT=$3
  echo "===================== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
     set -x
     peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
   res=$?
     set +x
     test $res -eq 0 && let rc=0
     test "$VALUE" = "$EXPECTED_RESULT" 
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
  echo "===================== Query on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
  else
  echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
  echo
  exit 1
  fi
}

# fetchChannelConfig <channel_id> <output_json>
# Writes the current channel config for a given channel to a JSON file
fetchChannelConfig() {
  CHANNEL=$1
  OUTPUT=$2

  setOrdererGlobals

  echo "Fetching the most recent configuration block for the channel"
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel fetch config config_block.pb -o orderer.ipsum.io:7050 -c $CHANNEL --cafile $ORDERER_CA
    set +x
  else
    set -x
    peer channel fetch config config_block.pb -o orderer.ipsum.io:7050 -c $CHANNEL --tls --cafile $ORDERER_CA
    set +x
  fi

  echo "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > "${OUTPUT}"
  set +x
}

# signConfigtxAsPeerOrg <org> <configtx.pb>
# Set the peerOrg admin of an org and signing the config update
signConfigtxAsPeerOrg() {
        PEERORG=$1
        TX=$2
        setGlobals 0 $PEERORG
        set -x
        peer channel signconfigtx -f "${TX}"
        set +x
}

# createConfigUpdate <channel_id> <original_config.json> <modified_config.json> <output.pb>
# Takes an original and modified config, and produces the config update tx which transitions between the two
createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config > original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config > modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb > config_update.pb
  configtxlator proto_decode --input config_update.pb  --type common.ConfigUpdate > config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > "${OUTPUT}"
  set +x
}

