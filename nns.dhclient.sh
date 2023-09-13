#!/bin/bash

#set -x

if [ "$#" -lt 2 ]; then
    echo "Run dhclient in a Network Namespace"
    echo "  Usage: $0 [namespace] [interface]"
    echo "  Params:"
    echo "    namespace - Network namespace, required"
    echo "    interface - Interface, required"
    exit 1;
fi

ns=$1
interface=$2

sudo ip netns exec $ns dhclient -d $interface

