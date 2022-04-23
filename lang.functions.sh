# java
java.run(){ javac "${1}.java" && java "${1%.**}"; }

# nodejs
BINARY=brew
if [[ ("$OSTYPE" =~ .*darwin.*) && ($(type /usr/{,local/}{,s}bin/${BINARY} 2> /dev/null) || $(which $BINARY))  ]]; then
  if type -p rbenv > /dev/null; then eval "$(rbenv init -)"; fi
  export NVM_DIR=~/.nvm
  nvm_prefix=$(brew --prefix nvm)
  if [[ -d $nvm_prefix ]];then
    source $(brew --prefix nvm)/nvm.sh
  fi
fi

config.read()
{
  
  INI_FILE_FORMAT="""
  INI File must be of format:
  [section1]
  key=value
  [section2]
  key=value
  [sectionN]
  key=value
  """

  declare -A params=(
  ["--ini-file|-f$"]="[path/to/ini/file]"
  ["--sections|-s$"]="[INI section to parse]"
  ["--stdout|-o$"]="[Write to STDOUT while parsing]"
  ["--private-key|-v"]="[path/to/private/key.pem]"
  ["--public-key|-b"]="[path/to/public/key.pem]"
  ["--edit|-e"]="EDIT INI"
  )
  # Display help if insufficient args
  if [[ $# -lt 2 ]];then 
    help ${FUNCNAME[0]} "${params}";
    echo "${INI_FILE_FORMAT}"
    return
  fi
  # Parse arguments
  eval $(create_params) 

  if ! [[ -f $ini_file ]];then
    echo "Could not find the specified configuration file ${ini_file}"
    return
  fi
  if [[ "$OSTYPE" =~ .*msys.* ]];then
    local ini_file=${ini_file//~/\~}
  fi
  # Decrypt the file first
  if [[ $edit ]];then
    file.decrypt --target-file $ini_file --edit --no-encrypt
  else
    file.decrypt --target-file "${ini_file}"
    # file.decrypt --target-file $ini_file --public-key ~/.ssh/id_rsa.pub.pem
  fi
  process="from collections import OrderedDict;import os;import sys
if sys.version_info[0] == 2:
  from ConfigParser import RawConfigParser
  from urllib import quote
if sys.version_info[0] >= 3:
  from configparser import RawConfigParser
ini_file = os.path.abspath(os.path.expanduser('${ini_file}'))
sections = '${sections}'
config_is_valid = False
try:
    cfg = RawConfigParser(allow_no_value=True, dict_type=OrderedDict) # specify dict_type although default is already OrderedDict
    cfg.optionxform = str
    cfg.read(ini_file)
    config_is_valid = len(cfg.sections()) > 0
    if not config_is_valid:
        quit('Invalid configuration file: No sections found!')
except Exception as e:
    quit('Error in parsing the configuration file! Error was:\n%s' % e)
settings = OrderedDict()
for section in sections.split(','):
    for key,value in cfg.items(section):
        settings[key] = value
if hasattr(settings,'iteritems'):
  print('\n'.join(['export %s=%s' % (i,v) for i,v in settings.iteritems()]))
else:
  print('\n'.join(['export %s=%s' % (i,v) for i,v in settings.items()]))
    "
  eval "$(python -c "$process")"
  if [[ -n ${stdout} ]]; then
      echo "$(python -c "$process")"
  fi
  # Re-encrypt the file
  echo "Re-encrypting file"
  file.encrypt --target-file "${ini_file}"  
}

config.write()
{
  if [ $# -lt 1 ]; then echo "Usage: ${FUNCNAME[0]} [config_file]"; return 0; fi
  while (( "$#" )); do
    if [[ "$1" =~ .*--ini.* ]]; then ini_file=$2;fi    
    if [[ "$1" =~ .*--section.* ]]; then section=$2;fi
    if [[ "$1" =~ .*--values.* ]]; then values=$2;fi
    shift
  done  
  process="from collections import OrderedDict;from configparser import RawConfigParser as configparser;import sys;import os;
ini_file = '${ini_file}'
section = '${section}'
values = '${values}'
config_exists = os.path.exists(ini_file)
config_is_valid = False
if config_exists:
    try:
        cfg = configparser(allow_no_value=True, dict_type=OrderedDict) # specify dict_type although default is already OrderedDict
        cfg.optionxform = str
        cfg.read(ini_file)
        config_is_valid = len(cfg.sections()) > 0
        if not config_is_valid:
            quit('Invalid configuration file: No sections found!')
    except Exception as e:
        quit('Error in parsing the configuration file! Error was:\n%s' % e)
    settings = OrderedDict()
    cfg.add_section(section)
    for key_value in values.split(','):
        key,value=(key_value.split('='))
        cfg.set(section, key, value)
    with open(ini_file, 'w') as file:
        cfg.write(file)    
    "
  python -c "$process"
}

## yaml
yaml.read () {
    usage="usage: ${FUNCNAME[0]} <yaml_string>"
    if [[ "$*" =~ .*--help.* ]]; then echo $usage;return 1;fi
    y=$1
    python -c "import sys;import yaml;yml=quit('Possibly bad yaml? $usage') if not sys.argv[1] else yaml.load(sys.argv[1]);print yml" "${y}"
}

yaml.validate(){
if [ $# -eq 1 ]; then
  yamlfile="${1}"
else
  echo Enter the full path to the yaml file you want to check
  read yamlfile
fi
if $(python -c 'import yaml, sys; yaml.safe_load(sys.stdin)' < "${1}");then
  echo ok
fi
}

# json
json.validate(){
  if [ $# -eq 1 ]; then
    filepath="${1}"
  else
    echo Enter the full path to the json file you want to check
    read filepath
  fi
  process="import json;
try:
    with open('$filepath') as f:
        result = json.load(f)        
        print('ok: valid json')
except Exception as e:
    quit('FAIL: invalid json: %s' % e)
"
  python -c "${process}"
}

json.to_yaml(){
  if [[ "$*" =~ .*--help.* ]]; then echo -e "usage: ${FUNCNAME[0]} [path/to/file.json]";return 1;fi  
    process="import sys;import json;import yaml
print(yaml.dump(yaml.load(json.dumps(json.loads(open('${1}').read()))), default_flow_style=False))
"
  python -c "$process"
}

# golang

if [[ $os_is_osx ]];then
  export GOPATH=$HOME/go
  export GOROOT=/usr/local/opt/go/libexec
  export PATH=$PATH:$GOPATH/bin
  export PATH=$PATH:$GOROOT/bin
fi

go.init() {
  while (( "$#" )); do
    if [[ "$1" =~ .*--install.* ]]; then local INSTALL="true";fi    
    if [[ "$1" =~ .*--build-hello.* ]]; then local BUILD_TEST="true";fi    
    shift
  done   
  if [ $BUILD_TEST ];then
    mkdir -p $GOPATH/rc/github.com/${GITHUB_USER}
    mkdir -p $GOPATH/src/github.com/${GITHUB_USER}/hello
    hello_world_src='''
    package main
    import "fmt"
    func main() {
    fmt.Printf("Hello, world. I am running Go!")
    }'''
    echo -e "${hello_world_src}" > $GOPATH/src/github.com/${GITHUB_USER}/hello/hello.go
    if go install github.com/${GITHUB_USER}/hello;then 
      hello
    else
      echo "Failed to install your hello world package, see $GOPATH/src/github.com/${GITHUB_USER}/hello/hello.go"
    fi
  fi
}

cs.build(){

  declare -A params=(
  ["--source-file|-s$"]="[path/to/source/file.cs]"
  ["--out-file|-o$"]="[path/to/exe/file.exe]"
  )
  # Display help if insufficient args
  if [[ $# -lt 2 ]];then 
    help ${FUNCNAME[0]} "${params}";
    echo "${INI_FILE_FORMAT}"
    return
  fi
  # Parse arguments
  eval $(create_params)   

  if [[ "$os_is_windows" == 'true' ]];then
    mgmt_automation_dll='c:\Windows\assembly\GAC_MSIL\System.Management.Automation\1.0.0.0__31bf3856ad364e35\System.Management.Automation.dll'
    bin_path='C:\Progra~2\MIB055~1\2017\BuildTools\MSBuild\15.0\Bin\Roslyn\'
    cmd //c "${bin_path}\csc.exe /r:${mgmt_automation_dll} /unsafe /platform:anycpu /out:${out_file-${source_file%%.*}.exe} ${source_file}"
  fi
}