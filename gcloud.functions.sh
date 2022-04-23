KUBECONFIGS="""
~/.kube/pwc-sky-dev-kubeconfig
~/.kube/config
~/.kube/pwc-fso-sandbox-seed-config
~/.kube/pwc-sky-qa-config
~/.kube/sky-sales-staging-config"""
KUBECONFIG=${KUBECONFIGS}

gcloud.initialize(){

	echo "Initializing gcloud aliases ..."
	for project in shit piss fuck; do 
	  namespace="gcloud.cluster.create"
	  alias "${namespace}.${project}=gcloud.cluster.create ${project} $*"
	done

	# gcloud.switch.$account
	for account in $(gcloud auth list --format="value(account)"); do 
	  namespace="gcloud.switch"
	  account=${account//@/-}
	  alias "${namespace}.${account}=gcloud.switch ${account} $*"
	done
	
}

BINARY=brew
if [[ ("$OSTYPE" =~ .*darwin.*) && ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null) || $(which $BINARY))  ]]; then
	# enable bash completion for gcloud
	sdk_path=$(brew info --cask google-cloud-sdk | grep -oiw '\''.*\/usr.*k' | head -1)
	inc=${sdk_path}/latest/google-cloud-sdk/completion.bash.inc
	if ! [[ -x "${inc}" ]];then
		sudo chmod +x "${inc}"
	fi
	[ -f "${inc}" ] && source "${inc}" || true
fi

gcloud.cluster.create(){
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} [project_name] [cluster_name]";return 1
	fi
	if [[ "$*" =~ .*--help.* ]];then echo -e "${usage}";return 0;fi
  	project=${1}
  	cluster_name=${2}
  	zone=${3-us-central1-a}
	gcloud container --project "${project}" \
	clusters create "${cluster_name}" \
	--zone "${zone}" \
	--machine-type "n1-standard-1" \
	--image-type "COS" \
	--disk-size "100" \
	--scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.full_control","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management","https://www.googleapis.com/auth/trace.append" \
	--num-nodes "3" \
	--network "default" \
	--enable-cloud-logging \
	--no-enable-cloud-monitoring \
	--enable-legacy-authorization
}

gcloud.sql.add-ip(){
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --project [project id] --instance [instance name]";return 1
	fi	
	while (( "$#" )); do
	    if [[ "$1" =~ .*--project.* ]]; then PROJECT_ID=$2;fi    
	    if [[ "$1" =~ .*--instance.* ]]; then INSTANCE_NAME=$2;fi
	    if [[ "$1" =~ .*--address.* ]]; then CIDR_ADDRESS=$2;fi
	    if [[ "$1" =~ .*--dry.* ]]; then DRY_RUN="true";fi
	    shift
	done
	echo ${CIDR_ADDRESS}
	AUTH_NETS="${CIDR_ADDRESS},$(gcloud sql instances describe --project ${PROJECT_ID} --format=json ${INSTANCE_NAME} | jq -r '.settings.ipConfiguration.authorizedNetworks | .[].value' | tr '\n' ',')"
	echo "new networks: ${AUTH_NETS}"
    gcloud sql instances patch ${INSTANCE_NAME} --project ${PROJECT_ID} --authorized-networks ${AUTH_NETS}	
	# # OUT="$(mktemp -t $(basename $0))"
	# # OUT2="$(mktemp -t $(basename $0))"
	# command="gcloud sql instances describe --format=json ${INSTANCE_NAME} --project ${PROJECT_ID} | jq '.settings.ipConfiguration.authorizedNetworks | .[]'"
	# if [[ ${DRY_RUN} ]];then
	# 	echo "${command}"
	# 	DRY_RUN=""
	# 	return
	# else
	# 	instance_description=$(eval "${command}" | sort -u | tr '\n' ',' | sed 's/,$//g')
	# fi
	# NETS=${instance_description}
	# # gcloud sql instances patch ${INSTANCE_NAME} --authorized-networks ${NETS}
}

