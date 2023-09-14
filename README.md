# Fork of dnsmasq

doc: https://thekelleys.org.uk/dnsmasq/doc.html
Browse original source: http://thekelleys.org.uk/gitweb/?p=dnsmasq.git
winks fork: https://github.com/winksaville/dnsmasq-fork

This is a fork of dnsmasq which I'm using investigate how dnsmasq
handles multiple dhcp-option's with the same tag.

I've added many printf statements in several files to get an idea
of how dnsmasq works. What I've found is that dnsmasq stores
dhcp-option's in a linked list of `dhcp_options` and in [testing](#testing) I show
the code and the resulting output and there are no issues with
multiple dhcp-options with the same tag name.

Looking at the code for when `src/rfc2131.c/do_options()` is invoked and
processing options and it invokes `option_find2`. If the opt meets necessary
pre-conditions then `option_put` is invoked to place it in `mess`, the
message buffer:
```
if (context->router.s_addr &&
  in_list(req_options, OPTION_ROUTER) &&
  !option_find2(OPTION_ROUTER))
option_put(mess, end, OPTION_ROUTER, INADDRSZ, ntohl(context->router.s_addr));

     if (daemon->port == NAMESERVER_PORT &&
  in_list(req_options, OPTION_DNSSERVER) &&
  !option_find2(OPTION_DNSSERVER))
option_put(mess, end, OPTION_DNSSERVER, INADDRSZ, ntohl(context->local.s_addr));
```

Below is `option_find2` and it iterates of the `daemon->dhcp_opts` linked list looking
for the matching `opt` and the `flags` has the `DHOPT_TAGOK` bit set.
```
static struct dhcp_opt *option_find2(int opt)
{
  printf("wink: option_find2:+ opt=%d\n", opt);
  struct dhcp_opt *opts;

  for (opts = daemon->dhcp_opts; opts; opts = opts->next)
    if (opts->opt == opt && (opts->flags & DHOPT_TAGOK))
      {
        printf("wink: option_find2:- found opt=%d rv=!NULL, opts->netid.net=%s opts->len=%d\n", opt, opts->netid->net, opts->len);
        return opts;
      }

  printf("wink: option_find2:- not found opt=%d rv=NULL\n", opt);
  return NULL;
}
```

## Building

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


## Testing


To test this I start a new termainl and run three commands, first
I create two Network Namespaces, ns1 and ns2 with veth1 and veth2
by running `./nns.setup.sh`:
```
wink@3900x 23-09-14T16:11:04.211Z:~/prgs/rust/forks/dnsmasq (wink-test1)
$ ./nns.setup.sh 
[sudo] password for wink:
```
Next I run `./nns.show.sh all` to verify the namespaces and veth's are created:
```
wink@3900x 23-09-14T16:11:19.897Z:~/prgs/rust/forks/dnsmasq (wink-test1)
$ ./nns.show.sh all
=== Namespace: ns2 ===
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
20: veth2@if21: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether ee:28:c5:71:ec:97 brd ff:ff:ff:ff:ff:ff link-netns ns1

=== Namespace: ns1 ===
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
21: veth1@if20: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state LOWERLAYERDOWN group default qlen 1000
    link/ether 0a:2a:ae:f7:d5:3a brd ff:ff:ff:ff:ff:ff link-netns ns2
    inet 192.168.1.1/24 scope global veth1
       valid_lft forever preferred_lft forever
```

And finally I run `./nns.wireshark.sh` to start wireshark to capture of
packets on veth1:
```
wink@3900x 23-09-14T16:11:45.137Z:~/prgs/rust/forks/dnsmasq (wink-test1)
$ ./nns.wireshark.sh ns1 veth1
 ** (wireshark:8334) 09:12:10.754026 [GUI WARNING] -- QStandardPaths: XDG_RUNTIME_DIR not set, defaulting to '/tmp/runtime-root'
 ** (wireshark:8334) 09:12:11.867728 [Capture MESSAGE] -- Capture Start ...
 ** (wireshark:8334) 09:12:12.002131 [Capture MESSAGE] -- Capture started
 ** (wireshark:8334) 09:12:12.002169 [Capture MESSAGE] -- File: "/tmp/wireshark_veth13O5NB2.pcapng"
```

