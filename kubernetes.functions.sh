function k.aliases {
if [[ $(type /usr/{,local/}{,s}bin/kubectl 2> /dev/null) || $(which kubectl 2> /dev/null) ]];then
  alias k=kubectl
  alias k.namespaces='kubectl get namespaces'
  alias k.config.context.list='kubectl config get-contexts'
  alias k.config.context.use='kubectl config use-context'
  k8s_contexts=$(kubectl config get-contexts -o name | sort -u 2>/dev/null)
  k8s_namespaces=$(kubectl get namespaces -o custom-columns=NAME:metadata.name --no-headers 2>/dev/null)
  if [[ $? -eq 0 ]];then
    for k8s_context in ${k8s_contexts}; do
        context="k.config.context.use";method=${k8s_context//-/.}
        alias "${context}.${method}=kubectl config use-context ${k8s_context}"
    done
    for k8s_namespace in ${k8s_namespaces}; do
      namespace="k.";method=${k8s_namespace//-/.}
      alias "${namespace}${method}=kubectl --namespace ${k8s_namespace}"
      eval """function ${namespace}${method}.logs(){ kubectl --namespace ${k8s_namespace} logs \$(kubectl --namespace ${k8s_namespace} get pods -o name | grep -i \${1?'YOU MUST SPECIFY A PODNAME'}); }"""
      alias "${namespace}${method}.pods=kubectl --namespace ${k8s_namespace} get pods"
      eval """function ${namespace}${method}.describe(){ kubectl --namespace ${k8s_namespace} describe \$(kubectl --namespace ${k8s_namespace} get \${1?'YOU MUST SPECIFY
A RESOURCE TYPE'} -o name | grep -i \${2?'YOU MUST SPECIFY THE RESOURCE NAME'}); }"""
      eval """function ${namespace}${method}.exec(){ POD_NAME=\$(kubectl --namespace ${k8s_namespace} get pods -o name | grep -i \${1?'YOU MUST SPECIFY A PODNAME'});kubectl --namespace ${k8s_namespace} exec -it \${POD_NAME##*/} \${2?'YOU MUST SPECIFY A COMMAND'}; }"""
      alias "${namespace}${method}.services=kubectl --namespace ${k8s_namespace} get services"
      alias "${namespace}${method}.deployments=kubectl --namespace ${k8s_namespace} get deployments"
      alias "${namespace}${method}.ingresses=kubectl --namespace ${k8s_namespace} get ingresses"
    done
  fi
fi
}

kubectl.proxy.start() {
	usage="""Usage: 
	${FUNCNAME[0]} --context"""	
	if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--context.* ) || ( "$1" == -x ) ]]; then context=$2;fi    
	    shift
	done
	port_file=/tmp/.port
	kubectl --context ${context} proxy --port=0 > ${port_file} &
	sleep 2
	current_port=$(cat ${port_file} | string.grep '[\d]+$')
	web.open_url http://127.0.0.1:${current_port}/ui

}

kubectl.secrets.decode(){
	usage="""Usage: 
	${FUNCNAME[0]} --context/-c [context_name] --namespace/-n [namespace_name] --secret/-s [secret_name]"""	
	if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--namespace.* ) || ( "$1" == -n ) ]]; then namespace="--namespace ${2}";fi	    	
	    if [[ ( "$1" =~ .*--context.* ) || ( "$1" == -x ) ]]; then context="--context ${2}";fi
	    if [[ ( "$1" =~ .*--secret.* ) || ( "$1" == -s ) ]]; then secret="${2}";fi
	    shift
	done	
	kubectl ${context} ${namespace} get secret ${secret} -o yaml | grep '^ ' | while read key value;do echo "$key" "$(echo $value | base64 -d)";done 2> /dev/null
}


kubectl.tls.export(){
	usage="""Usage: 
	${FUNCNAME[0]} --context [context_name] --namespace [namespace_name] --secret [secret_name]"""	
	if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--namespace.* ) || ( "$1" == -n ) ]]; then namespace="--namespace ${2}";fi	    	
	    if [[ ( "$1" =~ .*--context.* ) || ( "$1" == -x ) ]]; then context="--context ${2}";fi
	    if [[ ( "$1" =~ .*--secret.* ) || ( "$1" == -x ) ]]; then secret="${2}";fi
	    shift
	done	
	kubectl ${context} ${namespace} get secrets -o yaml ${secret} | grep -E 'tls.(crt|key)' | while read line;
	do
	  OUT=$(echo $line | awk -F:\  '{print$1}')
	  echo $line | awk -F:\  '{print$NF}' | base64 -d > ${namespace//--namespace/}-${secret}-$OUT
	done

}

kubectl.proxy.kill() {
	if ! [[ "$OSTYPE" =~ .*darwin.* ]]; then echo "This works only on OSX";return 1;fi
	usage="""Usage: 
	${FUNCNAME[0]} [regex]"""
	if [[ "$*" =~ .*--help.* ]];then echo -e "${usage}";return 0;fi
	regex=$1
	pid=$(ps -ef | grep -vi grep | grep -i kubectl.*proxy | grep ${regex} | awk '{print $2}')
	kill $pid
}

