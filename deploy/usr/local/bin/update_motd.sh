#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
eval "$(systemctl show --no-pager openttd-dedicated.service | grep WorkingDirectory)"
motd="$WorkingDirectory/scripts/on_server_connect.scr"

remaining=$(echo $(date -d "next sunday 03:30" +%s) - $(date +%s) | bc)
days=$(echo $remaining / 86400 | bc)
hours=$(echo "( $remaining % 86400 )" / 3600 | bc)
minutes=$(echo "( $remaining % 3600 )" / 60 | bc)
seconds=$(echo "( $remaining % 60 )" | bc)
echo "say \"$days days, $hours:$minutes:$seconds until server reset\"" > $motd;

