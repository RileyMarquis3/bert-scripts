# os

# Get OS X Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
os.software.update(){ 
	sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; npm update npm -g; npm update -g; sudo gem update
}

os.display.screensaver(){ 
	"/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine" -background &
}

osx.bootstrap(){

	echo "eyo ${USER}, I'm about to bootstrap the fuck out of your mac ..."
	if ! confirm;then
		echo "Alright then, I'm not installing shit!"
		return
	fi
	# setup inital packages
	brew install vim --with-python --with-ruby --with-perl
	brew install python
	brew install git
	brew install expect

	# set up fonts and base for terminal scheme
	git clone https://github.com/powerline/fonts ~/Documents
	git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

	# setup iterm colours schemes
	curl -o /tmp https:/github.com/mbadolato/iTerm2-Color-Schemes/tarball/master
	tar xvf /tmp/mbadolato-iTerm2-Color-Schemes-2505e91.tar.gz -C /tmp
	mv /tmp/mbadolato-iTerm2-Color-Schemes-2505e91/schemes ~/Documents/iterm-colours

	# create passwordless sudo
	echo "${USER} ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${USER}

	# setup keychain
	curl -o /tmp http://www.funtoo.org/distfiles/keychain/keychain-2.8.2.tar.bz2
	sudo tar -xvf /tmp/keychain-2.8.2.tar.bz2 -C /opt
	echo "export PATH=$PATH:/opt/keychain" >> ~/.zshrc 
	source ~/.zshrc

	# install extra utils
	brew install bash
	brew install moreutils --without-parallel
	brew install parallel
	brew install grsync
	brew install unzip
	brew install homebrew/dupes/openssh
	brew install homebrew/dupes/make
	brew install homebrew/dupes/less 
	brew install coreutils
	brew install wget
	brew install binutils
	brew install homebrew/dupes/diffutils
	brew install gawk
	brew install gnutls
	brew install gzip
	brew install homebrew/dupes/grep --with-default-names
	brew install screen
	brew install watch
	brew install findutils --with-default-names
	brew install gnu-which --with-default-names
	brew install gnu-sed --with-default-names
	brew install gnu-tar --with-default-names
	brew install pidof
	brew install ffmpeg --with-fdk-aac --with-ffplay --with-freetype --with-frei0r --with-libass --with-libvo-aacenc --with-libvorbis --with-libvpx --with-opencore-amr --with-openjpeg --with-opus --with-rtmpdump --with-schroedinger --with-speex --with-theora --with-tools

	# install vagrant
	brew install --cask virtualbox
	brew install --cask vagrant
	brew install --cask vagrant-manager


}

## application shortcuts
excel.open() { /usr/bin/open -a "/Applications/Microsoft\ Office\ 2011/Microsoft\ Excel.app/Contents/MacOS/Microsoft\ Excel"; }
google.chrome.open() { /usr/bin/open -a /Applications/Google\ Chrome.app "${1}" ; }
powerpoint.open() { /usr/bin/open -a /Applications/Microsoft\ Office\ 2011/Microsoft\ PowerPoint.app/Contents/MacOS/Microsoft\ PowerPoint; }
xmind.open() { /usr/bin/open -a /Applications/Xmind.app/Contents/MacOS/XMind; }
alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'
byword.open() { /usr/bin/open -a /Applications/Byword.app/Contents/MacOS/Byword "${1}" ; }
photoshop.open() { /usr/bin/open -a '/Applications/Adobe Photoshop CS5/Adobe Photoshop CS5.app/Contents/MacOS/Adobe Photoshop CS5' "${1}"; }
#turn screen off
alias screenoff="xset dpms force off"

## hardware
### pass options to free ## 
alias meminfo='free -m -l -t'
### get top process eating memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
### get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'
### process
my_ps() { ps $@ -u $USER -o pid,%cpu,%mem,start,time,bsdtime,command ; }
### findPid: find out the pid of a specified process
findPid () { lsof -t -c "$@" ; }
### memHogsTop, memHogsPs:  Find memory hogs
alias memHogsTop='top -l 1 -o rsize | head -20'
alias memHogsPs='ps wwaxm -o pid,stat,vsize,rss,time,command | head -10'
### cpuHogs:  Find CPU hogs
alias cpu_hogs='ps wwaxr -o pid,stat,%cpu,time,command | head -10'
alias ttop="top -R -F -s 10 -o rsize"
alias cpuinfo='lscpu'
## older system use /proc/cpuinfo ##
##alias cpuinfo='less /proc/cpuinfo' ##
## get GPU ram on desktop / laptop## 
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

os.sleep() {
	if ! [[ "$OSTYPE" =~ .*darwin.* ]]; then echo "This works only on OSX"
	return 1
	fi
	usage="""Usage: 
	${FUNCNAME[0]} --password <password>"""
	if [[ "$*" =~ .*--help.* ]];then echo -e "${usage}";return 0;fi
	while (( "$#" )); do
	if [[ "$1" =~ .*--password.* ]]; then _password_=$2;fi    
	shift
	done	
	echo "Computer is going to sleep!"
	process='''
	do shell script "/usr/bin/sudo -k;/usr/bin/sudo /usr/bin/pmset -a hibernatemode 1; /usr/bin/sudo -k" password "_password_" with administrator privileges
	ignoring application responses
	  tell application "Finder" to sleep
	  do shell script "(/bin/sleep 15 && /usr/bin/sudo -k && /usr/bin/sudo /usr/bin/pmset -a hibernatemode 3 && /usr/bin/sudo -k) &> /dev/null &" password "_password_" with administrator privileges
	end ignoring
	'''
	echo "${process}" | osascript - $*
}