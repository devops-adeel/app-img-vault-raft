packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "vault" {
  project_id        = var.project_id
  source_image      = var.source_image_id
  ssh_username      = var.ssh_username
  zone              = var.zone
  skip_create_image = true
}

build {
  sources = ["source.googlecompute.vault"]

  provisioner "shell" {
    script = "install.sh"
  }

  provisioner "ansible-local" {
    galaxy_file     = "ansible/requirements.yml"
    playbook_file   = "ansible/install.yml"
    inventory_file  = "ansible/inventory"
    extra_arguments = ["--extra-vars \"vault_storage_backend=integrated cloud=gcp gcp_region=us-central1 gcp_tag=vault\""]
  }

  provisioner "inspec" {
    profile          = "integration_tests"
    user             = "packer"
    inspec_env_vars  = ["CHEF_LICENSE=accept"]
    max_retries      = 3
    valid_exit_codes = [100]
  }
}
