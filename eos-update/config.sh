#!/bin/bash

set -euxo pipefail

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]-[$kiwi_profiles]..."

#======================================
# Setup update config
#--------------------------------------
update_project=https://download.opensuse.org/repositories/home:/marcus.schaefer:/EOS
update_repo=images_ALP
cat >/etc/os-update.yml <<- EOF
---
update:
  -
    image: ${update_project}/${update_repo}/EOS.aarch64-RPI.raw.xz
    name: EOS.aarch64-RPI-ALP.raw
  -
    image: ${update_project}/${update_repo}/EOS.aarch64-EC2.raw.xz
    name: EOS.aarch64-EC2-ALP.raw
  -
    image: ${update_project}/${update_repo}/EOS.x86_64-AB.raw.xz
    name: EOS.x86_64-AB-ALP.raw
EOF

#======================================
# Cloud setup per profile
#--------------------------------------
for profile in ${kiwi_profiles//,/ }; do
    if [ "${profile}" = "ALP-EC2" ] || [ "${profile}" = "TW-EC2" ]; then
        #======================================
        # Services
        #--------------------------------------
        for service in \
            sshd \
            systemd-networkd \
            systemd-resolved \
            chronyd \
            cloud-init-local \
            cloud-init \
            cloud-config \
            cloud-final \
            amazon-ssm-agent
        do
            systemctl enable "${service}"
        done

        #======================================
        # Fetcher
        #--------------------------------------
        systemctl enable os-fetch

        #======================================
        # Disable password based login via ssh
        #--------------------------------------
        ssh_conf=/etc/ssh/sshd_config
        if [ ! -e "${ssh_conf}" ];then
            ssh_conf=/usr/etc/ssh/sshd_config
        fi
        sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' "${ssh_conf}"
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "${ssh_conf}"

        #======================================
        # Remove the password for root
        #--------------------------------------
        sed -i 's/^root:[^:]*:/root:*:/' /etc/shadow

        #======================================
        # Allow root access on serial console
        #--------------------------------------
        grep -E -q '^ttyS0$' /etc/securetty || echo ttyS0 >> /etc/securetty
        # Set up time server
        echo "server 169.254.169.123 iburst" >> /etc/chrony.conf

        #======================================
        # Delete unwanted base files
        #--------------------------------------
        rm -f /root/.ssh/authorized_keys
        rm -f /etc/ssh/sshd_config.d/10-root-login.conf
        rm -f /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf
    fi
done
