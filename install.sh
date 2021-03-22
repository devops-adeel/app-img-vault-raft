#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

sudo dnf install epel-release -y
sudo yum update -y
sudo yum install wget -y
sudo yum install ansible -y
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
sudo dnf install gcc make perl kernel-devel elfutils-libelf-devel kernel-headers bzip2 dkms -y
sudo dnf update kernel-* -y
export KERN_DIR=/usr/src/kernels/$(uname -r)