#!/usr/bin/bash
# Check if the configuration file exists
if [ ! -f /etc/ansible/ansible.cfg ]; then
  echo "Ansible configuration file not found."
  exit 1
fi

# Backup the configuration file
cp /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg.bak

# Add the become method to the configuration file
echo "[privilege_escalation]" >> /etc/ansible/ansible.cfg
echo "become = True" >> /etc/ansible/ansible.cfg
echo "become_method = sudo" >> /etc/ansible/ansible.cfg
echo "become_user = root" >> /etc/ansible/ansible.cfg

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