Then in a second terminal I run `./nns.dnsmasq.sh` which starts dnsmasq in ns1 using veth1,
below is the initial output of the log:
```
wink@3900x 23-09-14T20:09:43.617Z:~/prgs/rust/forks/dnsmasq (wink-test1)
$ ./nns.dnsmasq.sh ns1 veth1 ./wink.dnsmasq.conf 
[sudo] password for wink: 
wink: read_opts:+ argc=3 argv=0x7ffe7018a588 compile_opts=IPv6 GNU-getopt no-DBus no-UBus no-i18n no-IDN DHCP DHCPv6 no-Lua TFTP no-conntrack ipset no-nftset auth no-cryptohash no-DNSSEC loop-detect inotify dumpfile
wink: one_opt:+ option=i arg=veth1 errstr= gen_err=try --help command_line=1 servers_only=0
wink: one_opt:- [rv=1] option=i arg=(null) errstr= gen_err=try --help command_line=1 servers_only=0
wink: one_file:+ file=./wink.dnsmasq.conf hard_opt=0
wink: read_file:+ file=./wink.dnsmasq.conf hard_opt=0 from_script=0
wink: one_opt:+ option=F arg=192.168.1.50,192.168.1.60,2m errstr=dhcp-range gen_err=error command_line=0 servers_only=0
wink: one_opt:- [rv=1] option=F arg=192.168.1.50 errstr=dhcp-range gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=l arg=./wink.dnsmasq.leases errstr=dhcp-leasefile gen_err=error command_line=0 servers_only=0
wink: one_opt:- [rv=1] option=l arg=./wink.dnsmasq.leases errstr=dhcp-leasefile gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=d arg=(null) errstr=no-daemon gen_err=error command_line=0 servers_only=0
wink: one_opt:- [set_opt_boot(6) rv=1] option=d arg=(null) errstr=no-daemon gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=8 arg=./wink.dnsmasq.log errstr=log-facility gen_err=error command_line=0 servers_only=0
wink: one_opt:- [rv=1] option=8 arg=./wink.dnsmasq.log errstr=log-facility gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=k arg=(null) errstr=log-debug gen_err=error command_line=0 servers_only=0
wink: one_opt:- [set_opt_boot(62) rv=1] option=k arg=(null) errstr=log-debug gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=q arg=(null) errstr=log-queries gen_err=error command_line=0 servers_only=0
wink: one_opt:- [rv=1] option=q arg=(null) errstr=log-queries gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=
 arg=(null) errstr=log-dhcp gen_err=error command_line=0 servers_only=0
wink: one_opt:- [set_opt_boot(28) rv=1] option=
 arg=(null) errstr=log-dhcp gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=O arg=tag:defaultoptions,option:router,192.168.1.6 errstr=dhcp-option gen_err=error command_line=0 servers_only=0
wink: parse_dhcp_opt:+ errstr=dhcp-option arg=tag:defaultoptions,option:router,192.168.1.6 flags=0
wink: dhcp_netid_create: net=defaultoptions next=(nil)
wink: parse_dhcp_opt:- [rv=1] errstr=dhcp-option arg=option:router flags=0
wink: one_opt:- [parse_dhcp_opt rv=1] option=O arg=tag:defaultoptions errstr=dhcp-option gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=O arg=tag:defaultoptions,option:dns-server,9.9.9.9 errstr=dhcp-option gen_err=error command_line=0 servers_only=0
wink: parse_dhcp_opt:+ errstr=dhcp-option arg=tag:defaultoptions,option:dns-server,9.9.9.9 flags=0
wink: dhcp_netid_create: net=defaultoptions next=(nil)
wink: parse_dhcp_opt:- [rv=1] errstr=dhcp-option arg=option:dns-server flags=0
wink: one_opt:- [parse_dhcp_opt rv=1] option=O arg=tag:defaultoptions errstr=dhcp-option gen_err=error command_line=0 servers_only=0
wink: one_opt:+ option=G arg=ee:28:c5:71:ec:97,set:defaultoptions errstr=dhcp-host gen_err=error command_line=0 servers_only=0
wink: one_opt: G --dhcp-host net:||set: arg=set:defaultoptions
wink: dhcp_netid_create: net=defaultoptions next=(nil)
wink: one_opt:- [rv=1] option=G arg=(null) errstr=dhcp-host gen_err=error command_line=0 servers_only=0
wink: read_file:- file=./wink.dnsmasq.conf hard_opt=0 from_script=0
wink: one_file:- [rv=1] file=./wink.dnsmasq.conf hard_opt=0
wink: read_opts:- argc=3 argv=0x7ffe7018a588 compile_opts=IPv6 GNU-getopt no-DBus no-UBus no-i18n no-IDN DHCP DHCPv6 no-Lua TFTP no-conntrack ipset no-nftset auth no-cryptohash no-DNSSEC loop-detect inotify dumpfile
dnsmasq: wink: main
dnsmasq: started, version 2.89-57-g848fde5 cachesize 150
dnsmasq: compile time options: IPv6 GNU-getopt no-DBus no-UBus no-i18n no-IDN DHCP DHCPv6 no-Lua TFTP no-conntrack ipset no-nftset auth no-cryptohash no-DNSSEC loop-detect inotify dumpfile
dnsmasq-dhcp: DHCP, IP range 192.168.1.50 -- 192.168.1.60, lease time 2m
dnsmasq: reading /etc/resolv.conf
dnsmasq: using nameserver 9.9.9.9#53
dnsmasq: read /etc/hosts - 2 names
```

