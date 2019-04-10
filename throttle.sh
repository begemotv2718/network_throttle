#!/bin/bash
ETH_NAME=eth0
CONTAINER_NAME=my_container
VETH_NAME=veth
ADDR_PREFIX="192.168.50."
TC_TBF_PARAMS="rate 200kbit buffer 1600 limit 3000"
TC_HTB_PARAMS="rate 200kbit" # ceil 200kbit burst 16kbit cburst 16kbit
TC_NETEM_PARAMS="delay 50ms" # loss 10% corrupt 5% duplicate 1%


setup(){
ip netns add $CONTAINER_NAME
ip link add name ${VETH_NAME}_ext type veth peer name ${VETH_NAME}_cont
ip link set dev ${VETH_NAME}_ext up
ip addr add ${ADDR_PREFIX}1/24 dev ${VETH_NAME}_ext
ip link set dev ${VETH_NAME}_cont netns $CONTAINER_NAME
ip route replace ${ADDR_PREFIX}0/24 via ${ADDR_PREFIX}1 dev ${VETH_NAME}_ext
iptables -A POSTROUTING -t nat --out-interface ${ETH_NAME} -j MASQUERADE
iptables -A FORWARD -i ${ETH_NAME} -o ${VETH_NAME}_ext -j ACCEPT
iptables -A FORWARD -i ${VETH_NAME}_ext -o ${ETH_NAME} -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
}

cleanup(){
iptables -D POSTROUTING -t nat --out-interface ${ETH_NAME} -j MASQUERADE
iptables -D FORWARD -i ${ETH_NAME} -o ${VETH_NAME}_ext -j ACCEPT
iptables -D FORWARD -i ${VETH_NAME}_ext -o ${ETH_NAME} -j ACCEPT
iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ip route del ${ADDR_PREFIX}0/24
ip link del ${VETH_NAME}_ext
ip netns del  $CONTAINER_NAME
}

setup
export CONTAINER_NAME
export VETH_NAME
export ADDR_PREFIX
export TC_TBF_PARAMS
export TC_HTB_PARAMS
export TC_NETEM_PARAMS
ip netns exec $CONTAINER_NAME ./throttle_helper.sh $1
cleanup

