[![Build Status](https://travis-ci.org/arctiqjacob/ansible-role-vault.svg?branch=master)](https://travis-ci.org/arctiqjacob/ansible-role-vault)

Ansible Role: Vault
===================
A role to deploy a production grade [HashiCorp Vault](https://www.vaultproject.io/).

Role Variables
--------------
Ansible variables are listed below, along with default values (see `defaults/main.yml`):

Controls whether a separate account is created or not and what the user and group should be named.

```yaml
vault_user: 'vault'
vault_group: 'vault'
vault_create_account: true
```

Where to initialize Vault's home, data, and install directory.

```yaml
vault_home_directory: '/etc/vault.d'
vault_data_directory: '/opt/vault'
vault_install_directory: '{{ vault_data_directory }}/bin'
vault_config_file: '{{ vault_home_directory }}/vault.hcl'
```

The version of Vault to install and where it should download its binary from.

```yaml
vault_version: '1.5.5'
vault_archive: 'vault_{{ vault_version }}_linux_amd64.zip'
vault_download: 'https://releases.hashicorp.com/vault/{{ vault_version }}/{{ vault_archive }}'
```

Controls how Vault should be configured. This data is used in the templated out `vault.hcl` file.

```yaml
vault_config:
  client_addr: '0.0.0.0'
  tls_disable: true
  tls_cert_file: ''
  tls_key_file: ''
  http_port: '8200'
  api_port: '8201'
  ui: true
  storage: 'file'
```

`vault_seal_type` controls Vault's sealing mechanism. This data is used in the templated out `vault.hcl` file. Options are: `shamir`, `pkcs11`, and `gcpkms`.

```yaml
seal:
  type: ''
  project: ''
  region: ''
  key_ring: ''
  crypto_key: ''
```

Dependencies
------------
- Consul cluster if using Consul as backend storage.

Example with Integrated Storage on GCP
--------------------------------------
The following example deploys a three node Vault 1.5 cluster with integrated storage in Google Cloud Platform.

Create three compute instances which will host the Vault servers:
```shell
for i in 0 1 2; do
  gcloud compute instances create vault-${i} \
    --async \
    --no-address \
    --boot-disk-size 100GB \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --scopes=https://www.googleapis.com/auth/cloudkms \
    --tags vault
done
```

Create an inventory file:
```shell
$ cat > inventory <<EOF
[vault]
vault-0.c.[PROJECT_ID].internal
vault-1.c.[PROJECT_ID].internal
vault-2.c.[PROJECT_ID].internal
EOF
```

Ensure Python is installed on the servers:
```shell
$ ansible -i inventory vault -m ping
vault-0.c.[PROJECT_ID].internal | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
vault-2.c.[PROJECT_ID].internal | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
vault-1.c.[PROJECT_ID].internal | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

Run the Ansible playbook:
```shell
$ ansible-playbook -i inventory site.yaml
...
PLAY RECAP *********************************************************************
vault-0.c.[PROJECT_ID].internal : ok=11   changed=9    unreachable=0    failed=0   
vault-1.c.[PROJECT_ID].internal : ok=11   changed=9    unreachable=0    failed=0   
vault-2.c.[PROJECT_ID].internal : ok=11   changed=9    unreachable=0    failed=0  
```

Initialize Vault:
```shell
$ export VAULT_ADDR=http://vault-0.c.[PROJECT_ID].internal:8200

$ vault operator init -recovery-shares=1 -recovery-threshold=1
Recovery Key 1: tMoFtiYOuBlf6757jjOl4lCvN1v4NneZhzQqwe3pzxA=

Initial Root Token: s.8OZR9fj3g3mJoxDKlUaE48Yx

Success! Vault is initialized

Recovery key initialized with 1 key shares and a key threshold of 1. Please
securely distribute the key shares printed above.

$ vault login
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.
...

$ vault operator raft list-peers
Node      Address                                    State       Voter
----      -------                                    -----       -----
vault0    vault-0.c.[PROJECT_ID].internal:8201       leader      true
vault1    vault-1.c.[PROJECT_ID].internal:8201       follower    true
vault2    vault-2.c.[PROJECT_ID].internal:8201       follower    true
```

Example with Consul Storage on GCP
----------------------------------
The following example deploys a three node Vault 1.4 cluster with Consul storage in Google Cloud Platform.

Create three compute instances which will host the Consul servers and two compute instances which will host the Vault servers:
```shell
for i in 0 1 2; do
  gcloud compute instances create consul-${i} \
    --async \
    --no-address \
    --boot-disk-size 100GB \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --scopes=compute-ro \
    --tags consul
done

for i in 0 1; do
  gcloud compute instances create vault-${i} \
    --async \
    --no-address \
    --boot-disk-size 100GB \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --scopes=https://www.googleapis.com/auth/cloudkms, compute-ro \
    --tags vault
done
```

Create an inventory file:
```shell
cat > inventory <<EOF
[vault]
[servers]
consul-0.c.[PROJECT_ID].internal
consul-1.c.[PROJECT_ID].internal
consul-2.c.[PROJECT_ID].internal

[clients]
vault-0.c.[PROJECT_ID].internal
vault-1.c.[PROJECT_ID].internal

[vault]
vault-0.c.[PROJECT_ID].internal
vault-1.c.[PROJECT_ID].internal
EOF
```

Create an Ansible playbook, calling both roles:
```shell
cat > main.yaml <<EOF
---
- hosts: servers, clients
  become: yes
  roles:
    - role: ansible-role-consul

- hosts: vault
  become: yes
  roles:
    - role: ansible-role-vault
      vars:
        vault_config:
          client_addr: '0.0.0.0'
          tls_disable: false
          tls_cert_file: 'vault.crt'
          tls_key_file: 'vault.key'
          http_port: '8200'
          api_port: '8201'
          ui: true
          storage: 'consul'
        seal:
          type: 'gcpkms'
          project: '[PROJECT_ID]'
          region: 'global'
          key_ring: '[VAULT_KEY_RING]'
          crypto_key: '[VAULT_KEY]'
EOF
```

Ensure Python is installed on the servers:
```shell
$ ansible -i inventory vault -m ping
vault-1.c.[PROJECT_ID].internal | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
vault-0.c.[PROJECT_ID].internal | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
consul-2.c.[PROJECT_ID].internal | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
consul-1.c.[PROJECT_ID].internal | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
consul-0.c.[PROJECT_ID].internal | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

Run the Ansible playbook:
```shell
$ ansible-playbook -i inventory main.yaml
...
PLAY RECAP *********************************************************************
consul-0.c.blizzard-253119.internal : ok=11   changed=2    unreachable=0    failed=0   
consul-1.c.blizzard-253119.internal : ok=11   changed=2    unreachable=0    failed=0   
consul-2.c.blizzard-253119.internal : ok=11   changed=2    unreachable=0    failed=0   
vault-0.c.blizzard-253119.internal : ok=20   changed=2    unreachable=0    failed=0   
vault-1.c.blizzard-253119.internal : ok=20   changed=2    unreachable=0    failed=0 
```

Initialize Vault:
```shell
$ export VAULT_ADDR=http://vault-0.c.[PROJECT_ID].internal:8200
$ export CONSUL_HTTP_ADDR=http://consul-0.c.[PROJECT_ID].internal:8500

$ vault operator init -recovery-shares=1 -recovery-threshold=1
Recovery Key 1: tMoFtiYOuBlf6757jjOl4lCvN1v4NneZhzQqwe3pzxA=

Initial Root Token: s.8OZR9fj3g3mJoxDKlUaE48Yx

Success! Vault is initialized

Recovery key initialized with 1 key shares and a key threshold of 1. Please
securely distribute the key shares printed above.

$ vault login
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.
...
```

Author Information
------------------
Jacob Mammoliti | jacob.mammoliti@arctiq.ca
Marek Anderson  | marek.anderson@arctiq.ca
