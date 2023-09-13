#!/bin/bash

#set -x

if [ "$#" -lt 2 ]; then
    echo "Run ./src/dnsmasq in a Network Namespace"
    echo "  Usage: $0 [namespace] [interface] <conf-file>"
    echo "  Params:"
    echo "    namespace - Network namespace, required"
    echo "    interface - Interface, required"
    echo "    conf-file - Configuration file, optional default=./wink.dnsmasq.conf"
    exit 1;
fi

ns=$1
interface=$2
conf_file=$([ "$#" -eq "3" ] && echo $3 || echo ./wink.dnsmasq.conf)

sudo ip netns exec $ns ./src/dnsmasq --interface=$interface --conf-file=$conf_file

