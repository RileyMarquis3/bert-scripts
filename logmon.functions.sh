logs.histogram(){
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --input [/path/to/file]";return 1
	fi
	while (( "$#" )); do
	    if [[ "$1" =~ .*--input.* ]]; then local INPUT=$2;fi    
	    shift
	done
	cat ${INPUT} | awk '{print substr($0,0,12)}' | uniq -c | sort -nr | awk '{printf("\n%s ",$0) ; for (i = 0; i<$1 ; i++) {printf("*")};}'
}

logs.show(){
  log_names='"Application","System"'
  declare -A params=(
  ["--message-pattern|-p$"]="[message pattern to search for]"
  ["--log-names|-l$"]="[log names to inspect]"
  )
  # Display help if insufficient args
  if [[ $# -lt 1 ]];then 
    help ${FUNCNAME[0]} "${params}";
    return
  fi
  # Parse arguments
  eval $(create_params)
  command="Get-WinEvent -FilterHashtable @{logname=${log_names};StartTime=(get-date).AddDays(-1); EndTime=(get-date).AddHours(-1)} | Where-Object { \$_.Message -Match '${message_pattern}' } | Select-Object -Property TimeCreated, Id, LevelDisplayName, Message"
  eval powershell -noprofile -command "'${command}'"
}

