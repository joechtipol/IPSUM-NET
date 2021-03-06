#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Testing your network..."
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="scriptum"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ipsum.io/orderers/orderer.ipsum.io/msp/tlscacerts/tlsca.ipsum.io-cert.pem

CC_SRC_PATH="github.com/chaincode/ipsumcc/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. /opt/gopath/src/github.com/hyperledger/fabric/network-management-scripts/network-helpers.sh

## Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode on peer0.organ1..."
installChaincode 0 1
# echo "Install chaincode on peer0.organ2..."
installChaincode 0 2
# echo "Install chaincode on peer0.organ3..."
installChaincode 0 3


# Instantiate chaincode on peer0.org2
echo "Instantiating chaincode on peer0.org1..."
instantiateChaincode 0 1

# Query chaincode on peer0.org1
echo "Querying chaincode on peer0.org1..."
chaincodeQuery 0 1 100

# Query chaincode on peer0.org2
echo "Querying chaincode on peer0.org2..."
chaincodeQuery 0 2 100

# Query chaincode on peer0.org3
echo "Querying chaincode on peer0.org3..."
chaincodeQuery 0 3 100

# Invoke chaincode on peer0.org1
echo "Sending invoke transaction on peer0.org1..."
chaincodeInvoke 0 1

# Query on chaincode on peer1.org2, check if the result is 90
echo "Querying chaincode on peer0.org2..."
chaincodeQuery 0 2 90

echo
echo "========= All GOOD, network test completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
