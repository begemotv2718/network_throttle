#!/bin/bash

setup(){
ip link set dev ${VETH_NAME}_cont up
ip addr add ${ADDR_PREFIX}2/24 dev ${VETH_NAME}_cont
ip route add default via ${ADDR_PREFIX}1 dev ${VETH_NAME}_cont
}

cleanup(){
ip addr del ${ADDR_PREFIX}2/24 dev ${VETH_NAME}_cont
}

setup_throttle(){
tc qdisc add dev ${VETH_NAME}_cont root handle 1:0 tbf $TC_TBF_PARAMS
tc qdisc add dev ${VETH_NAME}_cont parent 1:0 handle 10: netem $TC_NETEM_PARAMS
# Another way
#tc qdisc add dev ${VETH_NAME}_cont handle 1: root htb default 0
#tc class add dev ${VETH_NAME}_cont parent 1: classid 1:0 htb $TC_HTB_PARAMS
#tc qdisc add dev ${VETH_NAME}_cont parent 1:0 handle 10: netem $TC_NETEM_PARAMS

# Output current configuration
#tc qdisc show dev ${VETH_NAME}_cont
#tc class show dev ${VETH_NAME}_cont
}

cleanup_throttle(){
tc qdisc delete dev ${VETH_NAME}_cont root
}

setup
setup_throttle
$1
cleanup_throttle
cleanup
