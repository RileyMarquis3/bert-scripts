file.encrypt(){
	declare -A params=(
	["--public-key|-k$"]="[PEM-formatted public key]"
	["--target-file|-f$"]="[/path/to/target/file]"
	["--help|-h$"]="Display usage and exit"
	["--dry"]="Dry Run"
	)
	# Display help if no args
	if [[ $# -lt 1 ]];then help ${FUNCNAME[0]} "${params}";return;fi
	# Parse arguments
	eval $(create_params)
	# Display help if applicable
	if [[ -n $help ]];then help ${FUNCNAME[0]} "${params}";return;fi
	# DRY RUN LOGIC
	if [[ -n $dry ]];then 
	  PREFIX=echo
	fi
	local work_dir="${work_dir-$HOME/.ssh/}"
	local private_key="${private_key-${work_dir}/id_rsa}"
	if [[ -z $public_key ]];then
		local public_key="${public_key-${work_dir}${private_key##*/}}"
		local public_key_pem="${public_key}.pem"	
	else
		local public_key_pem="${public_key}"	
	fi
	if ! test -f $public_key_pem; then
	    echo "Creating public keys: $public_key_pem"
	    if [[ -z $dry ]];then
   	 		${PREFIX} ssh-keygen -f $public_key -e -m PKCS8 > $public_key_pem
		else
    		${PREFIX} ssh-keygen -f $public_key -e -m PKCS8 \> $public_key_pem
		fi
	fi
	TEMPFILE=$(mktemp -t $(whoami)XXX || mktemp -t $(whoami)ZZZ)
    eval openssl rsautl -encrypt -pubin -inkey ${public_key_pem} -ssl -in $target_file -out ${TEMPFILE}
    if [[ -z $dry ]];then
    	eval "cat ${TEMPFILE} > ${target_file}"
	fi
	rm -f "${TEMPFILE}"
}

file.decrypt(){
	PREFIX=eval
	declare -A params=(
	["--public-key|-k$"]="[PEM-formatted public key]"
	["--target-file|-f$"]="[/path/to/target/file]"
	["--help|-h$"]="Display usage and exit"
	["--edit|-e"]="EDIT INI"
	["--no-encrypt"]="Skip Re-encryption"
	)
	# Display help if no args
	if [[ $# -lt 1 ]];then help ${FUNCNAME[0]} "${params}";return;fi
	# Parse arguments
	eval $(create_params)
	# Display help if applicable
	if [[ -n $help ]];then help ${FUNCNAME[0]} "${params}";return;fi
	# DRY RUN LOGIC
	if [[ -n $dry ]];then 
	  PREFIX=echo
	fi

	local work_dir="${work_dir-$HOME/.ssh/}"
	local private_key="${private_key-${work_dir}/id_rsa}"
	if [[ -z $public_key ]];then
		local public_key="${public_key-${work_dir}${private_key##*/}}"
		local public_key_pem="${public_key}.pem"	
	else
		local public_key_pem="${public_key}"	
	fi
	if ! test -f $public_key_pem; then
	    echo "Creating public keys: $public_key_pem"
	    ssh-keygen -f $public_key -e -m PKCS8 > $public_key_pem
	fi
	TEMPFILE=$(mktemp -t $(whoami)XXX || mktemp -t $(whoami)ZZZ)
    eval openssl rsautl -decrypt -inkey "${private_key}" -in "${target_file}" -out "${TEMPFILE}"
    if [[ $edit ]];then
    	subl -w ${TEMPFILE}
	    cat ${TEMPFILE} > ${target_file}
	    if [[ -z $no_encrypt ]];then
		    file.encrypt --public-key "${public_key_pem}" --temp-file "${TEMPFILE}" --vault-file "${target_file}"
		fi
    else
	    eval "cat ${TEMPFILE} > ${target_file}"
    fi
	rm -f "${TEMPFILE}"
}

ssh.audit.logins(){
	if [[ ($# -lt 2) ]]; then 
		echo "Usage: ${FUNCNAME[0]} --host [hostname] [--current ] [--summarize] [--results] [--dry]";return 1
	fi
	PREFIX=""
	results=10
	while (( "$#" )); do
	    if [[ "$1" =~ .*--host.* ]]; then local HOST_NAME=$2;fi    
	    if [[ "$1" =~ .*--results.* ]]; then local results=$2;fi    
	    if [[ "$1" =~ .*--current.* ]]; then local CURRENT="true";fi    
	    if [[ "$1" =~ .*--summarize.* ]]; then local SUMMARIZE="true";fi    
	    if [[ "$1" =~ .*--dry.* ]]; then local PREFIX="echo";fi
	    shift
	done
	if [ $CURRENT ];then
		ssh "${HOST_NAME}" "last | grep -v ness | head -${results}" 2>/dev/null
	fi
}

ssl.cert.import(){
	HOST=$(echo "$1" | sed -E -e 's/https?:\/\///' -e 's/\/.*//')
	if [[ "$HOST" =~ .*\..* ]]; then
	    echo "Adding certificate for $HOST"
	    echo -n | openssl s_client -connect $HOST:443 -servername $HOST \
	        | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
	        | tee "/tmp/$HOST.cert"
	    sudo security add-trusted-cert -d -r trustRoot \
	        -k "/Library/Keychains/System.keychain" "/tmp/$HOST.cert"
	    rm -v "/tmp/$HOST.cert"
	else
	    echo "Usage: $0 www.site.name"
	    echo "http:// and such will be stripped automatically"
	fi
}

ssl.certs.generate(){

if [[ -z $SILENT ]]; then
echo "----------------------------"
echo "| OMGWTFSSL Cert Generator |"
echo "----------------------------"
echo
fi

export CA_KEY=${CA_KEY-"ca-key.pem"}
export CA_CERT=${CA_CERT-"ca.pem"}
export CA_SUBJECT=${CA_SUBJECT:-"test-ca"}
export CA_EXPIRE=${CA_EXPIRE:-"60"}

export SSL_CONFIG=${SSL_CONFIG:-"${PWD}/openssl.cnf"}
export SSL_KEY=${SSL_KEY:-"key.pem"}
export SSL_CSR=${SSL_CSR:-"key.csr"}
export SSL_CERT=${SSL_CERT:-"cert.pem"}
export SSL_SIZE=${SSL_SIZE:-"2048"}
export SSL_EXPIRE=${SSL_EXPIRE:-"60"}

export SSL_SUBJECT=${SSL_SUBJECT:-"example.com"}
export SSL_DNS=${SSL_DNS}
export SSL_IP=${SSL_IP}

export K8S_NAME=${K8S_NAME:-"omgwtfssl"}
export K8S_NAMESPACE=${K8S_NAMESPACE:-"default"}
export K8S_SAVE_CA_KEY=${K8S_SAVE_CA_KEY}
export K8S_SAVE_CA_CRT=${K8S_SAVE_CA_CRT}
export K8S_SHOW_SECRET=${K8S_SHOW_SECRET}

export OUTPUT=${OUTPUT:-"yaml"}

# needed for k8s cert-manager compatibility
echo "
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
" >> ${PWD}/openssl.cnf

[[ -z $SILENT ]] && echo "--> Certificate Authority"

if [[ -e ./${CA_KEY} ]]; then
    [[ -z $SILENT ]] && echo "====> Using existing CA Key ${CA_KEY}"
else
    [[ -z $SILENT ]] && echo "====> Generating new CA key ${CA_KEY}"
    openssl genrsa -out ${CA_KEY} ${SSL_SIZE} > /dev/null
fi

if [[ -e ./${CA_CERT} ]]; then
    [[ -z $SILENT ]] && echo "====> Using existing CA Certificate ${CA_CERT}"
else
    [[ -z $SILENT ]] && echo "====> Generating new CA Certificate ${CA_CERT}"
    openssl req -x509 -new -nodes -key ${CA_KEY} -days ${CA_EXPIRE} -out ${CA_CERT} -extensions v3_ca -subj "/CN=${CA_SUBJECT}" > /dev/null  || exit 1
fi

echo "====> Generating new config file ${SSL_CONFIG}"
cat > ${SSL_CONFIG} <<EOM
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOM

if [[ -n ${SSL_DNS} || -n ${SSL_IP} ]]; then
    cat >> ${SSL_CONFIG} <<EOM
subjectAltName = @alt_names
[alt_names]
EOM

    IFS=","
    dns=(${SSL_DNS})
    dns+=(${SSL_SUBJECT})
    for i in "${!dns[@]}"; do
      echo DNS.$((i+1)) = ${dns[$i]} >> ${SSL_CONFIG}
    done

    if [[ -n ${SSL_IP} ]]; then
        ip=(${SSL_IP})
        for i in "${!ip[@]}"; do
          echo IP.$((i+1)) = ${ip[$i]} >> ${SSL_CONFIG}
        done
    fi
fi

[[ -z $SILENT ]] && echo "====> Generating new SSL KEY ${SSL_KEY}"
openssl genrsa -out ${SSL_KEY} ${SSL_SIZE} > /dev/null || exit 1

[[ -z $SILENT ]] && echo "====> Generating new SSL CSR ${SSL_CSR}"
openssl req -new -key ${SSL_KEY} -out ${SSL_CSR} -subj "/CN=${SSL_SUBJECT}" -config ${SSL_CONFIG} > /dev/null || exit 1

[[ -z $SILENT ]] && echo "====> Generating new SSL CERT ${SSL_CERT}"
openssl x509 -req -in ${SSL_CSR} -CA ${CA_CERT} -CAkey ${CA_KEY} -CAcreateserial -out ${SSL_CERT} \
    -days ${SSL_EXPIRE} -extensions v3_req -extfile ${SSL_CONFIG} > /dev/null || exit 1

echo "Creating k8s secrets file"
# create k8s secret file
cat << EOM > ${PWD}/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ${K8S_NAME}
  namespace: ${K8S_NAMESPACE}
type: kubernetes.io/tls
data:
EOM

if [[ -n $K8S_SAVE_CA_KEY ]]; then
    echo -n "  ca.key: " >> ${PWD}/secret.yaml
    cat $CA_KEY | base64 | tr '\n' ',' | sed 's/,//g' >> ${PWD}/secret.yaml
    echo >> ${PWD}/secret.yaml
fi
if [[ -n $K8S_SAVE_CA_CRT ]]; then
    echo -n "  ca.crt: " >> ${PWD}/secret.yaml
    cat $CA_CERT | base64 | tr '\n' ',' | sed 's/,//g' >> ${PWD}/secret.yaml
    echo >> ${PWD}/secret.yaml
fi
echo -n "  tls.key: " >> ${PWD}/secret.yaml
cat $SSL_KEY | base64 | tr '\n' ',' | sed 's/,//g' >> ${PWD}/secret.yaml
echo >> ${PWD}/secret.yaml
echo -n "  tls.crt: " >> ${PWD}/secret.yaml
cat $SSL_CERT | base64 | tr '\n' ',' | sed 's/,//g' >> ${PWD}/secret.yaml
echo >> ${PWD}/secret.yaml

if [[ -z $SILENT ]]; then

	if [[ ${OUTPUT} == "k8s" ]]; then
	  echo "====> Output results as base64 k8s secrets"
	  echo "---"
	  cat ${PWD}/secret.yaml
	else
	  echo "====> Output results as YAML"
	  echo "---"
	  echo "ca_key: |"
	  cat $CA_KEY | sed 's/^/  /'
	  echo
	  echo "ca_crt: |"
	  cat $CA_CERT | sed 's/^/  /'
	  echo
	  echo "ssl_key: |"
	  cat $SSL_KEY | sed 's/^/  /'
	  echo
	  echo "ssl_csr: |"
	  cat $SSL_CSR | sed 's/^/  /'
	  echo
	  echo "ssl_crt: |"
	  cat $SSL_CERT | sed 's/^/  /'
	  echo
	fi

	echo "Validating the certificate chain ${CA_CERT} => ${SSL_CERT}"
	openssl verify -CAfile "${CA_CERT}" "${SSL_CERT}"

	echo -e "Server certificate (+ intermediates) : ${SSL_CERT}"
	echo -e "Server certificate key	             : ${SSL_KEY}"
	echo -e "CA certificate	                     : ${CA_CERT}"

	echo "====> Complete"
	echo "keys can be found in volume mapped to $(pwd)"

fi
}

ssl.cert.create(){

  all_args=$*
  num_args=$#
	cert_template="""
	[req]
	default_bits=2048
	encrypt_key=no
	prompt=no
	default_md=sha256
	distinguished_name=req_subj
	[req_subj]
	commonName='{FQDN}'
	emailAddress='{EMAIL}'
	countryName='{COUNTRY}'
	stateOrProvinceName='{STATE}'
	localityName='{CITY}'
	organizationName='{COMPANY}'
	organizationalUnitName='{ORGUNIT}'"""
	
  usage="usage: ${FUNCNAME[0]} [FQDN] [EMAIL] [COUNTRY] [CITY] [STATE] [COMPANY] [ORG_UNIT]"
	
  if [[ $all_args =~ ^--help$ ]];then 
    echo -e "${usage}"
    return 0
  fi

	BINARY=openssl
	if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then	
		echo "This function requires $binary"
		return 1
	fi
	local FQDN=$1
	local EMAIL=$2
	local COUNTRY=${3-US}
	local CITY=$4
	local STATE=$5
	local COMPANY=$6
	local ORGUNIT=$7
	# ( set -o posix ; set ) | less
	for var in $(local);do 
		key=${var%=*}
		val=${var#*=}
		cert_template=${cert_template//\{${key}\}/$val}
		# for line in $(echo -e "${cert_template}");do
		# 	# sed "s/{${key}}/${val}/" < <(echo "${line}")
		# done
	done
	tmp_file=$(mktemp -t opensslXXX || mktemp -t opensslZZZ)
	key_file=${FQDN}.key.pem
	cert_file=${FQDN}.cert.pem
	echo -e "${cert_template}" > ${tmp_file}
	openssl req -x509 -nodes -newkey rsa:2048 -config ${tmp_file} -keyout ${key_file} -out ${cert_file}
}

password.generate (){
 openssl rand -base64 18 | cut -c 1-16
}

symantec.stop() {
	BINARY=sep
	if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then
		echo "This function requires $binary, install with sudo curl https://gist.githubusercontent.com/steve-jansen/61a189b6ab961a517f68/raw/sep -o /usr/local/bin/sep -k"
		return 1
	else
		sep stop
	fi
}

symantec.start() {
	BINARY=sep
	if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then
		echo "This function requires $binary, install with sudo curl https://gist.githubusercontent.com/steve-jansen/61a189b6ab961a517f68/raw/sep -o /usr/local/bin/sep -k"
		return 1
	else
		sep start
	fi
}

alias sudo='sudo '

function string.encrypt() {
	if [ $# -lt 1 ]; then echo -e """usage: ${FUNCNAME[0]} <string> [optional parameters]
		optional positional parameters:
		</path/to/private_key>
		</path/to/public_key>""";return 0;fi	
	BINARY=openssl
	if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then	
		echo "This function requires $binary"
		return 1
	fi
	strings=$1
	private_key_default=~/.ssh/id_rsa
	public_key_default=${private_key_default}.pub
	private_key=${2-$private_key_default}
	if [[ -z $3 ]]; then
		# defaults for public key
		public_key=${public_key_default}
		public_key_pem=${public_key%.*}.pem.pub
	else	
		public_key=${3}
		# if specified public key matches *.pem.pub	
		if [[ $public_key =~ .*.pem.pub ]];then
			public_key_pem=${3%.pem*}.pem.pub
		# if specified public key matches *.pub	
		elif [[ $public_key =~ .*.pub ]];then
			public_key_pem=${public_key%.pub*}.pem.pub			
		else
			public_key_pem=${public_key}.pem.pub
		fi
	fi
	specified_public_key_is_pem_formatted=$(openssl rsa -inform PEM -pubin -in ${public_key} -noout &> /dev/null;echo $?)
	if [[ "${specified_public_key_is_pem_formatted}" == 1 ]]; then
		specified_public_key_is_pem_formatted="false"
	elif [[ "${specified_public_key_is_pem_formatted}" == 0 ]]; then
		specified_public_key_is_pem_formatted="true"
	else
		specified_public_key_is_pem_formatted="false"
	fi
	if [[ ! (-f ${public_key_pem}) && ("${specified_public_key_is_pem_formatted}" == "false") ]]; then
		echo "No PEM-formatted public key found."
		echo -e "Attempting to create one from your non-PEM-formatted public key (${yellow}${public_key})"
		if ! [[ -f ${public_key} ]]; then
			echo "Couldn't find your non-PEM public key (${public_key})"
			return 1
		fi
		echo "First, let's create a backup of your existing key ..."
		public_key_backup=${public_key}.bak
		if cp -n ${public_key} ${public_key}.bak; then
			echo -e "Done! Your backup key is located here: ${yellow}${public_key_backup}"
		else
			echo -e "Either your backup key already exists or I couldn't create one for you: ${red}${public_key_backup}"
		fi
		ssh-keygen -f ${public_key} -e -m PKCS8 > ${public_key_pem}
		echo -e "Done. Your newly-generated PEM-formatted key is located here: ${yellow}${public_key_pem}"
		echo -e "Relaunch your command ${green}${FUNCNAME[0]} $*"
		return 1
	fi
	if [[ ("${specified_public_key_is_pem_formatted}" == "true") ]]; then
		in_public=$public_key
	else
		in_public=$public_key_pem
	fi
	openssl rsautl -encrypt -pubin -inkey ${in_public} -ssl < <(echo -e "${strings}") 2>&1 || echo "Failed to load ${in_public}"
}

function string.decrypt() {
	usage="""usage: ${FUNCNAME[0]} <string> [optional parameters]
		optional positional parameters:
		</path/to/private_key>
		</path/to/public_key>"""
	if [[ "$*" =~ .*--help.* ]];then echo -e "${usage}";return 0;fi
	BINARY=openssl
	if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then	
		echo "This function requires $binary"
		return 1
	fi
	strings=$1
	private_key_default=~/.ssh/id_rsa
	private_key=${2-$private_key_default}
	openssl rsautl -decrypt -inkey $private_key || \
	(echo -e "${red}Failed to load ${private_key}${reset}";
	echo "Check for the following:"
	echo -e "\t* That you typed the right passphrase for the private key"
	echo -e "\t* That the private key ${yellow}${private_key} you're using matches the public key used to encrypt the string";return 1)
}

ssh_verify_keys() {
	if [[ "$#" -lt 2 ]]; then
		echo "Usage: ${FUNCNAME[0]} [PRIVKEY] [TESTKEY]"
		return
	fi
	PRIVKEY=$1
	TESTKEY=$2
	\diff <( ssh-keygen -y -e -f "$PRIVKEY" ) <( ssh-keygen -y -e -f "$TESTKEY" )

}

