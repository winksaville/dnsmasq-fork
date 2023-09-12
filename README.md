Fork of dnsmawq

doc: https://thekelleys.org.uk/dnsmasq/doc.html
Browse original source: http://thekelleys.org.uk/gitweb/?p=dnsmasq.git
winks fork: https://github.com/winksaville/dnsmasq-fork

* Building

```
wink@3900x 23-09-12T18:15:15.199Z:~/prgs/rust/forks/dnsmasq (master)
$ make
make[1]: Entering directory '/home/wink/prgs/rust/forks/dnsmasq/src'
cc -Wall -W -O2   -DVERSION='"2.89-45-g3b5ddf3"'             -c cache.c	
cc -Wall -W -O2   -DVERSION='"2.89-45-g3b5ddf3"'             -c rfc1035.c	
..
cc -Wall -W -O2   -DVERSION='"2.89-45-g3b5ddf3"'             -c nftset.c	
cc  -o dnsmasq cache.o rfc1035.o util.o option.o forward.o network.o dnsmasq.o dhcp.o lease.o rfc2131.o netlink.o dbus.o bpf.o helper.o tftp.o log.o conntrack.o dhcp6.o rfc3315.o dhcp-common.o outpacket.o radv.o slaac.o auth.o ipset.o pattern.o domain.o dnssec.o blockdata.o tables.o loop.o inotify.o poll.o rrfilter.o edns0.o arp.o crypto.o dump.o ubus.o metrics.o hash-questions.o domain-match.o nftset.o   
make[1]: Leaving directory '/home/wink/prgs/rust/forks/dnsmasq/src'
```

To use wink.dnsmasq.conf you'll need to add capabilities so
you won't need to run as root.
```
wink@3900x 23-09-12T18:27:58.704Z:~/prgs/rust/forks/dnsmasq (wink-test1)
$ sudo setcap 'cap_net_admin,cap_net_raw+ep' ./src/dnsmasq
```

More instructions to come, such as setting up a test network using Network Namespaces

