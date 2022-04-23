if [[ $os_is_windows ]];then
	process.kill(){
		if [[ ($# -lt 1) ]]; then 
			echo "Usage: ${FUNCNAME[0]} [process_name]";return 1
		fi			
		taskkill //f //im ${@}
	}
	process.find(){
		if [[ ($# -lt 1) ]]; then 
			echo "Usage: ${FUNCNAME[0]} [process_name]";return 1
		fi		
		tasklist //FI "IMAGENAME eq ${@}"
	}
	process.usage(){
		if [[ ($# -lt 1) ]]; then 
			echo "Usage: ${FUNCNAME[0]} [process name pattern]";return 1
		fi
		powershell -noprofile -command "get-process | Where-Object{ \$_.Name -match '${$1}'} | Group-Object -Property ProcessName | Format-Table Name, @{n='Mem (KB)';e={'{0:N0}' -f ((\$_.Group|Measure-Object WorkingSet -Sum).Sum / 1KB)};a='right'} -AutoSize"
	}
	alias pkill=process.kill
	alias process.ls=process.find
	alias process.mem=process.usage
else
	process.kill.child () {
	    # recursively kill a pid

	    # kill recursive children first
	    CPID=$1
	    CPIDS=$(ps xao ppid,pid | awk '{print $1 " " $2}' | egrep ^"$CPID ")
	    for CCPID in $CPIDS; do
	        if [[ $CCPID != $CPID ]]; then
	            KILL_CHILD $CCPID
	        fi
	    done

	    # kill the primary
	    echo "KILLING $CPID" >> /tmp/test.log
	    kill -9 $CPID
	}
	# aliases
	alias screen.send='screen -dm -S $(date +%m%d%y%H%M%s) -L'
fi


