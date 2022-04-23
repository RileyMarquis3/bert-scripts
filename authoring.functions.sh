avim(){
 local _VIM=/usr/bin/vim
 local FILE=$1
 [[ -z $FILE ]] && { ${_VIM} ; return; }
 local BFILE=$(basename $FILE)
 local BACKUP="$HOME/.backup/vim"
 local NOW=$(date +"d_%m_%Y_%T%P"|sed 's/:/_/g')
 local DEST=${BACKUP}/${BFILE}.${NOW}
 [[ ! -d $BACKUP  ]] && mkdir -p $BACKUP
 [[ -f $FILE ]] && /bin/cp $FILE $DEST
 [[ ! -z $FILE ]] && ${_VIM} ${FILE}
 [[ "$AVIM_VERBOSE" != "" ]] && echo "Backup file stored to $DEST."
}

if ! [[ "$OSTYPE" =~ .*darwin.* ]]; then
  screen.capture () {
    directory_name=screen.capture
    filename=shot_`date '+%Y-%m-%d_%H-%M-%S'`.png
    path=/workspace/png/$directoryname/
    binary="/usr/sbin/screencapture"
    args="-o -i $path$filename"
    [[ -d $path ]] || mkdir -p $path
    $binary $args $path$filename
    echo $path$filename | pbcopy
    # open --reveal $path$filename
  }
fi

alias vim=avim
alias vi=avim
alias lvim="vim -c \"normal '0'\"" #To open last edited file

toc.create() {

  PREFIX=eval
  declare -A params=(
  ["--source|-s$"]="[some/README.md]"
  ["--help|-h$"]="display usage and exit"
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
  grep "^#" ${source} |\
  sed 's|^[ ]*||g' |\
  awk  -F, '\
  BEGIN {
  }{
    basic_name=$1;
    anchor=basic_name
    basic_name_no_hash=basic_name
    gsub(/^[#]* /,"",basic_name_no_hash)
    gsub(/[ ]*$/,"",basic_name_no_hash)
    subs_string=basic_name
    subs = gsub(/#/,"",subs_string);
    gsub(/^[#]+ /,"",anchor);
    gsub(/ /,"-",anchor);
    anchor = tolower(anchor);
    {for (i=0;i<subs-1;i++) printf "    " }
    print "* [" basic_name_no_hash "](#markdown-header-" anchor ")";
  }
  END {
  }'  

}

#@ authoring
