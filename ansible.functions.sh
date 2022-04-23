ansible.roles.create(){
    if [[ ($# -lt 2) ]]; then 
        echo "Usage: ${FUNCNAME[0]} --role-name [ROLE_NAME]";return 1
    fi  
    PREFIX=""
    while (( "$#" )); do
        if [[ "$1" =~ .*--role-name.* ]]; then local ROLE_NAME=$2;fi    
        if [[ "$1" =~ .*--dry.* ]]; then local PREFIX="echo";fi
        shift
    done
    $PREFIX mkdir -p roles/${ROLE_NAME}/{defaults,tasks,files,templates,vars,handlers,meta}
    for i in defaults tasks vars handlers meta; do
        if [[ ! -f roles/${ROLE_NAME}/${i}/main.yaml ]]; then
            echo creating file:  roles/${ROLE_NAME}/${i}/main.yaml
        echo "---
# Default Ansible YAML
" > roles/${ROLE_NAME}/${i}/main.yaml
        else
            echo "roles/${ROLE_NAME}/${i}/main.yaml exists ... skipping"
        fi
    done
    return  
}