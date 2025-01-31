#!/bin/sh

set -ex

#=======================================
# RPI specific
#---------------------------------------
for profile in ${kiwi_profiles//,/ }; do
    if [ "${profile}" = "RPI" ] || [ "${profile}" = "RPI5" ]; then
        #=======================================
        # Setup EFI
        #---------------------------------------
        # move rPI firmware from boot partition(s) to ESP
        cp -a /boot/vc/* /boot/efi/
        rm -rf /boot/vc
    fi
    if [ "${profile}" = "RPI" ] || [ "${profile}" = "RPI5" ]; then
        cat >/boot/efi/extraconfig.txt <<- EOF
			# Enable USB boot
			program_usb_boot_mode=1

			# Enable DRM VC4 V3D driver
			dtoverlay=vc4-kms-v3d
			max_framebuffers=2
			display_auto_detect=1
			disable_overscan=1
			gpu_mem=128

			# Enable I2C (1)
			dtparam=i2c1=on
		EOF
    fi
    if [ "${profile}" = "RPI5" ]; then
        cat >>/boot/efi/extraconfig.txt <<- EOF
			dtparam=uart0_console
			dtoverlay=uart0
		EOF
    fi
done

#=======================================
# Create UUID because squashfs has none
#---------------------------------------
uuid=$(uuidgen)
touch /boot/${uuid}
ln -s /boot/${uuid} /boot/uuid

#=======================================
# Create kernel links
#---------------------------------------
pushd boot
rm -f Image initrd
ln -s Image-* Image
ln -s initrd-* initrd
popd

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
