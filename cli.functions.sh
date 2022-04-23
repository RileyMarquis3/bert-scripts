# "Adjusting CLI behavior ..."
# cli
# enables CTRL+O, see
# http://apple.stackexchange.com/questions/3253/ctrl-o-behavior-in-terminal-app
stty discard undef
# disable START/STOP output control
# frees up CTRL+S for bash history forward search
stty -ixon
set -o vi

#Safety Nets
alias rm='rm -I --preserve-root' #Do not delete / or prompt if deleting more than 3 files at a time #
#confirmation #
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
alias rm='rm -i'

cli.echo.range(){
  [ $# -lt 3 ] && echo "Usage: ranged_output <start_of_range> <end_of_range> <string_prefix> <string_suffix> <num_repetitions>" >&2 && return 1
  [[ -z "$4" ]] && 4=""
  [[ -z "$5" ]] && 5="2"
  for i in `eval echo {$1..$2}`;do echo $3$((1+i*1))$4 | python -c "import sys;line=sys.stdin.readlines()[0];print line*10,";done
}

exe.describe()
{
  type -all $1
}

functions.list(){ awk '{print $3}' < <(typeset -F) ;}
paths.list(){ echo -e ${PATH//:/\\n} ; }


cmd.fu(){
	curl -L "http://www.commandlinefu.com/commands/matching/$@/$(echo -n $@ | openssl base64)/plaintext";
}

#@ cli
#@ shell
