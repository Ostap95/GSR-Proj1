#!/bin/bash
IPT="/sbin/iptables"
INNER_INTERFACES=eth1 eth2 eth3 eth4
OUTER_INTERFACES=eth0
RULE=REJECT

echo "Flushing iptables rules"
$IPT -F


echo "Adding anti-spoofing rules"
for i in $INNER_INTERFACES
do
	$IPT -A FORWARD -i eth0 -o $i -s 192.168.0.0./16 -j $RULE
	$IPT -A FORWARD -i eth0 -o $i -s 10.0.0.128/26 -j $RULE
	$IPT -A FORWARD -i eth0 -o $i -s 10.0.2.64/26 -j $RULE		
done


