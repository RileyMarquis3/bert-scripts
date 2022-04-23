PS1='\[\033[0;32m\]\[\033[0m\033[0;32m\]\u\[\033[0;36m\] @ \w\[\033[0;32m\]\n[$(git branch 2>/dev/null | grep "^*" | cut -c 2-)\[\033[0;32m\] ]\[\033[0m\033[0;32m\] \$\[\033[0m\033[0;32m\]\[\033[0m\]'

git.set.tracking(){


  USAGE="""
  Description: Sets the remote tracking for the current branch
  If now arguments specified, it will set the remote to 'origin'
  Usage:
    ${FUNCNAME[0]} [--origin|-o <name_of_origin>]
  """
  # args
  num_args=$#
  allargs=$*
  
  while (( "$#" )); do
    if [[ "$1" =~ ^--origin$|^-o$ ]]; then origin_name="${2}";shift;fi
    if [[ "$1" =~ ^--help$|^-h$ ]]; then help=true;fi
    shift
  done
  
  # Display help if applicable
  if [[ (-n $help) ]];then 
    echo -e "${USAGE}"
    return
  fi

  current_branch_name=$(git rev-parse --abbrev-ref HEAD)
  git branch --set-upstream-to=${origin_name-origin}/${current_branch_name} ${current_branch_name}

}

git.log.by_file(){

  COMMITS=$(git log --oneline | awk '{print $1}')
  for COMMIT in $COMMITS; do
      #echo $COMMIT
      FILES=$(git show --name-only --oneline $COMMIT| egrep -v ^$COMMIT)
      for FILE in $FILES; do
          echo "$COMMIT:$FILE"
      done
  done
  
}

