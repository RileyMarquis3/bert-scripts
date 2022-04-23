function aws.profile.list(){
  aws configure list-profiles
}

function aws.profile.login(){

  argscount=$#
  allargs=${@}

  USAGE="""
  ${FUNCNAME[0]}
    -p <profile_name>
    --help
  """

  while (( "$#" )); do
      if [[ "$1" =~ ^-p$ ]]; then profile_name=$2;fi    
      if [[ "$1" =~ ^--help$ ]]; then help=true;fi    
      shift
  done

  if [[ (-n $help) || ($argscount -lt 1) ]];then
    echo -e "${USAGE}"
    return
  fi

  if $(aws configure list-profiles | grep -q "${profile_name}" 2>/dev/null);then
    aws sso login --profile "${profile_name}"
    export AWS_PROFILE="${profile_name}"
    return
  else
    echo "The specified profile '${profile_name}' does not exist"
    return 1
  fi

}

function aws.secrets.create(){

  argscount=$#
  allargs=${@}

  USAGE="""
  ${FUNCNAME[0]}
    -n <secret_name>
    -d <secret_description>
    -s <secret_string>
    --help
  """

  while (( "$#" )); do
      if [[ "$1" =~ ^-n$ ]]; then secret_name=$2;fi    
      if [[ "$1" =~ ^-d$ ]]; then secret_description=$2;fi    
      if [[ "$1" =~ ^-i$ ]]; then secret_string=$2;fi    
      if [[ "$1" =~ ^--help$ ]]; then help=true;fi    
      shift
  done

  if [[ (-n $help) || ($argscount -lt 1) ]];then
    echo -e "${USAGE}"
    return
  fi

  aws secretsmanager create-secret --name ${secret_name} \
      --description "${secret_description}" \
      --secret-string "${secret_string}"
}

function aws.ec2.list(){
  aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].{PublicDNS:PublicDnsName,IP:PublicIpAddress,ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[0].Value}" \
  --output=table
}

function aws.ec2.clone {

  argscount=$#
  allargs=${@}

  USAGE="""
  ${FUNCNAME[0]}
    -i <instance_name>
    -r <region_name>
    --help
  """

  while (( "$#" )); do
      if [[ "$1" =~ ^-i$ ]]; then awsinstanceid=$2;fi    
      if [[ "$1" =~ ^-r$ ]]; then region=$2;fi    
      if [[ "$1" =~ ^--help$ ]]; then help=true;fi    
      shift
  done

  if [[ (-n $help) || ($argscount -lt 1) ]];then
    echo -e "${USAGE}"
    return
  fi

  export AWS_DEFAULT_REGION=${region?Error: Must define region}
  ami=$(aws ec2 describe-instances --instance-ids $awsinstanceid | grep INSTANCES | awk '{print $7}')
  privatekey=$(aws ec2 describe-instances --instance-ids $awsinstanceid | grep INSTANCES | awk '{print $10}')
  securitygroup=$(aws ec2 describe-instances --instance-ids $awsinstanceid | grep SECURITYGROUPS | awk '{print $2}')
  instancetype=$(aws ec2 describe-instances --instance-ids $awsinstanceid | grep INSTANCES | awk '{print $9}')
  subnet=$(aws ec2 describe-instances --instance-ids $awsinstanceid | grep NETWORKINTERFACES | awk '{print $9}')

  awsinstancedata=$(aws ec2 run-instances --image-id $ami --key-name $privatekey --security-group-ids $securitygroup --instance-type $instancetype --subnet-id $subnet)
  awsinstanceid=$(echo $awsinstancedata | awk '{print $9}')

  # AWS CLI sucks and doesn't return error codes so have to look for a valid id
  if [[ "$awsinstanceid" == i-* ]]; then 
    echo -e "\t\tSuccessfully created. Instance ID: $awsinstanceid";
  else 
    echo -e "\t\tSomething went wrong. Check your configuration."; 
    return; 
  fi 
  echo -e "\t\tWaiting for ec2 instance to come up..."
  aws ec2 wait instance-running --instance-ids $awsinstanceid
  echo -e "\t\Instance is up and ready"
}

