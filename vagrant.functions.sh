# vagrant
alias vagrant='export VAGRANT_DOTFILE_PATH=".vagrant/$(cat .vagrant/tmp/.environment_context 2> /dev/null)";vagrant'
alias vagrant.halt='vagrant halt'
alias vagrant.destroy='vagrant destroy'
alias vagrant.provision='vagrant provision'
alias vagrant.reload='vagrant reload'
alias vagrant.port='vagrant port'
alias vagrant.ssh='vagrant ssh'
alias vagrant.stat='vagrant status'
alias vagrant.up='vagrant up'

# vagrant
v.list () { process='
  begin
    require "yaml"
    require "./lib/config.rb"
    rescue LoadError; puts "You are not in the Vagrant project folder, silly."
    exit
  end
  abort "Could not find #{@enc_file}!" if not File.exist?(@enc_file)
  enc={}
  yaml_content = File.read(@enc_file).gsub("%{environment}", @environment)
  enc_envs = YAML.load(yaml_content).keys
  enc_envs.each do |environment|
    enc.merge!(YAML.load(yaml_content)[environment]["nodes"])
  end
  enc.keys.each do |key|
    puts key
  end'; 
ruby -e "${process}"
}