gcloud.switch(){
	if [[ ($# -lt 1) ]]; then 
		echo "Usage: ${FUNCNAME[0]} [account_name] [project_name] [cluster_name] [zone_name]";return 1
	fi
	if [[ "$*" =~ .*--help.* ]];then echo -e "${usage}";return 0;fi	
	account=$1
	project_name=$2
	cluster_name=$3
	zone_name=$4
	if [[ -z ${project} ]];then
		echo -e "You must specify a project, one of:\n $(gcloud projects list --format='value(NAME)')"
		return 1
	fi
	gcloud config set account ${account}
	gcloud config set project ${project_name}
	if [[ (-z ${cluster_name}) || (-z ${zone}) ]];then
		echo -e "You must Specify a cluster and zone, one of:\n $(gcloud container clusters list --format='value(NAME,ZONE)')"
		return 1
	fi	
	gcloud container clusters get-credentials ${cluster_name} --zone ${zone_name} --project ${project_name}
}

gcloud.builds.watch(){
	gcloud container builds log $(gcloud container builds list --filter WORKING --format="value(ID)" | head -1) --stream || echo "No builds yet found ot be active"
}

gcloud.container.images.delete() {
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --older-than [YYYY-MM-DD]";return 1
	fi	
	while (( "$#" )); do
	    if [[ "$1" =~ .*--image.* ]]; then IMAGE=$2;fi    
	    if [[ "$1" =~ .*--older-than.* ]]; then OLDER_THAN=$2;fi
	    if [[ "$1" =~ .*--dry.* ]]; then DRY_RUN="true";fi
	    shift
	done	
	gcloud container images list-tags ${IMAGE} --limit=999999 --sort-by=TIMESTAMP --filter="timestamp.datetime < ${OLDER_THAN}" --format='get(digest)' | while read digest
	do 
		command="gcloud container images delete -q --force-delete-tags '${IMAGE}@${digest}'"
		if [ $DRY_RUN ];then
			echo ${command}
		else
			eval ${command}
		fi
	done
	DRY_RUN=""
}

gcloud.cloudsql.start_proxy() {
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --project [project_id] --config [config] --config_db_sections [section1,section2] --credential_file [service_account_key.json]";return 1
	fi	
	BINARY=cloud_sql_proxy
	if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then
		echo "This function requires $BINARY"
		if [[ "$OSTYPE" =~ .*darwin.* ]]; then
			echo -e """You can install the binary as follows:
			curl -o ${BINARY} https://dl.google.com/cloudsql/${BINARY}.darwin.386
			sudo chmod +x ./${BINARY}
			mv -f ./${BINARY} /usr/local/bin
			"""
		fi
		return 1
	fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--project.* ) || ( "$1" == -p ) ]]; then PROJECT_ID=$2;fi    
	    if [[ ( "$1" =~ .*--config.* ) || ( "$1" == -c ) ]]; then CONFIG=$2;fi
	    if [[ ( "$1" =~ .*--config_db_sections.* ) || ( "$1" == -s ) ]]; then CONFIG_DB_SECTIONS=$2;fi
	    if [[ ( "$1" =~ .*--credential_file.* ) || ( "$1" == -j ) ]]; then CREDENTIAL_FILE=$2;fi
	    shift
	done
	config.read --ini ${CONFIG} --sections ${CONFIG_DB_SECTIONS-DATABASE,CLOUDSQL_DB}
	CLOUDSQL_CONNECTION_STRING="${CLOUDSQL_CONNECTION_STRING}=tcp:${CLOUDSQL_PORT}"
	${BINARY} --dir=./ -instances=$CLOUDSQL_CONNECTION_STRING -credential_file=${CREDENTIAL_FILE} &
	CLOUDSQL_CONNECTION_STRING=""
}