kubectl.cluster.backup(){
	for ns in $(kubectl get ns --no-headers | cut -d " " -f1); do
	  if { [ "$ns" != "kube-system" ]; }; then
	  kubectl --namespace="${ns}" get --export -o=json svc,rc,rs,deployments,cm,secrets,ds | \
	jq '.items[] |
	    select(.type!="kubernetes.io/service-account-token") |
	    del(
	        .spec.clusterIP,
	        .metadata.uid,
	        .metadata.selfLink,
	        .metadata.resourceVersion,
	        .metadata.creationTimestamp,
	        .metadata.generation,
	        .status,
	        .spec.template.spec.securityContext,
	        .spec.template.spec.dnsPolicy,
	        .spec.template.spec.terminationGracePeriodSeconds,
	        .spec.template.spec.restartPolicy
	    )' >> "./my-cluster.json"
	  fi
	done
	# In case you need to revocer the state after, you just need to execute kubectl create -f ./my-cluster.json
}

kubectl.pods.restart(){
	usage="""Usage: 
	${FUNCNAME[0]} --context/-x [context_name] --namespace/-n [namespace_name] --deployment/-d [deployment_name] --rc [replication_controller_name]"""	
	if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--context.* ) || ( "$1" == -x ) ]]; then local context="--context ${2}";fi
	    if [[ ( "$1" =~ .*--namespace.* ) || ( "$1" == -n ) ]]; then local namespace="--namespace ${2}";fi	    	
	    if [[ ( "$1" =~ .*--pod.* ) || ( "$1" == -p ) ]]; then local pod_name="${2}";fi
	    if [[ ( "$1" =~ .*--rc.* ) || ( "$1" == -r ) ]]; then local obj_type="rc";local con_name="${2}";fi
	    if [[ ( "$1" =~ .*--deployment.* ) || ( "$1" == -d ) ]]; then local obj_type="deployment";local con_name="${2}";fi
	    if [[ ( "$1" =~ .*--wait.* ) || ( "$1" == -w ) ]]; then local t="${2}";fi
	    shift
	done
	local t=${t-10}
	num_replicas=$(kubectl ${context} ${namespace} get "${obj_type}" "${con_name}" --output=jsonpath={.spec.replicas})
	echo "Restarting ${obj_type} ${con_name}"
	kubectl ${context} ${namespace} scale --replicas=0 ${obj_type} ${con_name}
	echo "Waiting 10 seconds before we bring ${obj_type} ${con_name} back up to its original scaling of ${num_replicas}"
	sleep 10
	kubectl ${context} ${namespace} scale --replicas=${num_replicas} ${obj_type} ${con_name}
}


kubectl.run.curl(){
	usage="""Usage: 
	${FUNCNAME[0]} --context [context_name] --namespace [namespace_name] --curl [url] --command [command]"""
	if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi	
	while (( "$#" )); do
	    if [[ ( "$1" =~ .*--context.* ) || ( "$1" == -x ) ]]; then local context="--context ${2}";fi
	    if [[ ( "$1" =~ .*--namespace.* ) || ( "$1" == -n ) ]]; then local namespace="--namespace ${2}";fi	    	
	    if [[ ( "$1" =~ .*--curl.* ) || ( "$1" == -u ) ]]; then local shell_exec="sh -c 'curl ${2}'";fi
	    if [[ ( "$1" =~ .*--command.* ) || ( "$1" == -c ) ]]; then local shell_exec="sh -c '${2}'";fi
	    shift
	done
	shell_exec=${shell_exec-sh}
	deployment_name=curl-${namespace#* }
	command1="kubectl ${context} ${namespace} get pods  --no-headers | grep -iq curl"
	command2="kubectl ${context} ${namespace} scale --replicas=0 deployment ${deployment_name}  && sleep 10 && kubectl ${context} ${namespace} scale --replicas=1 deployment ${deployment_name}"
	if ! [[ ( $command1 ) || ( $command2 ) ]];then
		kubectl ${context} ${namespace} run ${deployment_name} --image=radial/busyboxplus:curl -i --tty --rm
	else
		eval kubectl ${context} ${namespace} exec -it $(kubectl ${context} ${namespace} get pods  --no-headers | grep -i curl | awk '{print $1}') -- "${shell_exec}"
	fi
}

kubectl.logs(){
	usage="""Usage: 
	${FUNCNAME[0]} --namespace [namespace_name] --label [label_name]"""	
	if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi	
	while (( "$#" )); do
	    if [[ "$1" =~ .*--namespace.* ]]; then NAMESPACE=$2;fi    
	    if [[ "$1" =~ .*--label.* ]]; then LABEL=$2;fi    
	    if [[ "$1" =~ .*--container.* ]]; then CONTAINER=$2;fi    
	    if [[ "$1" =~ .*--follow.* ]]; then FOLLOW="-f";fi
	    if [[ "$1" =~ .*--all.* ]]; then all="true";fi
	    shift
	done
	if [ $all ];then
		for pod in $(kubectl -n ${NAMESPACE} get pods -l "${LABEL}" --output=jsonpath={.items..metadata.name});do
			echo "-----Showing logs for pod ${pod}-----"
			kubectl -n ${NAMESPACE} logs ${pod} ${CONTAINER} ${FOLLOW}
		done
	else
		pod=$(kubectl -n ${NAMESPACE} get pods -l "${LABEL}" --output=jsonpath={.items..metadata.name} | awk '{print $1}')
		echo "-----Showing logs for pod ${pod}-----"
		kubectl -n ${NAMESPACE} logs ${pod} ${CONTAINER} ${FOLLOW}
	fi
	unset CONTAINER FOLLOW
}

minikube.reset(){
	minikube config set cpus 4
	minikube config set memory 4096
	minikube config view
	minikube delete || true
	minikube start --vm-driver ${1-"virtualbox"}
}