# Created by SnoopDog 27 Aug 2015
# Modified for RPI
# SnoopDogg - (03) 8649 3360 - sam.nuth@team.telstra.com.au
# Installs/Configures pptp-linux
# Creates all the VPN configuration files and puts in all the required locations.
# Creates an init.d script to autoload all the routes and start the vpn service. 
# Version 5.8

## GLOBAL VARIABLES
LOG_FILE="/home/stack/install_log.log"
vCPE="vCPE"

## NO PASSWORD SUDO FOR ALL USERS
sudo echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

## UNINSTALL NETWORK-MANAGER
#sudo apt-get remove network-manager -y

# Find CPU type
CPU=$(cat /proc/cpuinfo | grep -m1 "model name"| awk '{print $4}')

# MetricBeat & Docker installation
# Check if CPU type = ARMv7 then ignore MetricBeat Installation
if test "$CPU" = "ARMv7"
then
    echo "***************************************"
    echo "ARMv7 CPU - NOT installing MetricBeats, Collectd will be used for health metrics"
    echo "***************************************"
    echo "Installing CollectD and Docker CE for ARM"
    echo "***************************************"
    apt update -y
    apt install collectd -y
    # Common tools installation
    sudo apt-get update -y
    #sudo apt-get install syslog-ng net-tools vim snmpd usb-modeswitch pptp-linux lm-sensors -y
    sudo apt-get install openssh-server rsyslog net-tools vim snmpd pptp-linux openvswitch-switch wvdial -y
    # Install docker
    echo "***************************************"
    echo "Installing Docker on x86 Host"
    echo "***************************************"
    sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y

    curl -sSL https://get.docker.com | sh
else
    echo "***************************************"
    echo "X86 Host"
    echo "***************************************"
    # Install metricbeat module for health monitoring
    # Common tools installation
    sudo apt-get update -y
    #sudo apt-get install syslog-ng net-tools vim snmpd usb-modeswitch pptp-linux lm-sensors -y
    sudo apt-get install openssh-server rsyslog net-tools vim snmpd pptp-linux lm-sensors -y
    echo "***************************************"
    echo "Installing MetricBeat on x86 Host"
    echo "***************************************"
    sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    sudo apt-get install apt-transport-https -y
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
    sudo apt-get update && sudo apt-get install metricbeat -y
    sudo update-rc.d metricbeat defaults 95 10
    sleep 5
    # Install docker
    echo "***************************************"
    echo "Installing Docker on x86 Host"
    echo "***************************************"
    sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli docker-compose containerd.io -y
fi

#usb_modeswitch -v 12d1 -p 1f01 -M '55534243123456780000000000000011062000000101000100000000000000'

### CHANGE USERNAME FOR EACH CPE
VPN_USER="test1"
VPN_PASS="Sn00p"
VPN_SERVER="203.42.246.228"
#MGMT_INT="eth2"
#WAN_INT="eth1"
#LAN_INT="eth0"


## EDIT THE /ETC/NETWORK/INTERFACES
#rm -rf /etc/network/interfaces
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# This is the MGMT interface
#auto $MGMT_INT
#iface $MGMT_INT inet dhcp

# This is the WAN interface
#auto $WAN_INT
#iface $WAN_INT inet dhcp

# This is the LAN interface
#auto $LAN_INT
#iface $LAN_INT inet dhcp
EOF


## EDIT THE /ETC/PPP/OPTIONS FILE
#rm -rf /etc/ppp/options
cat << EOF > /etc/ppp/options
lock
noauth
nobsdcomp
nodeflate
refuse-pap
refuse-eap
refuse-chap
refuse-mschap
EOF

## EDIT THE /ETC/PPP/CHAP-SECRETS FILE
#rm -rf /etc/ppp/chap-secrets
cat << EOF > /etc/ppp/chap-secrets
$VPN_USER       PPTP    $VPN_PASS       *
EOF

## CREATE THE /ETC/PPP/PEERS/$VPN FILE
#rm -rf /etc/ppp/peers/$vCPE
cat << EOF > /etc/ppp/peers/$vCPE
pty "pptp $VPN_SERVER --nolaunchpppd"
name $VPN_USER
remotename PPTP
require-mppe-128
file /etc/ppp/options
ipparam $vCPE
persist
EOF

