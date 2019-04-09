#!/bin/bash
ETH_NAME=eth0
CONTAINER_NAME=my_container
VETH_NAME=veth
ADDR_PREFIX="192.168.50."

setup(){
ip netns add $CONTAINER_NAME
ip link add name ${VETH_NAME}_ext type veth peer name ${VETH_NAME}_cont
ip link set dev ${VETH_NAME}_ext up
ip addr add ${ADDR_PREFIX}1/24 dev ${VETH_NAME}_ext
ip link set dev ${VETH_NAME}_cont netns $CONTAINER_NAME
ip route add ${ADDR_PREFIX}0/24 via ${ADDR_PREFIX}1 dev ${VETH_NAME}_ext
iptables -A POSTROUTING -t nat --out-interface ${ETH_NAME} -j MASQUERADE
iptables -A FORWARD -i ${ETH_NAME} -o ${VETH_NAME}_ext -j ACCEPT
iptables -A FORWARD -i ${VETH_NAME}_ext -o ${ETH_NAME} -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
}

setup_throttle(){
tc qdisc add dev ${VETH_NAME}_ext root handle 1:0 tbf rate 200kbit buffer 1600 limit 3000
tc qdisc add dev ${VETH_NAME}_ext parent 1:0 handle 10:0 netem delay 100ms
}

cleanup_throttle(){
# cause an error
tc qdisc del dev ${VETH_NAME}_ext root netem
tc qdisc del dev ${VETH_NAME}_ext root tbf rate 512kbit latency 150ms burst 1540
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
setup_throttle
export CONTAINER_NAME
export VETH_NAME
export ADDR_PREFIX
ip netns exec $CONTAINER_NAME ./throttle_helper.sh $1
cleanup_throttle
cleanup

