function bert.bash.install() {

 argscount=$#
  allargs=${@}

  USAGE="""
  ${BASH_SOURCE[0]}
    --bert-bash-home|-b </path/to/dir>
    --update
    --help
  """

  BERT_BASH_GIT_URL="https://github.com/berttejeda/bert.bash.git"

  while (( "$#" )); do
      if [[ "$1" =~ --bert-bash-git-url|^-g$ ]]; then BERT_BASH_GIT_URL=$2;fi    
      if [[ "$1" =~ --bert-bash-home|^-b$ ]]; then BERT_BASH_HOME=$2;fi    
      if [[ "$1" =~ ^--update$ ]]; then BERT_BASH_UPDATE=true;shift;fi
      if [[ "$1" =~ ^--help$ ]]; then help=true;shift;fi
      shift
  done

  if [[ -n $help ]];then
    echo -e "${USAGE}"
    return
  fi

  BERT_BASH_HOME="${HOME}/.bert.bash"

  echo -n "Checking if bert.bash is installed ... "

  if [[ ! -d "${HOME}/.bert.bash" ]];then
      echo 'Installing bert.bash'
      git clone $BERT_BASH_GIT_URL "${BERT_BASH_HOME}"
      echo "source ${BERT_BASH_HOME}/.installer.sh" >> "${HOME}/.bash_profile"
  elif [[ (-d "${BERT_BASH_HOME}") && ($BERT_BASH_UPDATE) ]];then
      echo -n "updating bert.bash ... "
      pushd "${PWD}"
      cd "${BERT_BASH_HOME}"
      git clean -f
      git checkout .
      git pull
      echo "done"
      popd
  else
      echo 'no need to install or update'
  fi

  echo "Commencing imports!"

  for script in ${BERT_BASH_HOME}/*.sh; do
  start=`date +%s`
  if eval source $script;then
      end=`date +%s`
      runtime=$((end-start))      
      echo -e "${green}${runtime}s: Imported ${script}${reset}"
  else
      echo -e "${red}Failed to import ${script}${reset}"
  fi
  done
}

bert.bash.install

echo -e "${yellow}Wassup home skillet!${reset}"
echo -e "You are logged in as ${bold}${USER-USERNAME}${reset}"
echo -e "Today's date is `date "+%A %d.%m.%Y %H:%M, %Z %z"`"