## CREATE WVDIAL conf file to dialout using Telstra APN
cat << EOF > /etc/wvdial.conf
[Dialer Defaults]
Init1 = ATZ
Init2 = AT&F &D2 &C1
Init3 = ATS7=60 S30=0 S0=0
Init4 = AT+CGDCONT=1,"IP","telstra.extranet"
New PPPD = yes
Modem Type = Analog Modem
Phone = *99#
ISDN = 0
Password = guest
Username = guest
Modem = /dev/ttyUSB2
Baud = 460800
Dial Command = ATD
Stupid Mode = 1
Auto DNS = 1
Check DNS = 0
Carrier Check = yes
EOF

## UPDATE AUTOMATIC ROUTES BACK TO MGMT NETWORK /ETC/PPP/IP-UP FILE
cat << EOF >> /etc/ppp/ip-up
Default routes back to mgmt network
sudo /sbin/route add -net 192.168.90.254 netmask 255.255.255.255 gw 192.168.90.1
sudo /sbin/route add -net 192.168.90.253 netmask 255.255.255.255 gw 192.168.90.1
sudo /sbin/route add -net 192.168.90.252 netmask 255.255.255.255 gw 192.168.90.1
sudo /sbin/route add -net 192.168.90.251 netmask 255.255.255.255 gw 192.168.90.1
sudo /sbin/route add -net 192.168.90.250 netmask 255.255.255.255 gw 192.168.90.1
EOF

## ADD RSYSLOG EXPORTER TO PRIMARY SYSLOG SERVER
cat << EOF >> /etc/rsyslog.conf
*.* @192.168.90.253:514
EOF

## EDIT THE /ETC/SNMP/SNMPD.CONF FILE FOR MANAGMENT MONITORING
#rm -rf /etc/snmp/snmpd.conf
cat << EOF > /etc/snmp/snmpd.conf
com2sec ConfigUser      default         idv90we3rnov90wer
com2sec AllUser         default         public
group   ConfigGroup     v2c             ConfigUser
group   AllGroup        v2c             AllUser
view    SystemView      included        .1.3.6.1.2.1.1
view    SystemView      included        .1.3.6.1.2.1.25.1.1
view    AllView         included        .1
access  ConfigGroup     ""      any     noauth  exact   SystemView      none    none
access  AllGroup        ""      any     noauth  exact   AllView         none    none
EOF


## EDIT THE /ETC/RC.LOCAL FILE TO AUTO REJOIN OPENSTACK
#rm -rf /etc/rc.local
cat << EOF > /etc/rc.local
#!/bin/sh -e

#dhclient eth2
sleep 10
wvdial &
sleep 10
/usr/sbin/pppd call vCPE
sleep 10
/sbin/ifconfig ppp0 mtu 1400
exit 0
EOF

chmod +x /etc/rc.local
#chmod +x /etc/init.d/autostart.sh

## Change to google DNS
sudo /bin/echo "nameserver 8.8.8.8" > /etc/resolv.conf

## START THE VPN SERVER
sudo wvdial &
sudo /usr/bin/pppd call vCPE
sudo /bin/sleep 15

## DISABLE DHCPCD AGENT
sudo systemctl stop dhcpcd
sudo systemctl disable dhcpcd

## RESTART RSYSLOG
sudo service rsyslog restart

## START SSH SERVER ON BOOT
sudo systemctl enable ssh
sudo systemctl start ssh

## Add static routes back to mgmt
sudo /sbin/route add -net 192.168.90.254 netmask 255.255.255.255 gw 192.168.90.1
sudo /sbin/route add -net 192.168.90.253 netmask 255.255.255.255 gw 192.168.90.1
sudo /sbin/route add -net 192.168.90.252 netmask 255.255.255.255 gw 192.168.90.1
sudo /sbin/route add -net 192.168.90.251 netmask 255.255.255.255 gw 192.168.90.1
sudo /sbin/route add -net 192.168.90.250 netmask 255.255.255.255 gw 192.168.90.1

sleep 15
echo " "
echo "**********************************"
echo " "
echo "Your VPN PPP0 Connection is now connected!!!!"
echo "Your VPN IP Address is below:"
echo " "
echo " "
/sbin/ifconfig ppp1 | grep -1 addr
echo " "
echo " "
echo "***************************"
echo "***************************"
echo " "
echo "$(date)"
echo " "
echo "VPN should now be established"
echo "Mgmt routes should now be added"
echo "Network autoload script has been created and added to /etc/init.d/autostart.sh"
echo "If you are using a Huawei Modem as the MGMT_WAN gateway then vi into /etc/init.d/autstart.sh and uncomment the usb_modeswitch commands."
echo "Run the next setupOpenStack.sh script to build Openstack"
echo " "
echo "***************************"



