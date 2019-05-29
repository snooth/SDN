
# SDN-GW-1
# -----------------
sudo ovs-vsctl add-br br-vxlan10
sudo ovs-vsctl set-controller br-vxlan10 tcp:192.168.90.254:6633
sudo ovs-vsctl add-port br-vxlan10 eth1
sudo ip link set br-vxlan10 up
sudo ovs-vsctl add-port br-vxlan10 tun0 -- set interface tun0 type=vxlan options:remote_ip=192.168.100.20 options:key=123

## Tear Down SDN-GW-1
sudo ovs-vsctl del-port br-vxlan10 eth1
sudo ovs-vsctl del-port br-vxlan10 tun0
sudo ovs-vsctl del-br br-vxlan10


# SDN-GW-2
# ----------------
sudo ovs-vsctl add-br br-vxlan10
sudo ovs-vsctl set-controller br-vxlan10 tcp:192.168.90.254:6633
sudo ovs-vsctl add-port br-vxlan10 eth1
sudo ip link set br-vxlan10 up
sudo ovs-vsctl add-port br-vxlan10 tun0 -- set interface tun0 type=vxlan options:remote_ip=192.168.100.10 options:key=123

## Tear Down SDN-GW-2
sudo ovs-vsctl del-port br-vxlan10 eth1
sudo ovs-vsctl del-port br-vxlan10 tun0
sudo ovs-vsctl del-br br-vxlan10
