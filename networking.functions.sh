## networking

# TODO Fix this function, as os_is_osx evals to true, even on windows hosts (i think)
ip.list () { 
  if [[ $os_is_osx ]]; then 
    ifconfig | grep -vw inet6 | grep -w inet | cut -d: -f2 | cut -d'\' -f1
  elif [[ $os_is_linux ]]; then
    ip -4 -o addr | grep -vie '127\|loop'
  elif [[ $os_is_windows ]]; then
    wmic nicconfig where ipenabled=true get description,ipaddress
  fi
}

host.getip () { 
  if [[ "$1" =~ http://* ]];then 
    node=${1#h*//}
    node=${node%/}
  elif [[ "$1" =~ www* ]];then 
    node=${1#**.}
  else 
    node=$1
  fi
  nodeip=$(dig +short $node)
  if [[ -z $nodeip ]];then
    echo $node | while read node;do
      nodeip=$(echo $node | $NIPAP_HOME/nipap.py);
      nodeip=${nodeip%/**};
      echo ${nodeip#**:}
    done
  else
    echo $nodeip
  fi
   
}

host.tcp.send()
{
  if [[ -z "$1" ]]; then
    echo "Usage: send host stuff [...]"
    return
  fi
  DEST=$1
  shift
  BYTES=$(du -csb "${@}" | tail -1 | cut -f1)

  tar -cpf - "${@}" | pv -epbrs $BYTES | nc -4q 3 -T throughput $DEST 6502
}

port.scan(){ 
  usage="Usage: 
  ${FUNCNAME[0]} <host> <port>
  or 
  ${FUNCNAME[0]} <host> --deep
  "
  if [[ $os_is_windows ]];then sudo='';fi
  [ $# -lt 1 ] && echo -e "${usage}" && return 1  
  [ $# == 2 ]  && $sudo nmap -p $2 $1
  if [[ "$*" =~ .*--deep.* ]];then
    $sudo nmap -Pn -n -sS -p- -sV --min-hostgroup 255 --min-rtt-timeout \
     25ms --max-rtt-timeout 100ms --max-retries 1 \
     --max-scan-delay 0 --min-rate 1000 -vvv --open $1
  fi
}

port.test(){
  if [[ $os_is_windows ]];then 
    powershell -command "(New-Object System.Net.Sockets.TcpClient).Connect('${1}', ${2})" 2>/dev/null
    (( $? == 0 )) && echo 'Open' || echo 'Closed'
  else
    server=$1; port=$2; proto=${3:-tcp}
    exec 5<>/dev/$proto/$server/$port
    (( $? == 0 )) && echo 'Open' || echo 'Closed'
    # && exec 5<&-
  fi
}

network.routing.reset() {
  # Reset routing table on OSX
  # display current routing table
  echo "********** BEFORE ****************************************"
  netstat -r
  echo "**********************************************************"
  for i in {0..4}; do
    sudo route -n flush # several times
  done
  echo "********** AFTER *****************************************"
  netstat -r
  echo "**********************************************************"
  echo "Bringing interface down..."
  sudo ifconfig en1 down
  sleep 1
  echo "Bringing interface back up..."
  sudo ifconfig en1 up
  sleep 1
  echo "********** FINALLY ***************************************"
  netstat -r
  echo "**********************************************************"
}

alias reset-networking="sudo -s -- 'killall Network\ Connect ; networksetup -setv4off Wi-Fi ; networksetup -setdhcp Wi-Fi'"
alias ports='netstat -tulanp'
alias myip='curl ip.appspot.com'                    # myip:         Public facing IP Address
alias netCons='lsof -i'                             # netCons:      Show all open TCP/IP sockets
alias flushDNS='dscacheutil -flushcache'            # flushDNS:     Flush out the DNS Cache
alias lsock='sudo /usr/sbin/lsof -i -P'             # lsock:        Display open sockets
alias lsockU='sudo lsof -nP | grep UDP'   # lsockU:       Display only open UDP sockets
alias lsockT='sudo lsof -nP | grep TCP'   # lsockT:       Display only open TCP sockets
alias ipInfo0='ipconfig getpacket en0'              # ipInfo0:      Get info on connections for en0
alias ipInfo1='ipconfig getpacket en1'              # ipInfo1:      Get info on connections for en1
alias openPorts='sudo lsof -i | grep LISTEN'        # openPorts:    All listening connections
alias showBlocked='sudo ipfw list'                  # showBlocked:  All ipfw rules inc/ blocked IPs
#Control Home Router
#The curl command can be used to reboot Linksys routers.
# Reboot my home Linksys WAG160N / WAG54 / WAG320 / WAG120N Router / Gateway from *nix.
function rebootlinksys() {
  "curl -u "$routerUsername:$routerPassword" http://$routerHostName/setup.cgi?todo=reboot"
}
# Reboot tomato based Asus NT16 wireless bridge 
function reboottomato() {
  ssh $routerUsername@${routerHostName} /sbin/reboot
}
#Resume wget by default
alias wget='wget -c'

## refresh nfs mount / cache etc for Apache ##
alias nfsrestart='sync && sleep 2 && /etc/init.d/httpd stop && umount netapp2:/exports/http && sleep 2 && mount -o rw,sync,rsize=32768,wsize=32768,intr,hard,proto=tcp,fsc natapp2:/exports /http/var/www/html &&  /etc/init.d/httpd start'

#Firewall (iptables)
alias iptlist='sudo /sbin/iptables -L -n -v --line-numbers'
alias iptlistin='sudo /sbin/iptables -L INPUT -n -v --line-numbers'
alias iptlistout='sudo /sbin/iptables -L OUTPUT -n -v --line-numbers'
alias iptlistfw='sudo /sbin/iptables -L FORWARD -n -v --line-numbers'
alias firewall=iptlist
alias allow-tcp=allow-tcp