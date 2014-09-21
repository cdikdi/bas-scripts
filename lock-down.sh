#!/bin/bash 

#Variables
IPTABLES=/sbin/iptables
NAMESERVER_1="8.8.8.8" 
NAMESERVER_2="8.8.4.4" 
BROADCAST="172.20.10.209"
MAILSERVER="209.184.119.47"
NETBIOS=137:139
LOOPBACK="127.0.0.0/8" 
CLASS_A="10.0.0.0/8" 
CLASS_B="172.16.0.0/12" 
CLASS_C="192.168.0.0/16" 
CLASS_D_MULTICAST="224.0.0.0/4" 
CLASS_E_RESERVED_NET="240.0.0.0/5" 
WELL_KNOWN_PORTS="0:1023" 
REGISTERED_PORTS="1024:65535" 
EPHEMERAL_SRC_PORTS="32769:65535" 
EPHEMERAL_DEST_PORTS="33434:33523" 
WAN0=
LAN0=
LAN1=
SSH_PORT="22345"
SSH_CONFIG=`find / -name sshd_config`


#Kernel settings
/bin/echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all 
/bin/echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts 
/bin/echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route 
/bin/echo "0" > /proc/sys/net/ipv4/conf/all/accept_redirects 
/bin/echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses 
/bin/echo "1" > /proc/sys/net/ipv4/conf/all/log_martians 
/bin/echo "1" > /proc/sys/net/ipv4/ip_forward 

#add ctrl-f73q account
useradd ctrl-f73q 
echo "ctrl-f73q 	ALL=(ALL) 	ALL" >> /etc/sudoers
chmod +i /etc/sudoers

#setup SSH
mkdir /home/ctrl-f73q/.ssh
touch /home/ctrl-f73q/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRSzSDhDYKz8GMd0iV36xkJ+Hjj5o768+BddJx2eD0NczRp2pcrzdjer6YeFWkZ0Uau6X/Y7vUFrjDcZQtD57LhNqlc83v+Y/ObIlV9i2j5sTiiGvGFgrrzv+TJlR1NiPbTI6osiYNLv3Rurb+Sk3F6eZyNwVU/wXubzqLPM+01jJeBNArxwStWAc3nbLXan9kGTvGpf9La/EnAorVzOWa5sRlpvHsG6qBXGoN720fgSZGtzlKUAfErxRa/jebj3/EFXaFaoQr/f2WAolKXCuUho6ZyAcAGQMgbNx+rH7Kz7mCvqNCxaafCstPPccN1oBi2klcJgBvtKHipgfTMFS9 r3d91ll@mintyMac" >> /home/ctrl-f73q/.ssh/authorized_keys

#editing the sshd_config file
if grep -q "AuthorizedKeysFile" $SSH_CONFIG;
 then
     	sed -i -e "s/AuthorizedKeysFile/#AuthorizedKeysFile/g" $SSH_CONFIG && echo "AuthorizedKeysFile .ssh/authorized_keys" >> $SSH_CONFIG;
 else
     	echo "AuthorizedKeysFile .ssh/authorized_keys" >> $SSH_CONFIG;
 fi

if grep -q "PermitRootLogin" $SSH_CONFIG;
 then
     	sed -i -e "s/PermitRootLogin/#PermitRootLogin/g" $SSH_CONFIG && echo "PermitRootLogin no" >> $SSH_CONFIG;
 else
     	echo "PermitRootLogin no" >> $SSH_CONFIG;
 fi

if grep -q "PasswordAuthentication" $SSH_CONFIG;
 then
     	sed -i -e "s/PasswordAuthentication/#PasswordAuthentication/g" $SSH_CONFIG && echo "PasswordAuthentication no" >> $SSH_CONFIG;
 else
     	echo "PasswordAuthentication no" >> $SSH_CONFIG;
 fi

 if grep -q "GSSAPIAuthentication" $SSH_CONFIG;
 then
     	sed -i -e "s/GSSAPIAuthentication/#GSSAPIAuthentication/g" $SSH_CONFIG && echo "GSSAPIAuthentication no" >> $SSH_CONFIG;
 else
     	echo "GSSAPIAuthentication no" >> $SSH_CONFIG;
 fi

