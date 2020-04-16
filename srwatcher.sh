#!/bin/bash

VERSION="0.2"

# Verifying that parameters were given
if [ -z "$1" -o -z "$2" ]; 
then
    echo "Simple Resource Watcher. Version: "$VERSION
    echo "Author: Veronica Valeros (vero.valeros@gmail.com)"
    echo
    echo "usage: $0 [interface] [slack.auth]"
    echo "e.g. $0 eth0 slack.auth"
    echo
    echo "Log stored at srwatcher.log"
    exit
fi

# Reading parameters
INTERFACE=$1
AUTH=$2

# Sourcing the configuration file
. $AUTH

# The following variables are now loaded
# $slack_webhook
# $slack_channel
# $slack_thumb_url

# slack_alert: function to post a given text message to slack.
slack_alert (){
    PAYLOAD="payload={
        \"channel\": \"#$slack_channel\",
        \"username\": \"Simple Resource Watcher\",
        \"text\": \"Alert from *$(hostname)*:\",
        \"icon_emoji\": \":robot_face:\",
        \"attachments\": [
                {
                    \"text\": \"$1\",
                    \"color\": \"#ff0000\",
                    \"footer\": \"Simple Resource Watcher\",
                    \"thumb_url\": \"$slack_thumb_url\",
                }
            ]
    }"
    curl -s -X POST --data-urlencode "$PAYLOAD" $slack_webhook
}

# Measuring Memory Usage: FREEMEM contains the available RAM Memory given by free based on /proc/meminfo.
FREEMEM=$(free -g | grep Mem | awk '{print $7}')
MEM_MESSAGE="Available RAM: *$FREEMEM GB*"

# Measuring Network Bandwith
R1=`cat /sys/class/net/$1/statistics/rx_bytes`
T1=`cat /sys/class/net/$1/statistics/tx_bytes`
sleep 1
R2=`cat /sys/class/net/$1/statistics/rx_bytes`
T2=`cat /sys/class/net/$1/statistics/tx_bytes`

TBPS=`expr $T2 - $T1`
RBPS=`expr $R2 - $R1`

TKBPS=`expr $TBPS / 1024`
RKBPS=`expr $RBPS / 1024`

NET_MESSAGE="Network Download: *$RKBPS kB/s* \n Network Upload: *$TKBPS kB/s*"

# Measuring Temperature
TEMP=`sensors 2>/dev/null |grep temp1 |awk '{print $2}'|awk -F+ '{print $2}'|awk -F. '{print $1}'`
TEMP_MESSAGE="Current Temperature: *$TEMP °C*"

# Listing the top memory consuming processes
IFS=$'\n'
PROC_MESSAGE=""
for i in $(ps -axo user,pid,pcpu,pmem,comm --sort=-%mem |head -n 6 |  cut -c -100);
do
    PROC_MESSAGE=$PROC_MESSAGE$i"\n"
done

# ALERT IF: the bandwidth is more than 30,000 KBPS or the available memory is less than 4 GB or the temperature is greater than 92C
if [ "$FREEMEM" -le 4 ] || [ "$TKBPS" -gt 30000 ] || [ "$TEMP" -gt 92 ]
then
   slack_alert "$NET_MESSAGE \n $MEM_MESSAGE \n $TEMP_MESSAGE."
fi

# LIST MEMORY CONSUMING PROCESSES IF: the available memory is less than 4 GB
if [ "$FREEMEM" -le 4 ] 
then
    PROC_MESSAGE_SLACK="\`\`\`"$PROC_MESSAGE"\`\`\`"
    slack_alert "$PROC_MESSAGE"
fi

#COMMAND LINE OUTPUT
echo "$(date +"%Y/%m/%d %T"), $NET_MESSAGE, $MEM_MESSAGE, $TEMP_MESSAGE." 
echo "$(date +"%Y/%m/%d %T"), $NET_MESSAGE, $MEM_MESSAGE, $TEMP_MESSAGE." >> srwatcher.log
