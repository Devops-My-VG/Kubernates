#!/bin/sh

sudo yum install -y amazon-linux-extras
sudo amazon-linux-extras enable epel
sudo yum install -y epel-release
sudo yum install -y stress stress-ng gcc make git httpd-tools httpd vim siege

stress --cpu $(nproc) --timeout 900 &
stress --cpu $(nproc) --timeout 900 &
stress --cpu $(nproc) --timeout 900 &
stress --cpu $(nproc) --timeout 900 &
stress --cpu $(nproc) --timeout 900 &
stress --cpu $(nproc) --timeout 900 &
stress --cpu $(nproc) --timeout 900 &
stress --cpu $(nproc) --timeout 900 &
stress --cpu $(nproc) --timeout 900 &

CORES=$(nproc)              
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &
sudo stress-ng --cpu $CORES --cpu-load 90 --timeout 900 &

git clone https://github.com/wg/wrk.git
cd wrk
make
sudo cp wrk /usr/local/bin/

for i in {1..10000}; do curl -s http://$IP_ADDR/ > /dev/null & done