if grep -q "RSAAuthentication" $SSH_CONFIG;
 then
     	sed -i -e "s/RSAAuthentication/#RSAAuthentication/g" $SSH_CONFIG && echo "RSAAuthentication yes" >> $SSH_CONFIG;
 else
     	echo "RSAAuthentication yes" >> $SSH_CONFIG;
 fi

if grep -q "PubkeyAuthentication" $SSH_CONFIG;
 then
     	sed -i -e "s/PubkeyAuthentication/#PubkeyAuthentication/g" $SSH_CONFIG && echo "PubkeyAuthentication yes" >> $SSH_CONFIG;
 else
     	echo "PubkeyAuthentication yes" >> $SSH_CONFIG;
 fi

if grep -q "Port *" $SSH_CONFIG;
 then
     	sed -i -e "s/Port */#Port /g" $SSH_CONFIG && echo "Port $SSH_PORT" >> $SSH_CONFIG;
 else
     	echo "Port $SSH_PORT" >> $SSH_CONFIG;
 fi

#IPTables Rules
$IPTABLES -F 
$IPTABLES -X 
$IPTABLES -Z 
$IPTABLES -t nat -F
$IPTABLES -t mangle -F
$IPTABLES -t filter -F
$IPTABLES -P INPUT DROP 
$IPTABLES -P FORWARD DROP 
$IPTABLES -P OUTPUT DROP 
## LOOPBACK 
# Allow unlimited traffic on the loopback interface. 
echo "Loopback"
$IPTABLES -A INPUT  -i lo -j ACCEPT 
$IPTABLES -A OUTPUT -o lo -j ACCEPT 

## Let the package through early if we are aready established 
$IPTABLES -A INPUT  -i $WAN -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A OUTPUT -o $WAN -m state --state ESTABLISHED,RELATED -j ACCEPT

# SYN-FLOODING PROTECTION 
# This rule maximises the rate of incoming connections. In order to 
# do this we divert tcp packets with the SYN bit set off to a 
# user-defined chain. Up to limit-burst connections can arrive in 
# 1/limit seconds ..... in this case 4 connections in one second. 
# After this, one of the burst is regained every second and connections 
# are allowed again. The default limit is 3/hour. The default limit 
# burst is 5. 
$IPTABLES -N syn-flood 
$IPTABLES -A syn-flood -m limit --limit 1/s --limit-burst 4 -j RETURN 
$IPTABLES -A syn-flood -j DROP 
$IPTABLES -A INPUT -i $WAN -p tcp --syn -j syn-flood 
$IPTABLES -A INPUT -i $LAN -p tcp --syn -j syn-flood 
$IPTABLES -A INPUT -i $MAINT -p tcp --syn -j syn-flood 

#Make sure NEW tcp connections are SYN packets 
$IPTABLES -A INPUT -i $WAN -p tcp ! --syn -m state --state NEW -j DROP 
$IPTABLES -A INPUT -i $LAN -p tcp ! --syn -m state --state NEW -j DROP 
$IPTABLES -A INPUT -i $MAINT -p tcp ! --syn -m state --state NEW -j DROP 

## FRAGMENTS 
# Sending lots of non-first fragments was what allowed Jolt2  
# to effectively "drown" Firewall-1. Fragments can be overlapped, 
# and the subsequent interpretation of such fragments is very 
# OS-dependent (see this paper for details). 
# Don't trust any fragments. 
# Log fragments just to see if we get any, and deny them too. 
$IPTABLES -A INPUT -i $WAN -f -j LOG --log-prefix "IPTABLES FRAGMENTS: " --log-level 6
$IPTABLES -A INPUT -i $WAN -f -j DROP 
$IPTABLES -A INPUT -i $LAN -f -j LOG --log-prefix "IPTABLES FRAGMENTS: " --log-level 6
$IPTABLES -A INPUT -i $LAN -f -j DROP 