git.branches.clean(){

  # args
  num_args=$#
  allargs=$*
  
  while (( "$#" )); do
    if [[ "$1" =~ ^--older-than$|^-o$ ]]; then older_than="${2}";shift;fi
    if [[ "$1" =~ ^--help$|^-h$ ]]; then help=true;fi
    shift
  done
  
  # Display help if applicable
  if [[ (-n $help) || ($num_args -lt 1) ]];then 
    help ${FUNCNAME[0]} "${params}";
    return
  fi
  
  branches=$(git branch | grep ${USERNAME-USER} | awk '{print $NF}')
  
  if [[ -n $branches ]];then
    for branch in $branches;do 
      current_branch_age=$(date -d $(echo $branch | cut -d/ -f4) +%s)
      vs_branch_age=$(date -d "${older_than}" +%s)
      branch_target=${branch//origin\//}
      if [ $vs_branch_age -ge $current_branch_age ];
      then
        echo "Deleting ${branch_target}"
        git branch -D ${branch_target}
      else
        echo "Not deleting ${branch_target} as it is not older than ${older_than}"
      fi     
    done
  else
    echo "No branches found"
  fi

}


git.branch.size(){

  git rev-list HEAD |                     # list commits
  xargs -n1 git ls-tree -rl |             # expand their trees
  sed -e 's/[^ ]* [^ ]* \(.*\)\t.*/\1/' | # keep only sha-1 and size
  sort -u |                               # eliminate duplicates
  awk '{ sum += $2 } END { print sum }'

}

git.preview.markdown() {
  PREFIX=eval
  declare -A params=(
  ["--markdown-file|-f$"]="[Markdown-formatted file]"
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
  $PREFIX grip ${markdown_file} -b
}

git.wincred(){
  git config --global credential.helper wincred
}

git.biggest() {

  git rev-list --all --objects | \
  sed -n $(git rev-list --objects --all | \
  cut -f1 -d' ' | \
  git cat-file --batch-check | \
  grep blob | \
  sort -n -k 3 | \
  tail -n40 | \
  while read hash type size; do
       echo -n "-e s/$hash/$size/p ";
  done) | \
  sort -n -k1
}

git.branch.list() {
  for branch in `git branch -r | grep -v HEAD`;do echo -e `git show --format="%ai %ar by %an" $branch | head -n 1` \\t$branch; done | sort -r;
}

git.issue.branch.create (){

  declare -A params=(
  ["--branch-name|-b$"]="[Name of the Git Branch]"
  ["--branch-type|-t$"]="[Type of branch, e.g. feature, bugfix, hotfix]"
  ["--change-context|-c$"]="[Name of the change context]"
  ["--dry-run|--dry"]="Dry Run"
  )
  # Display help if insufficient args
  if [[ $# -lt 3 ]];then help ${FUNCNAME[0]} "${params}";return;fi
  # Parse arguments
  eval $(create_params)
  # Display help if applicable
  if [[ -n $help ]];then help ${FUNCNAME[0]} "${params}";return;fi
  # DRY RUN LOGIC
  dtm=$(date +%Y%m%d/%H%M)
  if [[ -z $branch_name ]];then
    final_branch_name=${USERNAME-$USER}/$(git rev-parse --abbrev-ref HEAD)/${branch_type}/${dtm}/${change_context}
  else
    final_branch_name=${USERNAME-$USER}/${branch_name-$default_branch_name}/${branch_type}/${dtm}/${change_context}
  fi
  ${dry_run-eval} git checkout -b ${final_branch_name}
}

git.branch.status (){
  git for-each-ref --format="%(refname:short) %(upstream:short)" refs/heads | \
  while read local remote
  do
      [ -z "$remote" ] && continue
      git rev-list --left-right ${local}...${remote} -- 2>/dev/null >/tmp/git_upstream_status_delta || continue
      LEFT_AHEAD=$(grep -c '^<' /tmp/git_upstream_status_delta)
      RIGHT_AHEAD=$(grep -c '^>' /tmp/git_upstream_status_delta)
      echo "$local (ahead $LEFT_AHEAD) | (behind $RIGHT_AHEAD) $remote"
  done
}

function git.release_notes ()
{
  declare -A params=(
  ["--remote-name|-r$"]="[Name Of Your Remote Git Repo]"
  ["--start-tag-or-commit|-s$"]="[Tag Name to Start From]"
  ["--end-tag-or-commit|-e$"]="[Tag Name to End At]"
  ["--dry"]="Dry Run"
  )
  # Display help if insufficient args
  if [[ $# -lt 3 ]];then help ${FUNCNAME[0]} "${params}";return;fi
  # Parse arguments
  eval $(create_params)
  # Display help if applicable
  if [[ -n $help ]];then help ${FUNCNAME[0]} "${params}";return;fi
  # DRY RUN LOGIC
  git_branch=$(git rev-parse --abbrev-ref HEAD)
  repo_url=$(git config --get remote.${remote_name}.url | sed 's/\.git//' | sed 's/:\/\/.*@/:\/\//');
  git log --no-merges ${start_tag_or_commit}..${end_tag_or_commit} --format="* %s [%h]($repo_url/commit/%H)" | sed 's/      / /'
} 

git.c () { git commit -m "${1}" ;}

git.redo.commit () {
  [ $# -lt 1 ] && echo "Usage: ${FUNCNAME[0]} <file/dir>" >&2 && return 1
  git add $1
  git commit --amend
  git push -f
}

git.permissions.fix () { cd $(git rev-parse --show-toplevel);sudo chown -R $USER . ;}

git.logs(){
  [ $# -lt 1 ] && echo "Usage: ${FUNCNAME[0]} [date] <branch (optional)>" >&2 && return 1
  # git log --since="${1}" --pretty=oneline $2
  git log --since="${1}" --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short $2

}

git.log.tree(){
  # See the history of the current branch laid out in a tree
  local all=""
  while (( "$#" )); do
      if [[ "$1" =~ .*--all* ]]; then local all="--all";fi
      shift
  done
  git log --graph --pretty=oneline --abbrev-commit --decorate --color $all
}

git.get.last.commit () {
  if [[ -z $1 ]];then branch=$(git rev-parse --abbrev-ref HEAD);else branch=$1;fi
  git log -n 1 --pretty=format:%H $branch
}

git.get.first.commit () {
  if [[ -z $1 ]];then branch=$(git rev-parse --abbrev-ref HEAD);else branch=$1;fi
  git rev-list --max-parents=0 $branch
}

git.reset(){
  git reset --hard origin/$(git rev-parse --abbrev-ref HEAD) && git pull origin $(git rev-parse --abbrev-ref HEAD)
}

git.search(){

  USAGE="""Usage: 
    ${FUNCNAME[0]} [pattern]
  """

  # args
  num_args=$#
  allargs=$*
  
  while (( "$#" )); do
    if [[ "$1" =~ ^--search-string$|^-s$ ]]; then search_string="${2}";shift;fi
    if [[ "$1" =~ ^--case-sensitive$|^-c$ ]]; then case_sensitive=true;fi
    if [[ "$1" =~ ^--help$|^-h$ ]]; then help=true;fi
    shift
  done
  
  # Display help if applicable
  if [[ (-n $help) || ($num_args -lt 1) ]];then 
    echo -e "${USAGE}"
    return
  fi

  if [[ $allargs =~ ' --- ' ]];then
    extraparams=${allargs##*---}
  fi

  git log -E --grep="${search_string?Must specify search string}" $extraparams
}

git.show() {
    cd $1
    branch=`git branch 2> /dev/null | grep -e ^* | sed -E  s/^\\\\\*\ \(.+\)$/\\\\\1/`
    if [ -n "`git status 2> /dev/null | grep 'nothing to commit'`" ]; then
        status="\e[32mok\e[0m"
    else
        status="\e[31mmodified\e[0m"
    fi
    echo -e "\e[1m$1\e[0m (\e[34m$branch\e[0m): \e[1m$status\e[0m"
    cd ..
}

git.whatchanged(){
  [ $# -lt 1 ] && echo "Usage: ${FUNCNAME[0]} <date?" >&2 && return 1
  git whatchanged --since="${1}" --pretty=oneline
}

#--------------------------------------------------------------------------------------------------#
# Git shortcuts
alias git.undocommit='git reset --soft HEAD^'
alias git.recommit='git commit -c ORIG_HEAD'
alias git.ll='ls -alF'
alias git.la='ls -A'
alias git.l='ls -CF'
alias git.ls.untracked='git ls-files --others --exclude-standard'
alias git.ls.delta='(git diff-index --name-only HEAD --;git ls-files --others --exclude-standard)'
alias git.status='git status --short'
alias git.up='git smart-pull'
alias git.L='git smart-log'
alias git.m='git smart-merge'
alias git.b='git branch -rav'
alias git.fmod='git status --porcelain -uno | cut -c4-' # Only the filenames of modified files
alias git.today='git log --since="6am" --pretty=oneline'
alias git.umod='git status --porcelain -u | cut -c4-' # Only the filenames of unversioned files
alias git.branches='for branch in `git branch -r | grep -v HEAD`;do echo -e `git show --format="%ai %ar by %an" $branch | head -n 1` \\t$branch; done | sort -r'
alias gad='git add'
alias gci='git commit -v'
alias gst='git status'
alias gco='git checkout'
alias gb='git branch -v'
alias gba='git branch -a -v'
alias gl='git pull'
alias gp='git push'
alias gP='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gdiff='git diff | mate'
alias gup='git svn rebase'
alias gm='git checkout master'
alias gd='git diff master'