eod.report(){
	today=$(date +%Y%m%d);
	eod_report="/tmp/eod_${today}.txt";
	echo -e '----------------\nEOD Report\n----------------' | tee ${eod_report};
	curl -s $data_url | grep '<table'| sed 's/<br>/\n/g' | grep -v table | sed 's/<\/h5>//' | tee -a ${eod_report}
	slackutil.py post -p file -c ${slack_channel} -T "EOD Report for ${today}" ${eod_report};
}