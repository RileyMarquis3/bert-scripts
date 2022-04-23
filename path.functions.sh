# PATH

# GOROOT is the location where the Go package is installed on your system
# GOPATH is the location of your work directory. 
# e.g. ~/HOME/go/projects

PATHS="""
${LOCALAPPDATA}/Programs/Git/mingw64/bin
/c/git-sdk-64
/c/Progra~1/OpenSSL/bin
/c/oracle/instantclient_12_2
/c/ProgramData/Bind9/bin
/c/Users/$USER/Appdata/Local/Programs/nvm
$HOME/AppData/Local/Programs/nvm
$HOME/AppData/Local/Programs/nvm/v16.5.0
/c/tools/ruby24/bin
${HOME}/.conda/envs/py3
${HOME}/.conda/envs/py3/Scripts
/c/ProgramData/Miniconda3
/c/ProgramData/Miniconda3/Scripts
/c/tools/miniconda3/Scripts
/c/Progra~1/SUBLIM~1
$HOME/google-cloud-sdk/bin
/c/Programdata/chocolatey/bin
/usr/local/sbin
/usr/local/bin
/usr/local/opt/sqlite/bin
/c/ProgramData/Anaconda3/envs/py3
/c/ProgramData/Anaconda3/Scripts
${PATH}
/c/Progra~1/nodejs
/c/Progra~1/Oracle/VirtualBox
/c/aspell/bin
/c/Progra~2/Aspell/bin
/mingw64/bin/gcc
/c/HashiCorp/Vagrant/embedded/mingw64/bin
/c/HashiCorp/Vagrant/embedded/usr/bin
/c/HashiCorp/Vagrant/bin
${HOME}/AppData/Roaming/npm
/c/Progra~2/MIB055~1/2017/BuildTools/MSBuild/15.0/Bin
/c/Progra~2/MIB055~1/2017/BuildTools/MSBuild/15.0/Bin/Roslyn
${HOME}/.cargo/bin
 $HOME/ProgramData/nvm
"""
exclusions="/c/Program Files/Git/bin/git"
NEW_PATH=$(echo "${PATHS}" | tr ':' '\n' | egrep -v "${exclusions}" | sort -u | egrep '^/' | tr '\n' ':')
export PATH=${NEW_PATH}