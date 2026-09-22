#!/bin/sh
#
ab -n 1000000 -c 1000 http://10.0.1.110/ &
ab -n 1000000 -c 1000 http://10.0.1.110/ &
ab -n 1000000 -c 1000 http://10.0.1.110/ &
ab -n 1000000 -c 1000 http://10.0.1.110/ &
ab -n 1000000 -c 1000 http://10.0.1.110/ &
ab -n 1000000 -c 1000 http://10.0.1.110/ &
ab -n 1000000 -c 1000 http://10.0.1.110/ &
ab -n 1000000 -c 1000 http://10.0.1.110/ &

for i in {1..10000}; do curl -s http://10.0.1.110/ > /dev/null & done
for i in {1..10000}; do curl -s http://10.0.1.110/ > /dev/null & done
for i in {1..10000}; do curl -s http://10.0.1.110/ > /dev/null & done
for i in {1..10000}; do curl -s http://10.0.1.110/ > /dev/null & done
