#!/usr/local/env bash

slack.message(){
	MESSAGE="${1}"
	USERNAME="${USER}-bot"
	CHANNEL="${2}"
	PAYLOAD="payload={\"channel\": \"$CHANNEL\", \"username\": \"$USERNAME\", \"text\": \"$MESSAGE\"}"
	curl -X POST --data "$PAYLOAD" $SLACK_URL
}

mac.message(){
	usage="""Usage: 
	${FUNCNAME[0]} --hostname [Hostname/IP] --runas [Remote_Username] --message [text] --loginas [Remote_Admin_Username]"""	
	if [[ ($# -lt 3) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--hostname.* ) || ( "$1" == -h ) ]]; then HOSTNAME="${2}";fi	    	
	    if [[ ( "$1" =~ .*--runas.* ) || ( "$1" == -r ) ]]; then RUNAS="${2}";fi
	    if [[ ( "$1" =~ .*--message.* ) || ( "$1" == -m ) ]]; then MESSAGE="${2}";fi
	    if [[ ( "$1" =~ .*--loginas.* ) || ( "$1" == -u ) ]]; then LOGIN_AS="${2}";fi
	    shift
	done	
	command="""sudo /bin/launchctl asuser \"${RUNAS}\" /usr/bin/osascript -e 'set the answer to text returned of (display dialog \"${MESSAGE}\" default answer \"\" buttons {\"Continue\"})' 2> /dev/null"""
	ssh ${LOGIN_AS}@${HOSTNAME} "${command}" 2> /dev/null
}