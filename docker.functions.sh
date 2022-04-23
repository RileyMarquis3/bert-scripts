docker.quota.enable() {
	# put the diff directory /var/lib/docker/aufs/diff/$CONTAINER_ID into
	# a sparse loopback mounted ext4 directory.
	# This effectively limits the amount of data a user can store/modify in a container.
    local ID=$1
    local QUOTA_MB=$2

    local LOOPBACK=/var/lib/docker/aufs/diff/$ID-loopback
    local LOOPBACK_MOUNT=/var/lib/docker/aufs/diff/$ID-loopback-mount
    local DIFF=/var/lib/docker/aufs/diff/$ID

    docker stop -t=0 $ID
    sudo dd of=$LOOPBACK bs=1M seek=$QUOTA_MB count=0
    sudo mkfs.ext4 -F $LOOPBACK
    sudo mkdir -p $LOOPBACK_MOUNT
    sudo mount -t ext4 -n -o loop,rw $LOOPBACK $LOOPBACK_MOUNT
    sudo rsync -rtv $DIFF/ $LOOPBACK_MOUNT/
    sudo rm -rf $DIFF
    sudo mkdir -p $DIFF
    sudo umount $LOOPBACK_MOUNT
    sudo rm -rf $LOOPBACK_MOUNT
    sudo mount -t ext4 -n -o loop,rw $LOOPBACK $DIFF
    docker start $ID
}

docker.image.shell(){

	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --image_id [docker image id]";return 1
	fi	
	SHELL="/bin/sh"
	while (( "$#" )); do
	    if [[ "$1" =~ .*--image_id.* ]]; then local IMAGE_ID=$2;fi    
	    if [[ "$1" =~ .*--shell.* ]]; then local SHELL=${2};fi    
	    if [[ "$1" =~ .*--dry.* ]]; then local DRY_RUN="true";fi
	    shift
	done
	docker run -i -t --entrypoint ${SHELL} ${IMAGE_ID}

}

docker.pull_pack_push(){
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --images {{LIST_OF_COMMA_SEPARATED_IMAGES}} --host {{TARGET_HOST}} --path {{TARGET_PATH}} [--dry]";return 1
	fi
	PREFIX=""	
	TARGET_PATH="/home/${USERNAME}"
	while (( "$#" )); do
	    if [[ "$1" =~ .*--images.* ]]; then local IMAGES=$2;fi    
	    if [[ "$1" =~ .*--host.* ]]; then local TARGET_HOST=${2};fi    
	    if [[ "$1" =~ .*--path.* ]]; then local TARGET_PATH=${2};fi    
	    if [[ "$1" =~ .*--load.* ]]; then local LOAD="true";fi
	    if [[ "$1" =~ .*--dry.* ]]; then local DRY_RUN="true";PREFIX=echo;fi
	    shift
	done
	set -u
	shopt -s extglob
	echo -e "${IMAGES}" | tr ',' '\n' | while read image;do 
		if ! ${PREFIX} docker pull "${image}";then
			echo "Warning: Failed to pull image ${image}\!"
		fi
		output_image="${image//@(\/|:)/_}.tar"
		echo "Saving ${image} to ${output_image}"
		if ! ${PREFIX} docker save -o "${output_image}" "${image}";then
			echo "Failed to save image ${output_image}\!"
			return 1
		fi
		${PREFIX} scp "${output_image}" "${TARGET_HOST}:${TARGET_PATH}"
		if $LOAD;then ${PREFIX} ssh "${TARGET_HOST}" "sudo docker load -i ${output_image}";fi
	done
	echo 'Done!'
}


