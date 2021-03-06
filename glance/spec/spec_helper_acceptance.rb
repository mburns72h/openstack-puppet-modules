require 'beaker-rspec'

hosts.each do |host|

  install_puppet

  on host, "mkdir -p #{host['distmoduledir']}"
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module
    hosts.each do |host|

      # install git
      install_package host, 'git'

      # clean out any module cruft
      shell('rm -fr /etc/puppet/modules/*')

      # install library modules from the forge
      on host, puppet('module','install', '--force', 'puppetlabs-mysql', '--version', '3.2.0'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','dprince/qpid'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-inifile'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-rabbitmq'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','stahnma-epel'), { :acceptable_exit_codes => [0,1] }

      # install puppet modules from git, use master
      shell('git clone https://git.openstack.org/stackforge/puppet-openstacklib /etc/puppet/modules/openstacklib')
      shell('git clone https://git.openstack.org/stackforge/puppet-keystone /etc/puppet/modules/keystone')

      # Install the module being tested
      puppet_module_install(:source => proj_root, :module_name => 'glance')
      # List modules installed to help with debugging
      on hosts[0], puppet('module','list'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
