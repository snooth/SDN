#!/bin/shhttps://github.com/snooth/SDN_NFV

apt install tshark nc -y

## Netcat listen (-l) listen to port 8888 and PIPE traffic to a Kafka producer script. 
nc -l 8888 | ./producer.sh &

# Wait to load
sleep 5

# Listen to packetcature and PIPE Tshark packetcapture to netcat. 
tshark -l | nc 127.1 8888
