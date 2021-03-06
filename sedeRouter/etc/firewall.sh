#!/bin/bash
IPT="/sbin/iptables"
INNER_INTERFACES="eth1 eth2 eth3 eth4"
DNS_SERVER_IP="10.0.0.131"
DNS_SERVER2_IP="10.0.0.130"

echo "Flushing iptables rules"
$IPT -F

echo "Creating Firewall settings"

# Permite ligação ssh aos servidores públicos
$IPT -A FORWARD -i eth0 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -d 10.0.0.128/28 -j ACCEPT

# Permite ligação vpn do pc administrador de rede
$IPT -A FORWARD -s 192.168.106.2 -d 10.0.0.128/26 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# bloqueia trafego ssh do exterior
$IPT -A FORWARD -i eth0 -p tcp --dport 22 -m conntrack --ctstate NEW -d 192.168.0.0/29 -j REJECT

# Máquinas com IP privado não podem aceder à Internet
$IPT -A FORWARD -s 192.168.0.0/16 -o eth0 -j REJECT

# Ninguém de fora pode aceder a nenhuma maquina com IP privado
$IPT -A FORWARD -i eth0 -d 192.168.0.0/16 -j REJECT

# Rede externa pode iniciar ligação com PCs visitantes
$IPT -A FORWARD -i eth0 -d 10.0.0.160/28 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -i eth0 -d 10.0.0.144/28 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Máquinas com IP público podem comunicar com exterior
$IPT -A FORWARD -s 10.0.0.128/26 -o eth0 -j ACCEPT
$IPT -A FORWARD -s 10.0.2.64/26 -o eth0 -j ACCEPT
$IPT -A FORWATD -s 10.8.0.0/24 -o eth0 -j ACCEPT

# PCs com IP público não podem fazer pedidos HTTP
$IPT -A FORWARD -s 10.0.0.128/26 -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW -j REJECT
$IPT -A FORWARD -s 10.0.2.64/26 -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW -j REJECT

# PCs com IP público nao podem inicar ligação com rede externa
$IPT -A FORWARD -s 10.0.0.128/26 -o eth0 -m conntrack --ctstate NEW -j REJECT
$IPT -A FORWARD -s 10.0.2.64/26 -o eth0 -m conntrack --ctstate NEW -j REJECT

# Servidor DNS primário e email só deixa entrar trafego DNS,IMAP e SMTP
$IPT -A FORWARD -p udp -s 0/0 --sport 1024:65535 -d $DNS_SERVER_IP --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p udp -s $DNS_SERVER_IP --sport 53 -d 0/0 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p udp -s 0/0 --sport 53 -d $DNS_SERVER_IP --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p udp -s $DNS_SERVER_IP --sport 53 -d 0/0 --dport 53 -m state --state ESTABLISHED -j ACCEPT

$IPT -A FORWARD -p tcp --dport 143 -d $DNS_SERVER_IP -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p tcp --dport 25 -d $DNS_SERVER_IP -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Servidor DNS secundário deixa entrar trafego DNS
$IPT -A FORWARD -p udp -s 0/0 --sport 1024:65535 -d $DNS_SERVER2_IP --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p udp -s $DNS_SERVER2_IP --sport 53 -d 0/0 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p udp -s 0/0 --sport 53 -d $DNS_SERVER2_IP --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p udp -s $DNS_SERVER2_IP --sport 53 -d 0/0 --dport 53 -m state --state ESTABLISHED -j ACCEPT

# Servidor público HTTP deixa entrar trafego HTTP e HTTPS
$IPT -A FORWARD -p tcp -m multiport --dports 80,443 -d 10.0.0.131/28 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p tcp -m multiport --dports 80,443 -s 10.0.0.131/28 -o eth0 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p tcp -m multiport --dports 80,443 -d 10.0.0.130/28 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p tcp -m multiport --dports 80,443 -s 10.0.0.130/28 -o eth0 -m state --state NEW,ESTABLISHED -j ACCEPT

# Servidor proxy tem de deixar entrar trafego http
$IPT -A FORWARD -p tcp -m tcp --dport 80 -d 10.0.0.132 -m state --state NEW,ESTABLISHED -j ACCEPT

# Ninguem de fora pode iniciar ligação para nenhum dos PCS com IP publico (excepto visitantes)
$IPT -A FORWARD -i eth0 -d 10.0.0.128/26 -m conntrack --ctstate NEW -j REJECT
$IPT -A FORWARD -i eth0 -d 10.0.2.64/26 -m conntrack --ctstate NEW -j REJECT

# Servidor DNS secundário só deixa entrar trafego DNS
$IPT -A FORWARD -p udp --dport 53 -d 10.0.0.130 -j ACCEPT

# Proxy Web
$IPT -t nat -A PREROUTING -s 10.0.0.176/28 -p tcp --dport 80 -j DNAT --to 10.0.0.132:3128
$IPT -t nat -A PREROUTING -s 10.0.0.160/28 -p tcp --dport 80 -j DNAT --to 10.0.0.132:3128
$IPT -t nat -A PREROUTING -s 10.0.0.144/28 -p tcp --dport 80 -j DNAT --to 10.0.0.132:3128
$IPT -t nat -A PREROUTING -s 10.8.0.0/24 -p tcp --dport 80 -j DNAT --to 10.0.0.132:3128

$IPT -t filter -A FORWARD -s ! 10.0.0.132 -o eth0 -p tcp --dport 80 -j REJECT

$IPT -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

$IPT -A INPUT -i eth0 -d 10.0.0.128/26 -j REJECT
$IPT -A INPUT -i eth0 -d 10.0.2.64/26 -j REJECT
$IPT -A INPUT -i eth0 -d 192.168.0.0/16 -j REJECT

echo "Adding anti-spoofing rules"
for i in $INNER_INTERFACES
do
	$IPT -A FORWARD -i eth0 -o $i -s 192.168.0.0/16 -j REJECT
	$IPT -A FORWARD -i eth0 -o $i -s 10.0.0.128/26 -j REJECT
	$IPT -A FORWARD -i eth0 -o $i -s 10.0.2.64/26 -j REJECT
done

for i in $INNER_INTERFACES
do
	$IPT -A FORWARD -i $i -o eth0 -s 0/0
	$IPT -A FORWARD -i $i -o eth0 -s 10.0.0.0/24
done
