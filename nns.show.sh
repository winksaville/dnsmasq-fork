#!/bin/bash
#
#Based on code from GPT-4:
# https://chat.openai.com/share/8d579fc8-a3c0-4618-83e1-c5eb017ef0a3

# Function to list all network namespaces
list_namespaces() {
    sudo ip netns list | awk '{print $1}'
}

# Function to show network interface details for given namespaces
show_interfaces() {
    for ns in "$@"; do
        echo "=== Namespace: $ns ==="
        sudo ip netns exec "$ns" ip a show
        echo ""
    done
}

# Main script logic
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 [namespace1] [namespace2] ..."
    echo "       $0 all - show interfaces for all namespaces"
    echo "       $0 all list - list all namespace names"
    exit 1
elif [ "$1" == "all" ]; then
    if [ "$2" == "list" ]; then
        list_namespaces
    else
        namespaces=$(list_namespaces)
        show_interfaces $namespaces
    fi
else
    show_interfaces "$@"
fi
