# history
# "Adjusting HISTORY behavior ..."
alias rr="!:0 $1 !!:$"
alias rr='!!:gs/$1/$2'

export default_history_file="$HOME/.bash_history"
export LOCALIZED_HISTORY=true

history.search () { history | grep -i $1 | cut -d' ' -f8- | grep -vi history | sort -u; } 

history.recall() { 
    if [ ! $@ ] ; then 
       echo "Usage: ${FUNCNAME[0]} <PATTERN>" 
       echo "where PATTERN is a part of previously given command" 
    else 
        history | grep $@ | grep -vi "${FUNCNAME[0]}" | more; 
    fi 
} 

if [[ -n $LOCALIZED_HISTORY ]];then 
    # initial shell
    export HISTFILE="${HOME}/.history/${PWD##*/}.dir_bash_history"
    [[ -d ~/.history ]] || mkdir -p ~/.history
    # timestamp all history entries                                                                            
    export HISTTIMEFORMAT="%h/%d - %H:%M:%S "
    export HISTCONTROL=ignoredups:erasedups
    export HISTSIZE=1000000
    export HISTFILESIZE=1000000
    shopt -s histappend ## append, no clearouts                                                               
    shopt -s histverify ## edit a recalled history line before executing                                      
    shopt -s histreedit ## reedit a history substitution line if it failed                                    
    ## Save the history after each command finishes                                                           
    ## (and keep any existing PROMPT_COMMAND settings)                                                        
    export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
    alias cd='if ! [ -w ${2} ];then HISTFILE=~/.history/.bash_history;fi;cd.remember.history "${HOME}/.history/${PWD##*/}.dir_bash_history"'
    history.recall() { 
        if [ ! $@ ] ; then 
           echo "Usage: ${FUNCNAME[0]} <PATTERN>" 
           echo "where PATTERN is a part of previously given command" 
        else 
             grep -h $@ <(history) ~/.history/* | grep -vi "${FUNCNAME[0]}" | more; 
        fi 
    }
    function cd.remember.history()
    {
        # Keep history on a per-directory basis
        # History file is written to according to value of $PWD
        # Default History folder is ~/.history
        curDir="${PWD}"
        curDir_Name="${curDir##*/}"
        curDir_HISTFILE="${HOME}/.history/${curDir_Name}.dir_bash_history"
        export HISTFILE=${1// /_}
        desDir="${2}"
        dir.check(){
            if ! [[ -d "${1}" ]];then
                echo "The directory ${desDir} does not exist!
                You must check yourself before you wreck yourself ..."
                return 1
            fi
        }
        ##### actions logic
        #@special
        ### destination is a special bash variable
        ### e.g. .. ... ....
        if [[ $desDir =~ ^\.*\.$ ]];then 
            #### need to evaluate path
            desDir=$(\cd $desDir && pwd)
            desDir_Name=${desDir##*/}
            dir.check "${desDir}" || return 1
            if [[ ${DEBUG} ]];then echo "${desDir} matched @special, match on ${BASH_REMATCH}";fi
        #@previous
        ### destination matches - shortcut
        ### e.g. -
        elif [[ $desDir == '-' ]];then
            desDir=$(builtin cd $desDir)
            desDir_Name=${desDir##*/}
            dir.check "${desDir}" || return 1
            if [[ ${DEBUG} ]];then echo "${desDir} matched @previous";fi            
        #@hidden
        ### destination begins with a dot followed by an alphanumeric character
        ### e.g. .git
        elif [[ $desDir =~ ^\.[[:alnum:]] ]];then 
            #### need to strip the first character
            desDir_Name=${desDir:1}
            dir.check "${desDir}" || return 1
            if [[ ${DEBUG} ]];then echo "${desDir} matched @hidden, match on ${BASH_REMATCH}";fi
        #@standard
        ### destination begins with an alphanumeric character 
        ### and ends with the same, with no non-alphanumeric characters in between
        ### e.g. git, home, root
        elif [[ $desDir =~ ^[[:alnum:]]*[[:alnum:]]$ ]];then
            #### need to leave as is
            desDir_Name=${desDir}
            dir.check "${desDir}" || return 1
            if [[ ${DEBUG} ]];then echo "${desDir} matched @standard, match on ${BASH_REMATCH}";fi
        #@root
        elif [[ $desDir == "/" ]];then
            desDir_Name=ROOT
            dir.check "${desDir}" || return 1
            if [[ ${DEBUG} ]];then echo "${desDir} matched @root";fi
        #@fqpath
        else
            desDir_Name=${desDir##*/}
            dir.check "${desDir}" || return 1
            # account for fully qualified paths directly under /
            if [[ -z $desDir_Name ]];then desDir_Name=${desDir#*/};fi
            # account for fully qualified paths matching path/
            if [[ -z $desDir_Name ]];then desDir_Name=${desDir};fi
            if [[ ${DEBUG} ]];then echo "${desDir} matched @fqpath, dir name is ${desDir_Name}";fi
            #   account for fully qualified paths directly under ROOT(/)
            if [[ -z $desDir_Name ]];then desDir_Name=${desDir#*/}
            #   account for fully qualified paths matching ${path}/
                elif [[ -z $desDir_Name ]];then desDir_Name=${desDir%/*}
            fi
            if [[ ${DEBUG} ]];then echo "${desDir} matched @fqpath, dir name is ${desDir_Name}";fi
        fi
        # additional sanitization
        # remove trailing slashes from directory specification, except for / path
        if [[ (! $desDir == "/") && ($desDir =~ \/$) ]];then
            desDir=${desDir:0: ${#desDir} - 1}
            desDir_Name=${desDir:0: ${#desDir_Name} - 1}
            if [[ $desDir =~ .*\/.* ]];then desDir_Name=${desDir##*/};fi
        fi
        if [[ ${DEBUG} ]];then
            echo "desDir is ${desDir}"
            echo "desDir_Name is $desDir_Name"
        fi
        desDir_Name=${desDir_Name// /_}
        dex_file_name=".${desDir_Name}.dex"
        dex_file_path="${desDir}/${dex_file_name}"
        if [[ ${DEBUG} ]];then 
            echo "dex filename is ${dex_file_name}, path is ${dex_file_path}"
            if ! [[ -f ${dex_file_path} ]]; then echo "dex file ${dex_file_path} does not exist";fi
        fi
        if [[ -f ${dex_file_path} ]]; then
            source "${dex_file_path}"
        fi
        builtin cd "${desDir}" # do actual cd
        if [[ -w "${desDir}" ]]; then 
            export HISTFILE="${HOME}/.history/${desDir_Name}.dir_bash_history"
            touch $HISTFILE
            if [[ ${DEBUG} ]];then echo "${desDir} is writable";fi
            echo "#"`date '+%s'` >> "${curDir_HISTFILE}"
            echo "cd ${2}" >> "${curDir_HISTFILE}"
            echo "#"`date '+%s'` >> $HISTFILE
        else
            export HISTFILE=~/.history/${desDir_Name}.dir_bash_history
            if [[ ${DEBUG} ]];then echo "${desDir} is not writable";fi
            echo "#"`date '+%s'` >> "${curDir_HISTFILE}"
            echo "cd ${2}" >> "${curDir_HISTFILE}"
            echo "#"`date '+%s'`"$@" >> $HISTFILE
        fi
        if [[ ${DEBUG} ]];then echo "HISTFILE is $HISTFILE";fi
    }
fi

history.servers.retrieve(){
    trap '[ "$?" -eq 0 ] || echo -e "Looks like something went wrong. \nPlease Review step ´$STEP´. \nPress any key to continue..."' return 1
    if [[ ($# -lt 2) ]]; then 
        echo "Usage: ${FUNCNAME[0]} --server [HOST_NAME]";return 1
    fi  
    PREFIX=""
    while (( "$#" )); do
        if [[ "$1" =~ .*--server.* ]]; then local HOST_NAME=$2;fi    
        if [[ "$1" =~ .*--dry.* ]]; then local PREFIX="echo";fi
        shift
    done
    STEP="GETALLHISTORY"
    $PREFIX ssh $HOST_NAME "for dir in $(ls / | grep -e '^home\|^root');do sudo find /$dir -type f -iname '.bash_history' -exec cat {} \;;done" | tee -a "${HOST_NAME}.history.log"
    return 0
}