gcloud.cloudsql.run_script() {
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --project [project_id] --config [config]";return 1
	fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--project.* ) || ( "$1" == -p ) ]]; then PROJECT_ID=$2;fi    
	    if [[ ( "$1" =~ .*--config.* ) || ( "$1" == -c ) ]]; then CONFIG=$2;fi
	    if [[ ( "$1" =~ .*--user.* ) || ( "$1" == -u ) ]]; then MYSQL_USER=$2;fi
	    if [[ ( "$1" =~ .*--database.* ) || ( "$1" == -d ) ]]; then DATABASE=$2;fi
	    if [[ ( "$1" =~ .*--credential_file.* ) || ( "$1" == -j ) ]]; then CREDENTIAL_FILE=$2;fi
	    if [[ ( "$1" =~ .*--sql_script.* ) || ( "$1" == -s ) ]]; then SQL_SCRIPT=$2;fi
	    if [[ ( "$1" =~ .*--dry.* ) || ( "$1" == -r ) ]]; then DRY_RUN="true";fi
	    shift
	done
	preflight="gcloud.cloudsql.start_proxy --config ${CONFIG} --credential_file ${CREDENTIAL_FILE}"
	command="mysql -u ${MYSQL_USER} -h 127.0.0.1 -p ${DATABASE} < ${SQL_SCRIPT}"
	if [ $DRY_RUN ];then
		echo "Dry Run:"
		echo -e "\t${preflight}"
		echo -e "\t${command}"
	else
		eval ${preflight}
		eval ${command}
		pkill cloud_sql_proxy
	fi
	DRY_RUN=""
}

gcloud.cloudsql.backup_db() {
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: 
		${FUNCNAME[0]} 
		--project [project_id] 
		--config [config] 
		--credential_file [/path/to/credentials.json]
		--user [cloudsql_userid]
		--database [database_name]
		--dbtype [mysql/postgres]
		--dry [optional]
		"""
		return 0
	fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--project.* ) || ( "$1" == -j ) ]]; then PROJECT_ID=$2;fi    
	    if [[ ( "$1" =~ .*--config.* ) || ( "$1" == -c ) ]]; then CONFIG=$2;fi
	    if [[ ( "$1" =~ .*--credential_file.* ) || ( "$1" == -j ) ]]; then CREDENTIAL_FILE=$2;fi
	    if [[ ( "$1" =~ .*--user.* ) || ( "$1" == -u ) ]]; then CLOUDSQL_USER=$2;fi
	    if [[ ( "$1" =~ .*--database.* ) || ( "$1" == -d ) ]]; then DATABASE=$2;fi
	    if [[ ( "$1" =~ .*--dbtype.* ) || ( "$1" == -e ) ]]; then DB_TYPE=$2;fi
	    if [[ ( "$1" =~ .*--dry.* ) || ( "$1" == -r ) ]]; then DRY_RUN="true";fi
	    shift
	done
	gcloud.cloudsql.start_proxy --config ${CONFIG} --credential_file ${CREDENTIAL_FILE}
	config.read --ini ${CONFIG} --sections DATABASE
	if [[ "${DB_TYPE}" == "postgres" ]];then
		pg_dump -h 127.0.0.1 -U ${CLOUDSQL_USER} -a -d "${DATABASE}" -f "${DATABASE}.db.sql"
	elif [[ "${DB_TYPE}" == "postgres" ]];then
		mysqldump -h 127.0.0.1 -u ${CLOUDSQL_USER} -p "${DATABASE}" > "${DATABASE}.db.sql"
	fi
	# pkill cloud_sql_proxy
	unset PROJECT_ID CONFIG CLOUDSQL_USER CLOUDSQL_USER
}

gcloud.cloudsql.active_connections() {
	psql -h 127.0.0.1 --username=${API_USER} --db postgres -c "select datname as database, pid as pid, usename as username, application_name as application, client_addr as client_address from pg_stat_activity;"
}