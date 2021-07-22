# encoding: utf-8
# frozen_string_literal: true

title 'Vault Secure Configuration'

vault_executable = attribute(
  'vault_executable',
  value: '/usr/local/bin/vault',
  description: 'The path on the system where the Vault executable is located'
)

vault_service = attribute(
  'vault_service',
  value: 'vault',
  description: 'The name of the vault service'
)

vault_service_path = attribute(
  'vault_service_path',
  value: '/etc/systemd/system/vault.service',
  description: 'The path on the system where the Vault service configuration file is located'
)

vault_dir = attribute(
  'vault_dir',
  value: '/opt/vault',
  description: 'The system path for the vault installation'
)

vault_user = attribute(
  'vault_user',
  value: 'vault',
  description: 'The system user account that the vault service runs as'
)

include_controls 'linux-baseline'
include_controls 'ssh-baseline'

control 'vault-1.0' do
  impact 1.0
  title 'Verify that vault configuration directory permissions are set to 640 or more restrictive'
  desc 'Verify that vault configuration directory permissions are set to 640 or more restrictive'

  describe directory(vault_dir) do
    its('owner') { should eq vault_user }
    it { should_not be_readable.by('others') }
    it { should_not be_writable.by('others') }
    it { should_not be_executable.by('others') }
  end
end

control 'vault-1.2' do
  impact 1.0
  title 'Ensure that the vault service is running'
  desc 'Ensure that the Vault systemd service is running and enabled'

  describe service(vault_service) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'vault-1.3' do
  impact 1.0
  title 'Ensure Vault is not running as root'
  desc 'Ensure that the Vault service is not being run as root'

  describe processes('vault') do
    its('users') { should_not eq ['root'] }
  end
end

control 'vault-1.4' do
  impact 1.0
  title 'Ensure swap is disabled on the system'
  desc 'Ensure that swap is disabled on the system to prevent secrets from being written to disk'

  describe command('swapon -s | grep -v Filename') do
    its('exit_status') { should eq 1 }
  end
end

control 'vault-1.5' do
  impact 1.0
  title 'Verify that vault.service file permissions are set to 644 or more restrictive'
  desc 'Verify that the \'vault.service\' file permissions are correctly set to \'644\' or more restrictive.'

  describe file(vault_service_path) do
    it { should exist }
    it { should be_file }
    it { should be_readable.by('owner') }
    it { should be_writable.by('owner') }
    it { should be_readable.by('group') }
    it { should_not be_writable.by('group') }
    it { should_not be_readable.by('other') }
    it { should_not be_writable.by('other') }
    it { should_not be_executable }
  end
end
