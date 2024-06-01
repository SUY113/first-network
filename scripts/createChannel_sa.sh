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

CC_SRC_PATH_Database="github.com/chaincode/database/go/"
CC_SRC_PATH_Tokenerc="github.com/chaincode/mytoken/go/"

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
	#DATABASE
	## Install chaincode on peer0.orgAccountant and peer0.orgStaff
	echo "Installing chaincode database on peer0.orgAccountant..."
	installChaincodeDatabase 0 Accountant
	echo "Install chaincode database on peer0.orgStaff..."
	installChaincodeDatabase 0 Staff

	# Instantiate chaincode on peer0.orgAccountant
	echo "Instantiating chaincode database on peer0.orgAccountant..."
	instantiateChaincodeDatabase 0 Accountant
	#TOKENERC20
	## Install chaincode on peer0.orgAccountant and peer0.orgStaff
	echo "Installing chaincode token on peer0.orgAccountant..."
	installChaincodeToken 0 Accountant
	echo "Install chaincode token on peer0.orgStaff..."
	installChaincodeToken 0 Staff

	# Instantiate chaincode on peer0.orgAccountant
	echo "Instantiating chaincode token on peer0.orgAccountant..."
	instantiateChaincodeToken 0 Accountant

	# Query chaincode on peer0.orgAccountant
#	echo "Querying chaincode on peer0.orgAccountant..."
#	chaincodeQuery 0 Accountant 100

	# Invoke chaincode on peer0.orgAccountant and peer0.orgStaff
#	echo "Sending invoke transaction on peer0.orgAccountant peer0.orgStaff..."
#	chaincodeInvoke 0 Accountant 0 Staff
	
	## Install chaincode on peer1.orgStaff
#	echo "Installing chaincode on peer1.orgStaff..."
#	installChaincode 1 Staff

	# Query on chaincode on peer1.orgStaff, check if the result is 90
#	echo "Querying chaincode on peer1.orgStaff..."
#	chaincodeQuery 1 staff 90
	
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