Then, in a third terminal, run I `./nns.dhclient.sh` to request a DHCP address.
After a fews seconds or so dhclient discovers, is offered, requests and
receives an address, in this case `192.168.1.53`:
```
wink@3900x 23-09-14T20:12:04.846Z:~/prgs/rust/forks/dnsmasq (wink-test1)
$ ./nns.dhclient.sh ns2 veth2
[sudo] password for wink: 
Internet Systems Consortium DHCP Client 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/

Listening on LPF/veth2/ee:28:c5:71:ec:97
Sending on   LPF/veth2/ee:28:c5:71:ec:97
Sending on   Socket/fallback
DHCPDISCOVER on veth2 to 255.255.255.255 port 67 interval 8
DHCPOFFER of 192.168.1.53 from 192.168.1.1
DHCPREQUEST for 192.168.1.53 on veth2 to 255.255.255.255 port 67
DHCPACK of 192.168.1.53 from 192.168.1.1
bound to 192.168.1.53 -- renewal in 56 seconds.
```

If you look at the dnsmasq logs in the second termainal we see this additional output:
```
wink: dhcp_reply:+
dnsmasq-dhcp: 4215237179 available DHCP range: 192.168.1.50 -- 192.168.1.60
dnsmasq-dhcp: 4215237179 DHCPDISCOVER(veth1) 192.168.1.54 ee:28:c5:71:ec:97 
dnsmasq-dhcp: 4215237179 tags: defaultoptions, known, veth1
dnsmasq-dhcp: 4215237179 DHCPOFFER(veth1) 192.168.1.53 ee:28:c5:71:ec:97 
wink: do_options:+
wink: option_filter:+ tags: defaultoptions known veth1 
wink: option_filter:- tagif: defaultoptions known veth1 
dnsmasq-dhcp: 4215237179 requested options: 1:netmask, 28:broadcast, 2:time-offset, 3:router, 
dnsmasq-dhcp: 4215237179 requested options: 15:domain-name, 6:dns-server, 12:hostname
wink: option_find2:+ opt=67
wink: option_find2:- not found opt=67 rv=NULL
wink: option_find2:+ opt=66
wink: option_find2:- not found opt=66 rv=NULL
wink: option_find2:+ opt=255
wink: option_find2:- not found opt=255 rv=NULL
wink: option_find2:+ opt=58
wink: option_find2:- not found opt=58 rv=NULL
wink: option_find2:+ opt=59
wink: option_find2:- not found opt=59 rv=NULL
wink: option_find2:+ opt=1
wink: option_find2:- not found opt=1 rv=NULL
wink: option_find2:+ opt=28
wink: option_find2:- not found opt=28 rv=NULL
wink: option_find2:+ opt=3
wink: option_find2:- found opt=3 rv=!NULL, opts->netid.net=defaultoptions opts->len=4
wink: option_find2:+ opt=6
wink: option_find2:- found opt=6 rv=!NULL, opts->netid.net=defaultoptions opts->len=4
wink: do_options:-
dnsmasq-dhcp: 4215237179 next server: 192.168.1.1
dnsmasq-dhcp: 4215237179 sent size:  1 option: 53 message-type  2
dnsmasq-dhcp: 4215237179 sent size:  4 option: 54 server-identifier  192.168.1.1
dnsmasq-dhcp: 4215237179 sent size:  4 option: 51 lease-time  2m
dnsmasq-dhcp: 4215237179 sent size:  4 option: 58 T1  1m
dnsmasq-dhcp: 4215237179 sent size:  4 option: 59 T2  1m45s
dnsmasq-dhcp: 4215237179 sent size:  4 option:  1 netmask  255.255.255.0
dnsmasq-dhcp: 4215237179 sent size:  4 option: 28 broadcast  192.168.1.255
dnsmasq-dhcp: 4215237179 sent size:  4 option:  6 dns-server  9.9.9.9
dnsmasq-dhcp: 4215237179 sent size:  4 option:  3 router  192.168.1.6
wink: dhcp_reply:- rv=300 DHCPOFFER
wink: dhcp_reply:+
dnsmasq-dhcp: 4215237179 available DHCP range: 192.168.1.50 -- 192.168.1.60
dnsmasq-dhcp: 4215237179 DHCPREQUEST(veth1) 192.168.1.53 ee:28:c5:71:ec:97 
dnsmasq-dhcp: 4215237179 tags: defaultoptions, known, veth1
dnsmasq-dhcp: 4215237179 DHCPACK(veth1) 192.168.1.53 ee:28:c5:71:ec:97 
wink: do_options:+
wink: option_filter:+ tags: defaultoptions known veth1 
wink: option_filter:- tagif: defaultoptions known veth1 
dnsmasq-dhcp: 4215237179 requested options: 1:netmask, 28:broadcast, 2:time-offset, 3:router, 
dnsmasq-dhcp: 4215237179 requested options: 15:domain-name, 6:dns-server, 12:hostname
wink: option_find2:+ opt=67
wink: option_find2:- not found opt=67 rv=NULL
wink: option_find2:+ opt=66
wink: option_find2:- not found opt=66 rv=NULL
wink: option_find2:+ opt=255
wink: option_find2:- not found opt=255 rv=NULL
wink: option_find2:+ opt=58
wink: option_find2:- not found opt=58 rv=NULL
wink: option_find2:+ opt=59
wink: option_find2:- not found opt=59 rv=NULL
wink: option_find2:+ opt=1
wink: option_find2:- not found opt=1 rv=NULL
wink: option_find2:+ opt=28
wink: option_find2:- not found opt=28 rv=NULL
wink: option_find2:+ opt=3
wink: option_find2:- found opt=3 rv=!NULL, opts->netid.net=defaultoptions opts->len=4
wink: option_find2:+ opt=6
wink: option_find2:- found opt=6 rv=!NULL, opts->netid.net=defaultoptions opts->len=4
wink: do_options:-
dnsmasq-dhcp: 4215237179 next server: 192.168.1.1
dnsmasq-dhcp: 4215237179 sent size:  1 option: 53 message-type  5
dnsmasq-dhcp: 4215237179 sent size:  4 option: 54 server-identifier  192.168.1.1
dnsmasq-dhcp: 4215237179 sent size:  4 option: 51 lease-time  2m
dnsmasq-dhcp: 4215237179 sent size:  4 option: 58 T1  1m
dnsmasq-dhcp: 4215237179 sent size:  4 option: 59 T2  1m45s
dnsmasq-dhcp: 4215237179 sent size:  4 option:  1 netmask  255.255.255.0
dnsmasq-dhcp: 4215237179 sent size:  4 option: 28 broadcast  192.168.1.255
dnsmasq-dhcp: 4215237179 sent size:  4 option:  6 dns-server  9.9.9.9
dnsmasq-dhcp: 4215237179 sent size:  4 option:  3 router  192.168.1.6
wink: dhcp_reply:- rv=300 DHCPACK
dnsmasq: reading /etc/resolv.conf
dnsmasq: using nameserver 9.9.9.9#53
```

In the above the important lines are from option_find2. We see `opt=3` (router) and
`opt=6` (dns-server) are both found with the "tag", `opts->netid.net`, being `defaultoptions`:
```
wink: option_find2:+ opt=3
wink: option_find2:- found opt=3 rv=!NULL, opts->netid.net=defaultoptions opts->len=4
wink: option_find2:+ opt=6
wink: option_find2:- found opt=6 rv=!NULL, opts->netid.net=defaultoptions opts->len=4
wink: do_options:-
```

And we also see the message content being printed contians the expected
output for dns-server and router:
```
dnsmasq-dhcp: 4215237179 sent size:  4 option:  6 dns-server  9.9.9.9
dnsmasq-dhcp: 4215237179 sent size:  4 option:  3 router  192.168.1.6
```
