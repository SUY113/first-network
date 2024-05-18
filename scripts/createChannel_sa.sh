#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="staffaccountant"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
NO_CHAINCODE="$6"
: ${CHANNEL_NAME:="staffaccountant"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
: ${NO_CHAINCODE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

if [ "$LANGUAGE" = "java" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/java/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 Accountant

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/staffaccountant.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/staffaccountant.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
  ORG="$1"
  if [ "$ORG" == "Accountant" ]; then
    for peer in 0 1; do
      joinChannelWithRetry $peer $ORG
      echo "===================== peer${peer}.org${ORG} joined channel '$CHANNEL_NAME' ===================== "
      sleep $DELAY
      echo
    done
  elif [ "$ORG" == "Staff" ]; then
    for peer in 0 1; do
      joinChannelWithRetry $peer $ORG
       echo "===================== peer${peer}.org${ORG} joined channel '$CHANNEL_NAME'===================== "
       sleep $DELAY
       echo
    done
  else
    echo "Invalid org value. It must be either 'accountant' or 'staff'."
  fi
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel Accountant
joinChannel Staff

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for orgAccountant..."
updateAnchorPeersStaffAccountant 0 Accountant
echo "Updating anchor peers for orgStaff..."
updateAnchorPeersStaffAccountant 0 Staff

if [ "${NO_CHAINCODE}" != "true" ]; then

	## Install chaincode on peer0.org1 and peer0.org2
	echo "Installing chaincode on peer0.orgAccountant..."
	installChaincode 0 Accountant
	echo "Install chaincode on peer0.orgStaff..."
	installChaincode 0 Staff

	# Instantiate chaincode on peer0.orgStaff
	echo "Instantiating chaincode on peer0.orgStaff..."
	instantiateChaincode 0 Staff

	# Query chaincode on peer0.orgAccountant
	echo "Querying chaincode on peer0.orgAccountant..."
	chaincodeQuery 0 Accountant 100

	# Invoke chaincode on peer0.orgAccountant and peer0.orgStaff
	echo "Sending invoke transaction on peer0.orgAccountant peer0.orgStaff..."
	chaincodeInvoke 0 Accountant 0 Staff
	
	## Install chaincode on peer1.orgStaff
	echo "Installing chaincode on peer1.orgStaff..."
	installChaincode 1 Staff

	# Query on chaincode on peer1.orgStaff, check if the result is 90
	echo "Querying chaincode on peer1.orgStaff..."
	chaincodeQuery 1 staff 90
	
fi

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