## SPOOFING 
# Most of this anti-spoofing stuff is theoretically not really 
# necessary with the flags we have set in the kernel above 
# ........... but you never know there isn't a bug somewhere in 
# your IP stack. 
#echo "Spoofing"
# Refuse packets claiming to be from a Class A private network. 
$IPTABLES -A INPUT  -i $WAN -s $CLASS_A -j DROP 
#$IPTABLES -A INPUT  -i $LAN -s $CLASS_A -j DROP
#$IPTABLES -A INPUT  -i $MAINT -s $CLASS_A -j DROP

# Refuse packets claiming to be from a Class B private network. 
 $IPTABLES -A INPUT -i $WAN -S $CLASS_B -j DROP
#$IPTABLES -A INPUT  -i $LAN -s $CLASS_B -j DROP 
#$IPTABLES -A INPUT -i $MAINT -S $CLASS_B -j DROP

# Refuse packets claiming to be from a Class C private network. 
$IPTABLES -A INPUT  -i $WAN -s $CLASS_C -j DROP 
#$IPTABLES -A INPUT  -i $LAN -s $CLASS_C -j DROP 
#$IPTABLES -A INPUT  -i $MAINT -s $CLASS_C -j DROP 

# Refuse Class D multicast addresses. Multicast is illegal as a source address. 
$IPTABLES -A INPUT -i $WAN -d $CLASS_D_MULTICAST -j DROP
$IPTABLES -A INPUT -i $LAN -d $CLASS_D_MULTICAST -j DROP
#$IPTABLES -A INPUT -i $MAINT -d $CLASS_D_MULTICAST -j DROP

# Refuse Class E reserved IP addresses. 
$IPTABLES -A INPUT -i $WAN -s $CLASS_E_RESERVED_NET -j DROP 
$IPTABLES -A INPUT -i $LAN -s $CLASS_E_RESERVED_NET -j DROP 
#$IPTABLES -A INPUT -i $MAINT -s $CLASS_E_RESERVED_NET -j DROP 

# Refuse packets claiming to be to the loopback interface. 
# Refusing packets claiming to be to the loopback interface 
# protects against source quench, whereby a machine can be told 
# to slow itself down by an icmp source quench to the loopback. 
$IPTABLES -A INPUT  -i $WAN -d $LOOPBACK -j DROP 
$IPTABLES -A INPUT  -i $LAN -d $LOOPBACK -j DROP 
#$IPTABLES -A INPUT  -i $MAINT -d $LOOPBACK -j DROP 

## SSH 
# Allow ssh inbound only
echo "SSH"
$IPTABLES -A INPUT  -i $WAN -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT 
$IPTABLES -A OUTPUT -o $WAN -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT 
$IPTABLES -A INPUT  -i $LAN -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT 
$IPTABLES -A INPUT  -i $LAN -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT 
#$IPTABLES -A INPUT  -i $MAINT -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT 
#$IPTABLES -A INPUT  -i $MAINT -p tcp --dport $SSH_PORT -m state --state NEW -j ACCEPT 

## AUTH server 
# Reject ident probes with a tcp reset. 
# Needed for a mailhost that won't accept or delays
# mail if we just drop its ident probe. 
#$IPTABLES -A INPUT -i $WAN -p tcp --dport 113 -j REJECT --reject-with tcp-reset

