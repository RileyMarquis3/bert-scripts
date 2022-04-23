google.search-lectures(){
	echo -e """
	This will be your google search:
		${@} + Lecture filetype:pdf
	"""
	if [ $os_is_windows ];then
	'/c/Program Files (x86)/Google/Chrome/Application/chrome' "? ${*} + Lecture filetype:pdf"
	elif [ $os_is_osx ];then 
	/usr/bin/open -a "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "? ${*} + Lecture filetype:pdf"
	fi	
}