docker.machine.prep.cisco_anyconnect(){

	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --vm-name [vm_name]";return 1
	fi
	PREFIX=""
	HOST_DOCKER_DAEMON_PORT=2376
	while (( "$#" )); do
	    if [[ "$1" =~ .*--vm-name.* ]]; then local DM_HOSTNAME=$2;fi    
	    if [[ "$1" =~ .*--ip-address.* ]]; then local DM_IPADDRESS=${2};fi    
	    if [[ "$1" =~ .*--dry.* ]]; then local PREFIX="echo";fi
	    shift
	done
	if [[ -z $(docker-machine ls -q $DM_HOSTNAME) ]];then docker-machine create $DM_HOSTNAME;fi
	if [[ -z $DM_IPADDRESS ]];then IPADDRESS=$(docker-machine ip $DM_HOSTNAME);fi
	$PREFIX docker-machine stop $DM_HOSTNAME
	if [ $os_is_windows ];then
		vboxmanage=/c/Progra~1/Oracle/VirtualBox/vboxmanage
	elif [ $os_is_osx ];then 
		vboxmanage=VBoxManage
	fi
	# $PREFIX "${vboxmanage}" modifyvm "$DM_HOSTNAME" --natpf1 "docker,tcp,127.0.0.1,2376,,2376"
	$PREFIX "${vboxmanage}" controlvm ${DM_HOSTNAME} natpf1 dockerdaemon,tcp,127.0.0.1,${HOST_DOCKER_DAEMON_PORT},,2376
	# $PREFIX "${vboxmanage}" modifyvm "$DM_HOSTNAME" --natpf1 "docker,tcp,${DM_IPADDRESS},2376,,2376"
	$PREFIX docker-machine start $DM_HOSTNAME
	# docker-machine regenerate-certs "$DM_HOSTNAME"
	DOCKER_MACHINES_HOME=${HOME}/.docker/machine/machines
	DOCKER_CERTS_HOME=${HOME}/.docker/machine/certs
	SERVER_PEM_LOCATION=/var/lib/boot2docker/server.pem
	SERVER_PEM=$(docker-machine ssh ${DM_HOSTNAME} "openssl x509 -noout -text -in ${SERVER_PEM_LOCATION}")
	if [[ ${SERVER_PEM} != *"CN=localhost"* && ${SERVER_PEM} != *"IP:127.0.0.1"* ]]; then
	    #(Re)create the cert if it's missing localhost or 127.0.0.1
	    echo "=====[${DM_HOSTNAME}] Creating a new Docker daemon certificate====="
	    #Let's be good citizens.  Preserve the original cert and re-use the private key.
	    if [[ -f ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/server.pem ]];then
	    	yes | mv ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/server.pem ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/server.pem.bak
		fi
	    #Create a new cert for the Docker daemon and sign it
	    if [ $os_is_windows ];then
	    	SUBJ="//CN=localhost"
	    elif [ $os_is_osx ];then
	    	SUBJ="/CN=localhost"
	    fi
	    openssl req -subj "${SUBJ}" -sha256 -new -key ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/server-key.pem -out ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/server.csr
	    echo "subjectAltName = IP:$(docker-machine ip ${DM_HOSTNAME}),IP:127.0.0.1" > ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/extfile.cnf
	    openssl x509 -req -days 365 -sha256 -in ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/server.csr -CA ${DOCKER_CERTS_HOME}/ca.pem -CAkey ${DOCKER_CERTS_HOME}/ca-key.pem -set_serial 0x6f6e656a6c69 -out ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/server.pem -extfile ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/extfile.cnf
	    #Deploy the new cert to the Docker host and restart the Docker daemon to pick up the change
	    echo "=====[${DM_HOSTNAME}] Deploying Certificate to Docker host====="
	    NEW_SERVER_PEM=`cat ${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}/server.pem`
	    docker-machine ssh ${DM_HOSTNAME} "echo -e '${NEW_SERVER_PEM}' | sudo tee ${SERVER_PEM_LOCATION}"
	    echo "=====[${DM_HOSTNAME}] Restarting Docker daemon====="
	    docker-machine ssh ${DM_HOSTNAME} "sudo /etc/init.d/docker restart"
	fi	
	echo "=====Initializing Docker ENV Variables====="
	export DOCKER_TLS_VERIFY=1
	export DOCKER_HOST="tcp://localhost:${HOST_DOCKER_DAEMON_PORT}"
	export DOCKER_CERT_PATH="${DOCKER_MACHINES_HOME}/${DM_HOSTNAME}"
	export DOCKER_MACHINE_NAME="${DM_HOSTNAME}"	
}


docker.host.switch(){

	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --host [fqdn/ip] --port [docker_daemon_port] --cert-path [/path/to/docker/certs]";return 1
	fi
	PREFIX=""
	DM_PORT=2376
	DM_CERT_TLS_VERIFY=1
	DOCKER_MACHINE_NAME=docker
	while (( "$#" )); do
	    if [[ "$1" =~ .*--host.* ]]; then local DM_HOSTNAME=$2;fi    
	    if [[ "$1" =~ .*--port.* ]]; then local DM_PORT=${2};fi    
	    if [[ "$1" =~ .*--cert-path.* ]]; then local DM_CERT_PATH=${2};fi    
	    if [[ "$1" =~ .*--cert-tls-verify.* ]]; then local DM_CERT_TLS_VERIFY=${2};fi
	    if [[ "$1" =~ .*--dry.* ]]; then local PREFIX="echo";fi
	    shift
	done
	$PREFIX export DOCKER_HOST="tcp://${DM_HOSTNAME}:${DM_PORT}"
	$PREFIX export DOCKER_CERT_PATH="${DM_CERT_PATH}"
	$PREFIX export DOCKER_TLS_VERIFY=$DM_CERT_TLS_VERIFY
	$PREFIX export DOCKER_MACHINE_NAME="${DOCKER_MACHINE_NAME}"
}

docker.destroy(){
 echo "${*}" | tr ' ' '\n' | while read c;do
  docker stop $c && docker rm $c;
 done
}

# aliases
alias docker.ps="docker ps --format 'table{{.Names}}\t{{.ID}}\t{{.Status}}\t{{.Ports}}'"