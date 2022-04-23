
es.ingest() {

  PREFIX=eval
  declare -A params=(
  ["--inputs|-i$"]="[/path/to/messages.json]"
  ["--elasticsearch_url|-u$"]="[/path/to/messages.json]"
  ["--endpoint|-e$"]="[e.g. outlook/emails/_bulk?pretty]"
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
  ls ${inputs} | while read data_file; do 
  	echo "Loading ${data_file}"
  	$PREFIX curl -k -s -H 'Content-Type:application/x-ndjson' \
  	-XPOST "${elasticsearch_url// /}/${endpoint// /}" \
  	--data-binary @"${data_file}"
  	echo "Finished loading ${data_file}"
  done
}
