# grep # sed # awk
strings.grep(){ grep -irwe "${1}.*${2}" --include=*.${3} --include=*.${4} .; }
strings.fields.count () { 
	description="""Count the number of fields in piped input according to specified delimiter
	e.g. echo 1:2:3 | strings.fields.count :
	"""
	usage="${description}\nUsage: ${FUNCNAME[0]} <delimiter>"
	if [[ $# -lt 1 || "$*" =~ .*--help.* ]]; then echo -e "${usage}";return 1;fi  
	numfields=$(delimiter=$1;sed "s/[^$delimiter]//g" | awk '{ print length }')
	echo $((numfields +1))
}

string.randomnize(){
	if [[ "$*" =~ .*--help.* ]]; then echo -e "usage: ${FUNCNAME[0]} [string]";return 1;fi  
  	process="import random;import sys
s = sys.stdin.readlines()
s = ''.join(random.sample(s,len(s)))
print s 
"
  python -c "$process"
}

# regex
string.contains() {
	usage="usage: ${FUNCNAME[0]} <list of strings> <search string>"
	if [[ $# -lt 2 || "$*" =~ .*--help.* ]]; then echo -e "${usage}";return 1;fi  
    [[ "${1}" =~ "${2}" ]] && echo yes || echo no
}

string.grep() {
	if [[ $# -lt 1 || "$*" =~ .*--help.* ]]; then echo -e "usage: ${FUNCNAME[0]} <regex pattern>";return 1;fi  
  	process="import re;import sys;import os;
def err(message):
  return message
def mmatches(s):
  return all([hasattr(re.search('$1',s),'group'),hasattr(re.search('$2',s),'group')])
lines = map(lambda l: l.rstrip('\r\n'), sys.stdin.readlines());
# print re.search('$1',lines) or err('fail')
matched = [(re.search('$1',l).group(),re.search('$2',l).group()) if mmatches(l) else None for l in lines if re.search('$1',l)] or err(None)
result = matched[0] if matched else None
if result:
  print result[0]
#lines = filter(lambda s:'$1',lines)
# print lines
"
  python -c "$process"
  #   python -c "import re;import sys;import os;lines = map(lambda l: l.rstrip('\r\n'), sys.stdin.readlines());lines = filter(lambda s:"$1",lines);print lines"
}

string.check.bad_quotes() {
  	#echo -e "$1" | od -t cx1 |  tr -d \\n
  	process="import re;import sys;import os;
def err(message):
  return message
unicode_list = [u'\u201C',u'\u201D',u'\u2018',u'\u2019']
pattern = re.compile('|'.join(unicode_list), re.UNICODE)
lines = [l.decode('utf-8') for l in sys.stdin.readlines()]
bad_quotes = [c for c in lines if pattern.search(c)]
if bad_quotes:
	print bad_quotes
else:
	print 'Found no bad quotes'
"
  python -c "$process"
  #   python -c "import re;import sys;import os;lines = map(lambda l: l.rstrip('\r\n'), sys.stdin.readlines());lines = filter(lambda s:"$1",lines);print lines"
}

string.check.bad_quotes() {
  	#echo -e "$1" | od -t cx1 |  tr -d \\n
  	process="import re;import sys;import os;
def err(message):
  return message
unicode_list = [u'\u201C',u'\u201D',u'\u2018',u'\u2019']
pattern = re.compile('|'.join(unicode_list), re.UNICODE)
lines = [l.decode('utf-8') for l in sys.stdin.readlines()]
bad_quotes = [c for c in lines if pattern.search(c)]
if bad_quotes:
	print bad_quotes
else:
	print 'Found no bad quotes'
"
  python -c "$process"
}

string.search () {
    usage="usage: ${FUNCNAME[0]} <yaml_string>"
    if [[ "$*" =~ .*--help.* ]]; then echo $usage;return 1;fi
    process="import sys;import re;string=re.compile('$1')
lines = [l.rstrip('\r\n') for l in sys.stdin.readlines()]
matched = [string.search(l).group() for l in lines if string.search(l)] or quit(None)
if matched:
	print('\n'.join(matched))"
  python -c "${process}"
}
