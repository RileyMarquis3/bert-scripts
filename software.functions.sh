app.create(){
	# shamelessly gnabbed from https://gist.github.com/672684
	# version     : 2.0.2
	# author      : Thomas Aylott <oblivious@subtlegradient.com>
	APPNAME=${1:-Untitled}
	if [[ -a "$APPNAME.app" ]]; then
	  echo "App already exists :'(" >&2
	  echo "$PWD/$APPNAME.app"
	  exit 1
	fi
	mkdir -p "$APPNAME.app/Contents/MacOS"
	touch    "$APPNAME.app/Contents/MacOS/$APPNAME"
	chmod +x "$APPNAME.app/Contents/MacOS/$APPNAME"
	DONE=false
	until $DONE ;do
	  read || DONE=true
	  echo "$REPLY" >> "$APPNAME.app/Contents/MacOS/$APPNAME"
	done
	echo "$PWD/$APPNAME.app"
}