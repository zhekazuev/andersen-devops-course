#!/bin/bash

#netstat -tunapl | awk '/firefox/ {print $5}' | cut -d: -f1 | sort | uniq -c | sort | tail -n5 | 
# grep -oP '(\d+\.){3}\d+' | while read IP ; do whois $IP | grep 'Organization' ; done

# -p --pid pid
# -a --app app
# -c --count count

# Examples
# ./script.sh -p 10 -a firefox -c 10
# ./script.sh --pid 10 --app firefox --count 10
# ./script.sh -p 10 -a firefox -c 10 -m
# ./script.sh --pid 10 --app firefox --count 10 --more

# Use oprions
ARGS=$(getopt -a --options p:a:c:m  --long "pid:,app:,count:,more" -- "$@")
eval set -- "$ARGS"
while true; do
  case "$1" in
    -p|--pid)
      pid="$2"
      shift 2;;
    -a|--app)
      app="$2"
      shift 2;;
	-c|--count)
      count="$2"
      shift 2;;
	-m|--more)
      more="true"
      shift;;
    --)
      break;;
     *)
      printf "Unknown option %s\n" "$1"
      exit 1;;
  esac
done

# Start netstat
netstat_out=$(netstat -tunapl)

# Choose application
if [ -n "$app" ]; then
	awk_out=$(echo "$netstat_out" | awk -v app="$app" '$0~app {print $5}')
else
    awk_out=$(echo "$netstat_out" | awk '/firefox/ {print $5}')
fi

# Cut and sort data
cut_out=$(echo "$awk_out" | cut -d: -f1 | sort | uniq -c | sort)

# Change lines count
if [ -n "$count" ]; then
	tail_out=$(echo "$cut_out" | tail -n "$count")
else
    tail_out=$(echo "$cut_out" | tail -n 5)
fi

# Get IP addresses and checks
ips_list=$(echo "$tail_out" | grep -oP '(\d+\.){3}\d+')
if [ -n "$ips_list" ]; then
	while read IP ; do
    	organization=$(whois $IP | grep 'Organization');
    	if [ -n "$organization" ]; then
        	echo "$organization : $IP" ;
			if [[ "$more" == "true" ]]
			then
  				echo "Other info about IP:" ;
				whois $IP | awk '/:  / {print $1 " " $2}' ;
			fi
    	else
        	organisation=$(whois $IP | grep 'role');
        	echo "$organisation : $IP" ;
			if [[ "$more" == "true" ]]
			then
  				echo "Other info about IP:" ;
				whois $IP | awk '/:  / {print $1 " " $2}' ;
			fi
    	fi
	done <<< "$ips_list"
else
	echo "IP list for $app-application is empty" ;
fi
