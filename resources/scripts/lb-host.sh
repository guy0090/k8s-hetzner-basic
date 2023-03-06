#!/bin/bash
HOST=$(echo "$1" | awk '{split($0,a,"."); print "static."a[4]"."a[3]"."a[2]"."a[1]".clients.your-server.de"}')
echo "LB_HOST=$HOST" >> /etc/environment
echo "$HOST"