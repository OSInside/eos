#!/bin/bash

set -ex

declare kiwi_profiles=${kiwi_profiles}

source /etc/os-release

#======================================
# World writable flakes
#--------------------------------------
# This needs a better solution for rootless use, similar to podman
mkdir -p /usr/share/flakes
chmod 777 /usr/share/flakes
chmod 777 /var/lib/firecracker/images
chmod 777 /var/lib/firecracker/storage

#======================================
# Custom flake registry for podman cmds
#--------------------------------------
export CONTAINERS_STORAGE_CONF=/etc/flakes/storage.conf

#======================================
# hostname
#--------------------------------------
echo EOS > /etc/hostname

#======================================
# Import Build Time Containers (RO)
#--------------------------------------
# for profile in ${kiwi_profiles//,/ }; do
#    if [ ! "${profile}" = "Static" ]; then
#        pushd /usr/share/suse-docker-images/native/
#        acceptable_name=$(echo basesystem.*.tar)
#        skopeo copy \
#            docker-archive:"${acceptable_name}" \
#            oci-archive:basesystem.tar:registry.opensuse.org/tw-apps/basesystem
#        podman load -i basesystem.tar
#        rm -f basesystem.*.tar
#        rm -f basesystem.tar
#        popd
#        break
#    fi
# done

#======================================
# Create timesync subdirs
#--------------------------------------
mkdir -p /var/lib/systemd/timesync
mkdir -p /var/lib/private/systemd/timesync

#======================================
# Create container subdirs
#--------------------------------------
mkdir -p /var/lib/containers/storage
mkdir -p /var/cache/containers
mkdir -p /var/lib/cni
mkdir -p /etc/cni/net.d

#======================================
# Link flakes to a writable location
#--------------------------------------
mkdir -p /usr/share/flakes/bin
echo "export PATH=\$PATH:/usr/share/flakes/bin" >> /etc/profile

#======================================
# Move containers to read-only registry
#--------------------------------------
# move containers to additionalimagestores [read-only]
if [ -e /usr/share/flakes/storage ];then
    mv /usr/share/flakes/storage /var/lib/containers/loaded
fi

#======================================
# Move flakes to read-write registry
#--------------------------------------
mkdir -p /var/lib/containers/storage
mv /usr/share/flakes /var/lib/containers/storage/
ln -s /var/lib/containers/storage/flakes /usr/share/flakes

#======================================
# Relink kiwi boxes to RW
#--------------------------------------
mkdir -p /var/lib/containers/storage/kiwi_boxes
ln -s /var/lib/containers/storage/kiwi_boxes /root/.kiwi_boxes

#======================================
# Move firecracker registry to rw
#--------------------------------------
mkdir -p /var/lib/containers/storage/firecracker
mv /var/lib/firecracker/ /var/lib/containers/storage/firecracker/
ln -s /var/lib/containers/storage/firecracker /var/lib/firecracker

chmod 750 /var/lib/containers

