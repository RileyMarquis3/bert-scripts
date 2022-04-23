export BASH_PROFILE="~/.bash_profile"
alias profile.edit="subl -w $BASH_PROFILE;echo Reloading bash profile;source $BASH_PROFILE && echo Reloading of bash profile was successful."
alias profile.reload="source $BASH_PROFILE || echo Reloading of bash profile was successful."
alias watch="watch "
alias recv='nc -4l 6502 | pv -ebr | tar -xvvpf -'
alias remind="export Reminders_List=Personal;remind.me to $*;export Reminders_List=Reminders;"
alias edit.pyqerc='subl ~/.pyqerc'