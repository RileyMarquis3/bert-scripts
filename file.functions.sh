# file functions
alias rm="rm.safe ${@}"

if [[ $os_is_windows ]];then
  open(){
    explorer //e, ".\\${1////\\}"
  }
fi

alias r='fc -s'
alias ...="cd ../.."
alias ....="cd ../../../"
alias .....="cd ../../../.."

# Aliases for quick interaction with filesystem paths
#
# Popular Home Directories
#
directories=( ~/git ~/Documents ~/Downloads ~/Pictures )
for directory in ${directories[@]};do
  namespace="cd";method=.${directory##*/};
  if [[ ${method} =~ \.$ ]];then 
    method=''
  fi
  eval """function ${namespace}${method}(){ if ! [ -w ${2} ];then HISTFILE=~/.history/.bash_history;fi;cd.remember.history "${HISTFILE}" ${directory}/\${1}; }"""
  tab_completion_options=$(find ${directory} -maxdepth 1 -type d | while read _directory;do
    echo "'${_directory##*/}'"
  done | tr '\n' ' ')
  complete -W "${tab_completion_options}" ${namespace}${method} 
done
#
# Workspace
# 
# ls
workspace_directories=$(find ~/Documents/workspace -maxdepth 1 -type d)
for directory in ${workspace_directories}; do 
  namespace="ls";method=.${directory##*/};
  if [[ ${method} =~ \.$ ]];then 
    method=''
  fi
  eval "function ${namespace}${method}(){ ls -lthra ${directory}/\${1}; }"
done
# cd
for directory in ${workspace_directories}; do 
  namespace="cd";method=.${directory##*/};
  if [[ ${method} =~ \.$ ]];then 
    method=''
  fi
  eval """function ${namespace}${method}(){ if ! [ -w ${2} ];then HISTFILE=~/.history/.bash_history;fi;cd.remember.history "${HISTFILE}" ${directory}/\${1}; }"""
done
#
# Git directories
#
git_directories=$(find ~/git -maxdepth 1 -type d)
for directory in ${git_directories}; do
  namespace="cd.git";method=.${directory##*/};
  if [[ ${method} =~ \.$ ]];then 
    method=''
  fi
  eval """function ${namespace}${method}(){ if ! [ -w ${2} ];then HISTFILE=~/.history/.bash_history;fi;cd.remember.history "${HISTFILE}" ${directory}/\${1}; }"""
  tab_completion_options=$(find ${directory} -maxdepth 1 -type d | while read _directory;do
    echo "'${_directory##*/}'"
  done | tr '\n' ' ')
  complete -W "${tab_completion_options}" ${namespace}${method}  
done
#
# Markdown files
#
for md in $(find ~/Documents/workspace/md -maxdepth 2 -type f -iname '*.md'); do 
  namespace="edit";method=.${md##*/};
  if [[ ${method} =~ \.$ ]];then 
    method=''
  fi
  eval "function ${namespace}${method}(){ code ${md} \${1}; }"
done

biggest(){ du -sk ./* | sort -n | awk 'BEGIN{ pref[1]="K"; pref[2]="M"; pref[3]="G";} { total = total + $1; x = $1; y = 1; while( x > 1024 ) { x = (x + 1023)/1024; y++; } printf("%g%s\t%s\n",int(x*10)/10,pref[y],$2); } END { y = 1; while( total > 1024 ) { total = (total + 1023)/1024; y++; } printf("Total: %g%s\n",int(total*10)/10,pref[y]); }'; }
disk.unmount () { sudo diskutil unmountDisk $1 ;}
disk.list () { sudo diskutil list ;}
disk.erase () { if [ $# -lt 1 ]; then echo "Usage: ${FUNCNAME[0]} <VOLName> <disk#>";else sudo diskutil eraseDisk JHFS+ $1 $2;fi ;}
volume.rename () { sudo diskutil rename "${1}" "${2}" ;}
dir.zip () { zip -r ./"$1".zip "$1" ; } # zip up a directory
dir.count.lines () { find . -type f -not -path "./.git/*" -exec cat {} \; | wc -l; }
file.chown(){ sudo -s chown $1 ; }
file.chmod(){ sudo -s chmod $1 $2 ; }
file.chgrp(){ sudo -s chgrp $1 ; }
file.convert(){
  if [[ ($# -lt 2) ]]; then
    echo "Usage: ${FUNCNAME[0]} --file [/some/file] --format [gde]";return 1
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
file.base64.encode(){
  usage="""Usage:
  ${FUNCNAME[0]} --file [file] [--no-line-wrap]"""
  if [[ ($# -lt 2) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi
  linewrap="true"
  while (( "$#" )); do
      if [[ ( "$1" =~ .*--file.* ) || ( "$1" == -f ) ]]; then f=$2;fi    
      if [[ ( "$1" =~ .*--no-line-wrap.* ) || ( "$1" == -w ) ]]; then linewrap="";fi    
      shift
  done
  if [ $linewrap ]; then
    cat $f | openssl base64
  else
    cat $f | openssl base64 | tr -d '\n'
  fi
  linewrap="true"
}

folder.merge(){
  if [ $# -lt 1 ]; then echo "Usage: ${FUNCNAME[0]} <source_directory> <dest_directory>";return 1;fi
  src=$1
  dest=$2
  echo "I'm about to merge ${src} with ${dest}, do you want to continue?"
  if confirm --graphical;then
    rsync -aviu "${src}" "${dest}"
  else
    echo "Will not proceed"
  fi
}

#   extract:  Extract most know archives with one command
#   ---------------------------------------------------------
 file.extract () {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
             esac
         else
             echo "'$1' is not a valid file"
         fi
 }

file.reverse() { tail -r $1; }
file.show () { open --reveal $1; }
file.text.replace () { grep -l $1 $3 | while read file;do sed -i "s/$1/$2/g" $file;done; }
file.line.delete () { sed -i ${2} -e "${1}d" ; } 
find.newest () { find ./ -cmin -$1 ; }

files.organize.a_z(){
  target=${1-${PWD}}
  if ! test -d "$target";then 
    mkdir -p "${target}";
  fi
  find ./ -maxdepth 1 | while read f ; do
    if test "${f}"; then 
      i=${f##*/}
      i=${i:0:1}
      dir=${i,,}
      if [[ "${f}" =~ ./$|../$ ]];then 
        continue
      fi
      if [[ $dir != [a-z] ]]; then 
        if ! test -d "${target}/#";then 
          echo "Creating ${target}/#"      
          mkdir -p "${target}/#"
        fi
          re="${f}$"
          if [[ "${target}/#" =~ $re ]];then 
            echo "Not moving ${f} to ${target}/${dir} - same file or directory"
            continue
          fi            
          if [[ ! $(test -f "${target}/#/${f}") || ! $(test -d "${target}/#/${f}") ]];then 
            echo "Moving ${f} to ${target}/#"
            mv "$f" "${target}/#"
          else
            echo "Not moving ${f} to ${target}/#/${f} - file or directory exists"
          fi          
      else
        if ! test -d "${target}/${dir}";then 
          echo "Creating ${target}/${dir}"
          mkdir -p "${target}/${dir}"
        fi
        re="${f}$"
        if [[ "${target}/${dir}" =~ $re ]];then 
          echo "Not moving ${f} to ${target}/${dir}/${f} - same file or directory"
          continue
        fi           
        if [[ ! $(test -f "${target}/${dir}/${f}") || ! $(test -d "${target}/${dir}/${f}") ]];then 
          echo "Moving ${f} to ${target}/${dir}"
          mv "$f" "${target}/${dir}"
        else
          echo "Not moving ${f} to ${target}/${dir} - file or directory exists"
        fi
      fi
    fi
  done  
}

files.to.workspace() {
  if [[ "$1" =~ .*--help.* ]];then
    echo "Usage: ${FUNCNAME[0]} --destination [/some/path] [--dry]";return 1
  fi  
  workspace_folder="$HOME/Documents/workspace"
  while (( "$#" )); do
      if [[ "$1" =~ .*--destination.* ]]; then local workspace_folder=$2;fi    
      if [[ "$1" =~ .*--dry.* ]]; then local PREFIX="echo";fi
      shift
  done  
  if ! [ -d $workspace_folder ]; then
    echo "Could not find the workspace folder @ ${workspace_folder}!"
  return 1; fi
  find ./ -maxdepth 1 -type f \( ! -iname ".*" \) | while read f;do 
    workspace="${workspace_folder}/${f##*.}"
    if ! [[ -d "${workspace}" ]];then 
      echo "${workspace} does not exist, creating ${workspace}"
      $PREFIX mkdir $workspace
    fi
    echo "Moving ${f} to ${workspace}"
    $PREFIX mv "${f}" $workspace
  done
}

files.ren () 
{ 
    if [ $# -lt 1 ]; then
        cat  <<EOF
usage: ${FUNCNAME[0]} [-files:<'filename1|filename2'>] [-search:<'string1|string2'>] [-replace:<'string1|string2'>]
EOF
        return 1;
    fi
    process="import re;import sys;
print [item for item in re.split('\s-',''.join(sys.stdin.read()))]
sys.exit()
arguments = dict(item.strip().replace('-','',1).split(':',1) if re.search('^-',item) else item.strip().split(':',1) for item in re.split('\s-',''.join(sys.stdin.read())))
sys.exit(1)
files=arguments['files'].split(';');
search=arguments['search'].split(';');
repl=arguments['replace'].split(';');
print [file for file in files]
";
    echo $* | python -c "$process"
}

# List directories by size, largest on top
function files.largest () {
if [[ "$OSTYPE" =~ .*darwin.* ]]; then ducmd="du -k *";else ducmd="du --max-depth=0 -k *";fi
$ducmd | sort -nr | awk '{ if($1>=1024*1024) {size=$1/1024/1024; unit="G"} else if($1>=1024) {size=$1/1024; unit="M"} else {size=$1; unit="K"}; if(size<10) format="%.1f%s"; else format="%.0f%s"; res=sprintf(format,size,unit); printf "%-8s %s\n",res,$2 }'
}

ls.filter () {
  if [ $# -lt 1 ]; then
    ls
  else
    ls | grep -i "${1}"
  fi
}

function tree() {

  # args
  num_args=$#
  allargs=$*
  
  while (( "$#" )); do
    if [[ "$1" =~ ^--max-depth$|^-d$ ]]; then max_depth="${2}";shift;fi
    if [[ "$1" =~ ^--help$|^-h$ ]]; then help=true;fi
    shift
  done
  
  # Display help if applicable
  if [[ (-n $help) || ($num_args -lt 1) ]];then 
    return
  fi

  find . -maxdepth ${max_depth-10} ! -path './.git/*' -print |\
  sed -e 's;[^/]*/;|____;g;s;____|; |;g'

}

mount.smb(){
  if ! [[ "$OSTYPE" =~ .*darwin.* ]]; then echo "This works only on OSX";return 1;fi
  usage="Usage: ${FUNCNAME[0]} --config {{CONFIG_FILE}} [--root {{MOUNT_ROOT_PATH}}] [--dry]"
  PREFIX="" 
  if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi
  while (( "$#" )); do
      if [[ "$1" =~ .*--config.* ]]; then local CONFIG_FILE=${2};fi    
      if [[ "$1" =~ .*--root.* ]]; then local MOUNT_ROOT=$2;else local MOUNT_ROOT="${HOME}/mounts";fi    
      if [[ "$1" =~ .*--host.* ]]; then local smb_host=${2};fi    
      if [[ "$1" =~ .*--dry.* ]]; then local DRY_RUN="true";PREFIX=echo;fi
      shift
  done  
  if [ -f ${CONFIG_FILE} ];then
    echo "Found config file"
    config.read --ini ${CONFIG_FILE} --sections AUTH,SHARES
  else
    echo "Specified config file not found: ${CONFIG_FILE}"
    return 1
  fi
  if ! ping -c 1 -W 1 ${smb_host} 2>&1 >/dev/null;then 
      echo "${smb_host} is not reachable via ping ... exiting";
      return 1;
  fi 
  echo "${smb_host} is reachable, proceeding ..."
  for share in $(echo -e "${shares}" | tr ',' '\n'); do
      local_mount_path="${MOUNT_ROOT}/${smb_host}/${share}"
      if ! [[ -d "${local_mount_path}" ]];then 
        echo "${local_mount_path} does not exist ... creating"
        if ! eval mkdir -p "'${local_mount_path}'";then
          echo "Unable to create directory: '${local_mount_path}'"
          return 1
        fi
      fi
      echo "Attempting to mount //${smb_host}/${share} on $local_mount_path ..."
      if ! mount -t smbfs //${username}:${password}@${smb_host}/${share} $local_mount_path;then
        echo "Failed to mount //${smb_host}/${share} on $local_mount_path\!"
        continue
      else
        echo "OK\! Mounted //${smb_host}/${share} on $local_mount_path\!"
      fi
    done
}

skip.last () { head -n-$1; }
skip.first () { tail -n +$1; }
# spotlight: Search for a file using MacOS Spotlight's metadata
spotlight () { mdfind "kMDItemDisplayName == '$@'wc"; }

workspace.backup(){
  if [ $# -lt 1 ]; then cat << EOF
No input file specified. 
Backing up default paths ...
EOF
fi  
  backupdir="/Volumes/16GB/"
  for dir in /workspace/md /workspace/py_ /workspace/sh /workspace/xmind; do
  echo "Backing up $dir to $backupdir";sync $dir $backupdir
  echo "Backing up $dir to $backupdir";sync $dir $backupdir
  echo "Backing up $dir to $backupdir";sync $dir $backupdir 
done
}

# Recursively find the largest file in a directory
alias find-largest="find . -type f -print0 | xargs -0 du -s | sort -n | tail -150 | cut -f2 | xargs -I{} du -sh {}"
alias treesize="ncdu -x"
tree.show(){ find $1 -type d -print 2>/dev/null|awk '!/\.$/ {for (i=1;i<NF;i++){d=length($i);if ( d < 5  && i != 1 )d=5;printf("%"d"s","|")}print "---"$NF}'  FS='/'; }
alias cd..='cd ../'                         # Go back 1 directory level (for fast typers)
alias ..='cd ../'                           # Go back 1 directory level
alias ...='cd ../../'                       # Go back 2 directory levels
alias .3='cd ../../../'                     # Go back 3 directory levels
alias .4='cd ../../../../'                  # Go back 4 directory levels
alias .5='cd ../../../../../'               # Go back 5 directory levels
alias .6='cd ../../../../../../'            # Go back 6 directory levels
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'
alias make1mb='mkfile 1m ./1MB.dat'         # make1mb:      Creates a file of 1mb size (all zeros)
alias make5mb='mkfile 5m ./5MB.dat'         # make5mb:      Creates a file of 5mb size (all zeros)
alias make10mb='mkfile 10m ./10MB.dat'      # make10mb:     Creates a file of 10mb size (all zeros)
## refresh nfs mount / cache etc for Apache ##
alias nfsrestart='sync && sleep 2 && /etc/init.d/httpd stop && umount netapp2:/exports/http && sleep 2 && mount -o rw,sync,rsize=32768,wsize=32768,intr,hard,proto=tcp,fsc natapp2:/exports /http/var/www/html &&  /etc/init.d/httpd start'
#rsync
# alias backup="/usr/local/bin/rsync -av --info=progress2 --numeric-ids -E  -axzS $1 $2"

cwrsync.sync(){

  usage="Usage: ${FUNCNAME[0]} --source <path> --destination <path> [optional flags]
  optional flags:
  --exclude <path1>,<path2>,<path3> ..."
  PREFIX=""

  if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi
    while (( "$#" )); do
      if [[ "$1" =~ .*--exclude.* ]]; then local exl=$2;fi    
      if [[ "$*" =~ .*--source.* ]]; then local src=$2;fi    
      if [[ "$*" =~ .*--port.* ]]; then local port=$2;fi    
      if [[ "$*" =~ .*--destination.* ]]; then local dst=$2;fi    
      if [[ "$*" =~ .*--dry.* ]]; then local PREFIX="echo";fi    
      shift
    done 
  rsync_cmd="cmd //c /c/tools/cwRsync/bin/rsync.bat"
  case $dst in
       *@*)
              $PREFIX ${rsync_cmd} --protect-args --size-only -PptlDr --copy-links --chmod=ugo=rwX --no-perms --no-owner --no-group -e "ssh -p ${port-22} -o StrictHostKeyChecking=no" "${src}" "${dst}"
            ;;
       nowhere)
            echo "Very funny..."
            ;;
       *)
            if [[ -e "${exl}" ]];then 
              $PREFIX ${rsync_cmd} -PptlDr --exclude "${exl}" "${src}" "${dst}"
            else
              $PREFIX ${rsync_cmd} -PptlDr "${src}" "${dst}"
            fi
            ;;
  esac

}

files.sync(){ 

  usage="Usage: ${FUNCNAME[0]} --source <path> --destination <path> [optional flags]
  optional flags:
  --exclude <path1>,<path2>,<path3> ..."
  PREFIX=""

  BINARY=rsync
  if ! [[ ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null)) || ($(which $BINARY)) ]];then
  	echo "This function requires ${BINARY}"
  	echo "You can install it with:"
  	if $platform_is_windows;then 
  		echo "choco install rsync"
  	elif $platform_is_osx;then 
  		echo "brew install rsync"
  	elif 
  		$platform_is_linux;then
  		echo "<insert your package manager install command here> rsync"
  	fi
  fi
  if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi
    while (( "$#" )); do
      if [[ "$1" =~ .*--exclude.* ]]; then local exl=$2;fi    
      if [[ "$*" =~ .*--source.* ]]; then local src=$2;fi    
      if [[ "$*" =~ .*--destination.* ]]; then local dst=$2;fi    
      if [[ "$*" =~ .*--dry.* ]]; then local PREFIX="echo";fi    
      shift
    done 

  case $dst in
       *@*)
              $PREFIX rsync --protect-args --size-only -avzPe --archive --copy-links --chmod=ugo=rwX --no-perms --no-owner --no-group --rsync-path "sudo rsync" -e "ssh -o StrictHostKeyChecking=no" "${src}" "${dst}"
            ;;
       nowhere)
            echo "Very funny..."
            ;;
       *)
            if [[ -e "${exl}" ]];then 
              $PREFIX rsync -az -R --progress --partial --exclude "${exl}" "${src}" "${dst}"
            else
              $PREFIX rsync -az -R --progress --partial "${src}" "${dst}"
            fi
            ;;
  esac

}
# alias sync="rsync --Prltvcz -R --progress --partial ${1} ${2}"
alias move="/usr/local/bin/rsync -av --info=progress2 --remove-source-files --numeric-ids -E  -axzS $1 $2"
#mount with columns:
alias mnt='mount |column -t'
# list folders by size in current directory
alias usage="du -h --max-depth=1 | sort -rh"
#Grabs the disk usage in the current directory
alias usage='du -ch 2> /dev/null |tail -1'
#Gets the total disk usage on your machine
alias totalusage='df -hl --total | grep total'
#Shows the individual partition usages without the temporary memory values
alias partusage='df -hlT --exclude-type=tmpfs --exclude-type=devtmpfs'
#Gives you what is using the most space. Both directories and files. Varies on
#current directory
alias most='du -hsx * | sort -rh | head -10'
#progress bar on file copy. Useful evenlocal.
alias cpProgress="rsync --progress -ravz"
#Show text file without comment (#) lines (Nice alias for /etc files which have tons of comments like /etc/squid.conf)
alias nocomment='grep -Ev '\''^(#|$)'\'''
alias diff='colordiff' #must first install  colordiff package :)

# Accepts a checksum file path (w/o extension), and then a list of files to checksum
# If the checksum file doesn't exist, returns failure
# If the checksum file does exist, but the checksums do not match, returns failure
# If the checksum file does exist, but the filenames in the checksum do not match, returns failure
# If the checksum file does exist, and the checksums do match, returns success
# In all cases, the checksum file will be up-to-date after being called.
#
# Note: this function may not be safe for filenames containing whitespace.
verify_or_create_checksum() {
  local checksum_file="$1"
  local files=${@:2}

  if [[ -r "$checksum_file" ]] && [[ $(echo $files | tr ' ' "\n" | sort) == $(cat "$checksum_file" | awk '{ print $2 }' | sort) ]]; then
    comm -12 <(echo $files | sort) <(cat "$checksum_file")
    shasum --status --check "$checksum_file" && return 0
    shasum $files > "$checksum_file"
    return 1
  else
    shasum $files > "$checksum_file"
    return 1
  fi
}

back.this.dir.up(){
  usage="Usage: ${FUNCNAME[0]} --host <remote_host> --source_dir <path> --remote_dir <path>"
  if [[ ($# -lt 1) || ("$*" =~ .*--help.*) ]];then echo -e "${usage}";return 0;fi
    while (( "$#" )); do
      if [[ "$1" =~ .*--host.* ]]; then local remote_host=$2;fi    
      if [[ "$*" =~ .*--remote_dir.* ]]; then local remote_dir=$2;fi    
      if [[ "$*" =~ .*--source_dir.* ]]; then local source_dir=$2;fi
      if [[ "$*" =~ .*--size-threshold.* ]]; then local size_threshold=$2;fi
      if [[ "$*" =~ .*--single_dir.* ]]; then local single_dir="true";fi
      shift
    done  

  if [[ $single_dir ]];then
    directories=${source_dir}
  else
    directories=$(find ${source_dir} -maxdepth 1 \( -type d -o -type l \) | tail -n +2)
  fi
  for directory in $(echo -e "${directories}");
    do
      if [ $size_threshold ];then
        constraint_in_gb=$(( $size_threshold * 1073741824 ))
        if ! [[ $(du -s "${directory}" | awk '{print $1}') -le ${constraint_in_gb} ]];then
          echo "Skipping directory due to size constraint (${size_threshold})"
          continue
        fi        
      fi      
      excludes_file="${directory}/.rdiff.excludes"
      if ! [[ -f $excludes_file ]];then 
        touch $excludes_file
      fi
      ssh ${remote_host} "mkdir -p ${remote_dir}/${directory} 2>/dev/null"
      rdiff-backup --force \
       --terminal-verbosity 8 \
       --print-statistics \
       --exclude-globbing-filelist $excludes_file \
       -b ${directory} ${remote_host}::"${remote_dir}${directory}"
    done
}

alias rm="rm.safe ${@}"
rm.safe(){
        fso=${*: -1}
        protect_file="$HOME/.protected"
        if [[ ($1 =~ -(rf|fr)) && (-f "${protect_file}") && (-s "${protect_file}") ]];then
                if egrep -q $(readlink -f $fso 2>/dev/null) $protect_file 2>/dev/null;then
                    echo -e """
                    You can't remove this protected file system object (${fso})
                    You must first remove it from $HOME/.protected
                    """
                else
                    echo "File system object is not protected, proceeding with rm ${@}"
                    command rm "${@}"
                fi
        else
            echo "No file system object protections file found (~/.protected) or the file is empty ... proceeding with rm ${@}"
            command rm "${@}"
        fi
}
bytes.tohuman(){
  local USAGE="Usage: ${FUNCNAME[0]} --bytes {{NUM_BYTES}} [--dry]"
  if [[ ($# -lt 1) ]]; then 
    echo -e "${USAGE}"
    return 1  
  fi
  local PREFIX="" 
  while (( "$#" )); do
      if [[ "$1" =~ .*--bytes.* ]]; then local BYTES=$2;fi    
      if [[ "$1" =~ .*--dry.* ]]; then local DRY_RUN="true";local PREFIX=echo;fi
      shift
  done
  echo $BYTES | awk '{ split( "KB MB GB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1) v[s] }'
}

locate32.find.dupes(){
  local USAGE="Usage: ${FUNCNAME[0]} [--type <type>] --path <path> --filter <path> --name <pattern>"
  if [[ ($# -lt 2) ]]; then 
    echo -e "${USAGE}"
    return 1  
  fi
  local PREFIX="" 
  while (( "$#" )); do
      if [[ "$1" =~ .*--path.* ]]; then local path_spec=$2;fi    
      if [[ "$1" =~ .*--name.* ]]; then local filename=$2;fi    
      if [[ "$1" =~ .*--type.* ]]; then local file_type=$2;fi
      if [[ "$1" =~ .*--filter.* ]]; then local filter_paths=$2;fi
      if [[ "$1" =~ .*--dry.* ]]; then local DRY_RUN="true";local PREFIX=echo;fi
      shift
  done
  if [[ -n $filename ]];then
   local filename="-iname ${filename}"
  fi
  find "${path_spec}" -type ${file_type-f} ${filename} | while read file_spec;do 
    fso_name=${file_spec##*/}
    fso_bsn=${fso_name%%.*}
    fso_ext=${fso_name##*.}
    if [[ -n $filter_paths ]];then
      results=$(/c/ProgramData/chocolatey/bin/locate.exe -p "T:" -R -t "${fso_ext}" "${fso_bsn}" | egrep "${filter_paths}")
    else
      results=$(/c/ProgramData/chocolatey/bin/locate.exe -p "T:" -R -t "${fso_ext}" "${fso_bsn}")
    fi      
    num_hits=$(echo -n "${results}" | wc -l)
    echo "${file_spec}:${num_hits}"
  done
}