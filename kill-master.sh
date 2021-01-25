#!/bin/bash
## kill-master.sh##
master=`sudo docker ps |grep -c master`
online=1

for i in $master
do
if [ $i -eq $online ]
  then sudo docker kill master  && echo "killing old master instance"
  else echo "master not running" | sudo docker rm master &> /dev/null
fi
done