# ICMP 
# We accept some icmp requests including pings 
#$IPTABLES -A INPUT  -i $WAN -p icmp --icmp-type destination-unreachable -j ACCEPT 
#$IPTABLES -A INPUT  -i $WAN -p icmp --icmp-type time-exceeded           -j ACCEPT 
#$IPTABLES -A INPUT  -i $WAN -p icmp --icmp-type echo-request            -j ACCEPT 
$IPTABLES -A INPUT  -i $WAN -p icmp --icmp-type echo-reply              -j ACCEPT 
#$IPTABLES -A INPUT  -i $LAN -p icmp --icmp-type destination-unreachable -j ACCEPT 
#$IPTABLES -A INPUT  -i $LAN -p icmp --icmp-type time-exceeded           -j ACCEPT 
#$IPTABLES -A INPUT  -i $LAN -p icmp --icmp-type echo-request            -j ACCEPT 
$IPTABLES -A INPUT  -i $LAN -p icmp --icmp-type echo-reply              -j ACCEPT 
#$IPTABLES -A INPUT  -i $MAINT-p icmp --icmp-type destination-unreachable -j ACCEPT 
#$IPTABLES -A INPUT  -i $MAINT-p icmp --icmp-type time-exceeded           -j ACCEPT 
#$IPTABLES -A INPUT  -i $MAINT-p icmp --icmp-type echo-request            -j ACCEPT 
#$IPTABLES -A INPUT  -i $MAINT-p icmp --icmp-type echo-reply              -j ACCEPT 
# We always allow icmp out. 
$IPTABLES -A OUTPUT -o $WAN -p icmp -j ACCEPT 

# Drop some stuff without logging
## NETBIOS
#echo "Netbios"
$IPTABLES -A INPUT -i $WAN -p udp --dport $NETBIOS -j DROP
$IPTABLES -A INPUT -i $LAN -p udp --dport $NETBIOS -j DROP
$IPTABLES -A INPUT -i $MAINT -p udp --dport $NETBIOS -j DROP

# Other stuff from MS we don't want to log
$IPTABLES -A INPUT -i $WAN -p tcp --dport 445 -j DROP
$IPTABLES -A INPUT -i $WAN -p tcp --dport 135 -j DROP
$IPTABLES -A INPUT -i $LAN -p tcp --dport 445 -j DROP
$IPTABLES -A INPUT -i $LAN -p tcp --dport 135 -j DROP
$IPTABLES -A INPUT -i $MAINT -p tcp --dport 445 -j DROP
$IPTABLES -A INPUT -i $MAINT -p tcp --dport 135 -j DROP

# While we are at it drop this one too.  I'm not sure what
# its from, but I think its Oracle
$IPTABLES -A INPUT -i $WAN -p tcp --dport 1433 -j DROP
$IPTABLES -A INPUT -i $LAN -p tcp --dport 1433 -j DROP
$IPTABLES -A INPUT -i $MAINT -p tcp --dport 1433 -j DROP

# After smb, we can now refuse broadcast address packets. 
$IPTABLES -A INPUT -i $WAN -d $BROADCAST -j LOG --log-level 6
$IPTABLES -A INPUT -i $WAN -d $BROADCAST -j DROP 
$IPTABLES -A INPUT -i $LAN -d $BROADCAST -j LOG --log-level 6
$IPTABLES -A INPUT -i $LAN -d $BROADCAST -j DROP 
$IPTABLES -A INPUT -i $MAINT -d $BROADCAST -j LOG --log-level 6
$IPTABLES -A INPUT -i $MAINT -d $BROADCAST -j DROP

## LOGGING 
# You don't have to split up your logging like we do below, 
# but this way we can grep for things in the logs more easily.
# Any udp not already allowed is logged and then dropped. 
$IPTABLES -A INPUT  -i $WAN -p udp -j LOG --log-prefix "IPTABLES UDP-IN: " --log-level 6
$IPTABLES -A INPUT  -i $WAN -p udp -j DROP 
$IPTABLES -A OUTPUT -o $LAN -p udp -j LOG --log-prefix "IPTABLES UDP-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $LAN -p udp -j DROP 
$IPTABLES -A OUTPUT -o $MAINT -p udp -j LOG --log-prefix "IPTABLES UDP-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $MAINT -p udp -j DROP 

