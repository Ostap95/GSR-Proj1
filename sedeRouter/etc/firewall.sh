#!/bin/bash
IPT="/sbin/iptables"
INNER_INTERFACES="eth1 eth2 eth3 eth4"

echo "Flushing iptables rules"
$IPT -F

echo "Creating Firewall settings"

# Permite ligação ssh aos servidores públicos
$IPT -A FORWARD -i eth0 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -d 10.0.0.128/28 -j ACCEPT

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

# PCs com IP público não podem fazer pedidos HTTP
$IPT -A FORWARD -s 10.0.0.128/26 -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW -j REJECT
$IPT -A FORWARD -s 10.0.2.64/26 -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW -j REJECT

# PCs com IP público nao podem inicar ligação com rede externa
$IPT -A FORWARD -s 10.0.0.128/26 -o eth0 -m conntrack --ctstate NEW -j REJECT
$IPT -A FORWARD -s 10.0.2.64/26 -o eth0 -m conntrack --ctstate NEW -j REJECT

# Ninguem de fora pode iniciar ligação para nenhum dos PCS com IP publico (excepto visitantes)
$IPT -A FORWARD -i eth0 -d 10.0.0.128/26 -m conntrack --ctstate NEW -j REJECT
$IPT -A FORWARD -i eth0 -d 10.0.2.64/26 -m conntrack --ctstate NEW -j REJECT

# Rede externa não pode aceder ao proxy
$IPT -A FORWARD -i eth0 -d 10.0.0.132 -m conntrack --ctstate NEW -j REJECT

# Servidor público HTTP só deixa entrar trafego HTTP e HTTPS
$IPT -A FORWARD -p tcp -m multiport --dports 80,443 -d 10.0.0.132 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Servidor DNS primário e email só deixa entrar trafego DNS,IMAP e SMTP
$IPT -A FORWARD -p udp --dport 53 -d 10.0.0.131 -j ACCEPT
$IPT -A FORWARD -p tcp --dport 143 -d 10.0.0.131 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -p tcp --dport 25 -d 10.0.0.131 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Servidor DNS secundário só deixa entrar trafego DNS
$IPT -A FORWARD -p udp --dport 53 -d 10.0.0.130 -j ACCEPT

# FALTA PROXY SÓ DEIXAR ENTRAR SERVIÇO DELE


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




