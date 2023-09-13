#!/bin/bash

# Make Network Namespace ns1 and ns2
sudo ip netns add ns1
sudo ip netns add ns2

# Create veth1 and 2
sudo ip link add veth1 type veth peer name veth2

# Add veth1 and veth2 to ns1 and ns2 respectively
sudo ip link set veth1 netns ns1
sudo ip link set veth2 netns ns2

# Configure and up veth1
sudo ip netns exec ns1 ip addr add 192.168.1.1/24 dev veth1
sudo ip netns exec ns1 ip link set veth1 up