#======================================
# Import Build Time Containers (RW)
#--------------------------------------
for profile in ${kiwi_profiles//,/ }; do
    if [ ! "${profile}" = "Static" ]; then
        pushd /usr/share/suse-docker-images/native/
        for container in *.tar ;do
            acceptable_name=$(echo "${container}" | cut -f1 -d.)
            mv "${container}" "${acceptable_name}"
            skopeo copy \
                docker-archive:"${acceptable_name}" \
                oci-archive:"${acceptable_name}":registry.opensuse.org/tw-apps/"${acceptable_name}"
            podman load -i "${acceptable_name}"
            rm -f "${acceptable_name}"
        done
        popd
        break
    fi
done

#======================================
# Setup container policy
#--------------------------------------
# disabled for the moment, allow from anywhere
# cat >/etc/containers/policy.json <<- EOF
# {
#     "default": [
#         {
#             "type": "reject"
#         }
#     ],
#     "transports": {
#         "docker": {
#             "registry.opensuse.org": [
#                 {
#                     "type": "insecureAcceptAnything"
#                 }
#             ]
#         }
#     }
# }
# EOF

#======================================
# Setup flake container storage config
#--------------------------------------
# cat >>/etc/flakes/storage.conf <<- EOF
# [storage.options]
# additionalimagestores = ['/var/lib/containers/loaded']
# EOF

#======================================
# Setup flakes.yml
#--------------------------------------
cat >/etc/flakes.yml <<- EOF
---
generic:
  flakes_dir: /usr/share/flakes
  podman_ids_dir: /var/lib/containers/storage/tmp/flakes
  firecracker_ids_dir: /var/lib/firecracker/storage/tmp/flakes
EOF

#======================================
# Setup default registry
#--------------------------------------
cat >/etc/containers/registries.conf <<- EOF
unqualified-search-registries=["registry.opensuse.org"]

[[registry]]
prefix = "registry.opensuse.org/ubuntu-apps"
location = "registry.opensuse.org/home/marcus.schaefer/delta_containers/containers_ubuntu"

[[registry]]
prefix = "registry.opensuse.org/tw-apps"
location = "registry.opensuse.org/home/marcus.schaefer/delta_containers/containers_tw"
EOF

arch=$(uname -m)

#======================================
# Setup update config
#--------------------------------------
dist=unknown
if [ "${ID}" = "opensuse-tumbleweed" ];then
    dist=TW
fi
if [ "${ID}" = "alp" ];then
    dist=ALP
fi
cat >/etc/os-update.yml <<- EOF
---
update:
  pkey: /run/id_fleet
  server: ec2-user@ec2-3-125-193-126.eu-central-1.compute.amazonaws.com
  name: EOS.${arch}-${kiwi_profiles}-${dist}
EOF

#==================================
# Create ssh host keys
#----------------------------------
/usr/sbin/sshd-gen-keys-start

#==================================
# Delete stuff we don't need
#----------------------------------
rm -f /etc/containers/registries.d/default.yaml
rm -f /etc/containers/mounts.conf
rm -f /usr/share/containers/mounts.conf

#==================================
# Turn grub-mkconfig into a noop
#----------------------------------
# We have to provide a static version of the grub config
# because at the time of the grub2-mkconfig call the
# system is read-only
cp /usr/bin/true /usr/sbin/grub2-mkconfig

#==================================
# Mask services due to RO system
#----------------------------------
for service in \
    systemd-networkd-persistent-storage.service \
    systemd-backlight@.service \
    systemd-rfkill.service \
    systemd-rfkill.socket \
    logrotate.service \
    logrotate.timer
do
    systemctl mask "${service}"
done

#======================================
# Setup services
#--------------------------------------
for service in \
    sshd \
    systemd-resolved
do
    systemctl enable "${service}"
done

#======================================
# Setup grub
#--------------------------------------
mv "/boot/grub2/grub.cfg.${kiwi_profiles}.${arch}" /boot/grub2/grub.cfg
# delete unused grub templates
rm -f /boot/grub2/grub.cfg.*

#======================================
# Setup Profile Specific
#--------------------------------------
for profile in ${kiwi_profiles//,/ }; do
    # RPI
    if [ "${profile}" = "RPI" ] || [ "${profile}" = "RPI5" ]; then
        # RPI required services
        systemctl enable systemd-timesyncd
        systemctl enable update_commit
        systemctl enable registry-rw
        systemctl enable registry_resize
        systemctl enable systemd-networkd
    fi

    # AB
    if [ "${profile}" = "AB" ]; then
        # AB required services
        systemctl enable systemd-timesyncd
        systemctl enable update_commit
        systemctl enable registry-rw
        systemctl enable registry_resize
        systemctl enable systemd-networkd
    fi

    # Static
    if [ "${profile}" = "Static" ]; then
        # Static required services
        systemctl enable systemd-timesyncd
        systemctl enable NetworkManager
    fi

    # EC2
    if [ "${profile}" = "EC2" ]; then
        # Cloud required services
        for service in \
            chronyd \
            cloud-init-local \
            cloud-init \
            cloud-config \
            cloud-final \
            amazon-ssm-agent \
            update_commit \
            systemd-networkd \
            registry-rw \
            registry_resize
        do
            systemctl enable "${service}"
        done
        # Create flake-ctl alias to run via sudo
        echo "alias flake-ctl='sudo flake-ctl'" > /home/ec2-user/.alias
        # Disable password based login via ssh
        ssh_conf=/etc/ssh/sshd_config
        if [ ! -e "${ssh_conf}" ];then
            ssh_conf=/usr/etc/ssh/sshd_config
        fi
        sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' "${ssh_conf}"
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "${ssh_conf}"
        # Remove the password for root
        sed -i 's/^root:[^:]*:/root:*:/' /etc/shadow
        # Allow root access on serial console
        grep -E -q '^ttyS0$' /etc/securetty || echo ttyS0 >> /etc/securetty
        # Set up time server
        echo "server 169.254.169.123 iburst" >> /etc/chrony.conf
    fi
done

# The following should not be needed...

# make sure to create systemd-network user
# For some reason the user was missing on the aarch64 ALP image build
# The call is taken from the systemd spec file and can be
# deleted once the packaging got fixed
/usr/bin/systemd-sysusers systemd-network.conf

# make sure to create systemd-resolve user
# For some reason the user was missing on the aarch64 ALP image build
# The call is taken from the systemd spec file and can be
# deleted once the packaging got fixed
/usr/bin/systemd-sysusers systemd-resolve.conf
