ssh.get.remote.file(){
	usage="""Usage: ${FUNCNAME[0]} <hostname> </path/to/file"""
	if [[ (! $@) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi
	host=$1
	remote_file=$2
	remote_file_name=${remote_file##*/}
	local_file=${3-$remote_file_name}
	ssh "${host}" "sudo cat ${remote_file}" > $local_file
}