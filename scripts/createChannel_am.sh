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
CHANNEL_NAME="accountantmanager"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
NO_CHAINCODE="$6"
: ${CHANNEL_NAME:="accountantmanager"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
: ${NO_CHAINCODE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10

CC_SRC_PATH_Database="github.com/chaincode/database/go/"

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 Accountant

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/accountantmanager.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/accountantmanager.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
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
  elif [ "$ORG" == "Manager" ]; then
    for peer in 0 1; do
      joinChannelWithRetry $peer $ORG
       echo "===================== peer${peer}.org${ORG} joined channel '$CHANNEL_NAME' ===================== "
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
joinChannel Manager

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for orgAccountant..."
updateAnchorPeersAccountantManager 0 Accountant
echo "Updating anchor peers for orgManager..."
updateAnchorPeersAccountantManager 0 Manager

if [ "${NO_CHAINCODE}" != "true" ]; then

	## Install chaincode on peer0.orgAccountant and peer0.orgManager
#	echo "Installing chaincode on peer0.orgAccountant..."
#	installChaincodeDatabase 0 Accountant
	echo "Install chaincode on peer0.orgManager..."
	installChaincodeDatabase 0 Manager

	# Instantiate chaincode on peer0.orgManager
	echo "Instantiating chaincode on peer0.orgManager..."
	instantiateChaincodeDatabase 0 Manager
	
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
