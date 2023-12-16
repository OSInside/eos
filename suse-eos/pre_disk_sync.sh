#!/bin/sh

set -ex

#=======================================
# RPI specific
#---------------------------------------
for profile in ${kiwi_profiles//,/ }; do
    if [ "${profile}" = "RPI" ]; then
        #=======================================
        # Setup EFI
        #---------------------------------------
        # move rPI firmware from boot partition(s) to ESP
        cp -a /boot/vc/* /boot/efi/
        rm -rf /boot/vc

        #=======================================
        # Enable USB boot
        #---------------------------------------
        echo "program_usb_boot_mode=1" >> /boot/efi/config.txt

        #=======================================
        # Enable DRM VC4 V3D driver
        #---------------------------------------
        echo "dtoverlay=vc4-kms-v3d" >> /boot/efi/config.txt
        echo "max_framebuffers=2" >> /boot/efi/config.txt
        echo "display_auto_detect=1" >> /boot/efi/config.txt
        echo "disable_overscan=1" >> /boot/efi/config.txt
        echo "gpu_mem=128" >> /boot/efi/config.txt
    fi
done

#=======================================
# Create UUID because squashfs has none
#---------------------------------------
uuid=$(uuidgen)
touch /boot/${uuid}
ln -s /boot/${uuid} /boot/uuid

#=======================================
# Create stub resolv.conf link
#---------------------------------------
# kiwi cleanup has dropped stale resolv.conf
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

#=======================================
# Relink /var/lib/dhcp to /run (rw)
#---------------------------------------
(cd /var/lib && rm -rf dhcp && ln -s /run dhcp)

#=======================================
# Delete stuff we don't need
#---------------------------------------
rm -rf /usr/lib/sysimage/rpm
rm -rf /usr/share/locale
rm -rf /var/log/*
rm -rf /etc/zypp
rm -rf /usr/lib/dracut
rm -rf /usr/lib/zypp
rm -rf /usr/lib*/librpm*
rm -rf /usr/lib*/libzypp*
find /usr/lib/rpm -type f ! -path "*rpmrc" ! -path "*macros" -delete

#==================================
# Turn rpm into a noop
#----------------------------------
# kiwi calls rpm to fetch metadata from the image, but for size
# reasons we try to get rid of all rpm data
cat >/usr/bin/rpm <<- EOF
#!/bin/sh
echo "/read-only system, use os-update or container workload"
EOF
chmod 755 /usr/bin/rpm
