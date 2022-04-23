# dialog
proceed(){
read PROCEED
if [[ $PROCEED =~ .*n.* || $PROCEED = '' ]]; then \
  echo 'Terminating by your request...';return 1;fi
if [[ $PROCEED =~ .*y.* ]]; then echo 'Proceeding ...';fi  
}