#!/bin/bash

setup(){
ip link set dev ${VETH_NAME}_cont up
ip addr add ${ADDR_PREFIX}2/24 dev ${VETH_NAME}_cont
route add default gateway ${ADDR_PREFIX}1
}

cleanup(){
ip addr del ${ADDR_PREFIX}2/24
}


setup
$1
cleanup
