#!/bin/bash

NETWORK_PROXY=`cat modules.conf | grep 'network_proxy'`
NETWORK_PROXY=${NETWORK_PROXY##*=}
echo $NETWORK_PROXY

NETWORK_PROXY=`cat modules.conf | grep 'network_proxy'`
NETWORK_PROXY=${NETWORK_PROXY##*=}
echo $NETWORK_PROXY
