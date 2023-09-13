#!/bin/bash

#set -x

if [ "$#" -lt 1 ]; then
    echo "Run wireshark in a Network Namespace"
    echo "  Usage: $0 [namespace] <interface>"
    echo "  Params:"
    echo "    namespace - Network namespace, required"
    echo "    interface - Begin capturing using interface, optional"
    exit 1;
fi

ns=$1
interface=$([ $# -eq 2 ] && echo "-i $2 -k" || echo "")
# echo ns=$ns  interface=\"$interface\"

sudo ip netns exec $ns wireshark $interface

