# web
web.listen(){ 
  usage="""Usage: 
  ${FUNCNAME[0]} <PORTNUMBER>"""
  if [[ ($# -lt 1) || ("$*" =~ -h|--help) ]];then echo -e "${usage}";return 0;fi 
  if ! python -m SimpleHTTPServer ${1} 2>/dev/null;then 
    python -m http.server ${1}
  fi
}

alias jcurl='curl -s -f -i -L -o "/dev/stderr" -w "$(date -u +"%F %T,%3NZ") - GET \"%{url_effective}\" %{http_code} %{size_download} %{time_total}\n"'

web.stat.endpoint(){
  if wget -q -nv --spider "${1}"; then 
    echo "SUCCESS: Remote resource exists!"
  else
    echo "ERROR: Remote resource does not exist!"
  fi
}

web.open-url() {
  if [ $os_is_windows ];then
    '/c/Program Files (x86)/Google/Chrome/Application/chrome' "${*}"
  elif [ $os_is_osx ];then 
    /usr/bin/open -a "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "${*}"
  fi  
}

domain.get-commonname() {
  usage="""Usage: 
  ${FUNCNAME[0]} --url [URL] --port [PORTNUMBER]"""  
  if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi 
  PREFIX=""
  PORT="443"
  while (( "$#" )); do
      if [[ "$1" =~ .*--url.* ]]; then URL=$2;fi    
      if [[ "$1" =~ .*--port.* ]]; then PORT=$2;fi    
      if [[ "$1" =~ .*--dry.* ]]; then PREFIX="echo";fi
      shift
  done
  if [[ "${PORT}" == "443" ]];then 
    echo "No port specified, using default: 443"
  fi
	echo | openssl s_client -servername ${URL} -connect $URL:$PORT 2>/dev/null | openssl x509 -noout -subject
}

domain.get-cert() {
  usage="""Usage: 
  ${FUNCNAME[0]} --url [URL] --port [PORTNUMBER]"""  
  if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi 
  PREFIX=""
  PORT="443"
  while (( "$#" )); do
      if [[ "$1" =~ .*--url.* ]]; then URL=$2;fi    
      if [[ "$1" =~ .*--port.* ]]; then PORT=$2;fi    
      if [[ "$1" =~ .*--dry.* ]]; then PREFIX="echo";fi
      shift
  done
  if [[ "${PORT}" == "443" ]];then 
    echo "No port specified, using default: 443"
  fi
  # echo -n | openssl s_client -connect $ip:$port | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' 2>/dev/null
  openssl s_client -showcerts -connect $URL:$PORT </dev/null 2>/dev/null|openssl x509 -outform PEM
}