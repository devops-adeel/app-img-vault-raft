#!/usr/bin/env ruby
#
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'

if Gem::Version.new(::Vagrant::VERSION) < Gem::Version.new('1.5')
  Vagrant.require_plugin('vagrant-hostmanager')
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.include_offline = true

  custom_log = ENV['CUSTOM_VAGRANT_LOG'].to_i == 1

  config.vm.define 'source', autostart: false do |source|
    source.vm.box = 'centos/7'
    config.ssh.insert_key = false
  end

  N = 5

  (1..N).each do |machine_id|
    config.vm.define "vault-#{machine_id+1}" do |machine|
      machine.vm.hostname =  "vault-#{machine_id+1}.internal"
      machine.vm.network 'private_network', ip: "10.30.3.#{machine_id+1}"
      machine.vm.box = 'vault_raft_v1_7'
      machine.vm.box_url = 'file://package.box'
      machine.vm.provision 'file', source: 'creds.json',
        destination: '$HOME/.credentials'
      machine.vm.provision 'shell',
        inline: 'sudo cp .credentials /etc/vault.d/'

      if machine_id == N
        machine.vm.provision :ansible do |ansible|
          ansible.verbose = 'v'
          ansible.playbook = 'site.yml'
          ansible.become = true
          ansible.limit = 'all'
        end
      end
    end
  end

  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--memory', '1024']
    vb.gui = false
  end

end