# Any icmp not already allowed is logged and then dropped. 
$IPTABLES -A INPUT  -i $WAN -p icmp -j LOG --log-prefix "IPTABLES ICMP-IN: " --log-level 6
$IPTABLES -A INPUT  -i $WAN -p icmp -j DROP 
$IPTABLES -A OUTPUT -o $WAN -p icmp -j LOG --log-prefix "IPTABLES ICMP-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $WAN -p icmp -j DROP 
$IPTABLES -A INPUT  -i $LAN -p icmp -j LOG --log-prefix "IPTABLES ICMP-IN: " --log-level 6
$IPTABLES -A INPUT  -i $LAN -p icmp -j DROP 
$IPTABLES -A OUTPUT -o $LAN -p icmp -j LOG --log-prefix "IPTABLES ICMP-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $LAN -p icmp -j DROP 
$IPTABLES -A INPUT  -i $MAINT -p icmp -j LOG --log-prefix "IPTABLES ICMP-IN: " --log-level 6
$IPTABLES -A INPUT  -i $MAINT -p icmp -j DROP 
$IPTABLES -A OUTPUT -o $MAINT -p icmp -j LOG --log-prefix "IPTABLES ICMP-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $MAINT -p icmp -j DROP 

# Any tcp not already allowed is logged and then dropped. 
$IPTABLES -A INPUT  -i $WAN -p tcp -j LOG --log-prefix "IPTABLES TCP-IN: " --log-level 6
$IPTABLES -A INPUT  -i $WAN -p tcp -j DROP 
$IPTABLES -A OUTPUT -o $WAN -p tcp -j LOG --log-prefix "IPTABLES TCP-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $WAN -p tcp -j DROP 
$IPTABLES -A INPUT  -i $LAN -p tcp -j LOG --log-prefix "IPTABLES TCP-IN: " --log-level 6
$IPTABLES -A INPUT  -i $LAN -p tcp -j DROP 
$IPTABLES -A OUTPUT -o $LAN -p tcp -j LOG --log-prefix "IPTABLES TCP-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $LAN -p tcp -j DROP 
$IPTABLES -A INPUT  -i $MAINT -p tcp -j LOG --log-prefix "IPTABLES TCP-IN: " --log-level 6
$IPTABLES -A INPUT  -i $MAINT -p tcp -j DROP 
$IPTABLES -A OUTPUT -o $MAINT -p tcp -j LOG --log-prefix "IPTABLES TCP-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $MAINT -p tcp -j DROP 

# Anything else not already allowed is logged and then dropped. 
# It will be dropped by the default policy anyway ........ 
# but let's be paranoid. 
$IPTABLES -A INPUT  -i $WAN -j LOG --log-prefix "IPTABLES PROTOCOL-X-IN: " --log-level 6
$IPTABLES -A INPUT  -i $WAN -j DROP 
$IPTABLES -A OUTPUT -o $WAN -j LOG --log-prefix "IPTABLES PROTOCOL-X-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $WAN -j DROP 
$IPTABLES -A INPUT  -i $LAN -j LOG --log-prefix "IPTABLES PROTOCOL-X-IN: " --log-level 6
$IPTABLES -A INPUT  -i $LAN -j DROP 
$IPTABLES -A OUTPUT -o $LAN -j LOG --log-prefix "IPTABLES PROTOCOL-X-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $LAN -j DROP 
$IPTABLES -A INPUT  -i $MAINT -j LOG --log-prefix "IPTABLES PROTOCOL-X-IN: " --log-level 6
$IPTABLES -A INPUT  -i $MAINT -j DROP 
$IPTABLES -A OUTPUT -o $MAINT -j LOG --log-prefix "IPTABLES PROTOCOL-X-OUT: " --log-level 6
$IPTABLES -A OUTPUT -o $MAINT -j DROP
