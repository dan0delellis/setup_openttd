#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
eval "$(systemctl show --no-pager openttd-dedicated.service | grep WorkingDirectory)"
motd="$WorkingDirectory/scripts/on_server_connect.scr"

remaining=$(echo $(date -d "next sunday 03:30" +%s) - $(date +%s) | bc)
days=$(echo $(echo $remaining / 86400 | bc) % 7 | bc)
hours=$(echo "( $remaining % 86400 )" / 3600 | bc)
minutes=$(echo "( $remaining % 3600 )" / 60 | bc)
seconds="00";
msg=
if [ $days != 0 ]; then
    msg="$days days, "
fi
printf  "say \"%s%02d:%02d:%02d until server reset\"\n" $msg $hours $minutes $seconds > $motd;
