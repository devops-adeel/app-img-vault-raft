
source "vagrant" "autogenerated_1" {
  add_clean    = true
  add_force    = true
  communicator = "ssh"
  provider     = "virtualbox"
  source_path  = "centos/7"
}

build {
  sources = ["source.vagrant.autogenerated_1"]

  provisioner "shell" {
    script = "install.sh"
  }

  provisioner "ansible-local" {
    playbook_dir    = "ansible"
    playbook_file   = "ansible/install.yml"
    inventory_file  = "ansible/inventory"
    role_paths      = ["ansible/roles/ansible-role-vault"]
    extra_arguments = ["-vvvv"]
  }

  # post-processor "vagrant-cloud" {
  #   # access_token = "${var.cloud_token}"
  #   box_tag      = "devsop-adeel/vault-raft"
  #   version      = "0.0.1"
  #   version_description = "MVP release of Vault"
  # }

  # provisioner "inspec" {
  #   inspec_env_vars = ["CHEF_LICENSE=accept"]
  #   profile         = "https://github.com/dev-sec/ssh-baseline"
  # }

}
