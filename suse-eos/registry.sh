#!/bin/sh

set -ex

for device in /dev/mapper/loop*;do
    partlabel=$(blkid -s PARTLABEL -o value "${device}")
    if [ "${partlabel}" = "p.lxreadonly" ];then
        root_device=$device
        root_partuuid=$(blkid -s PARTUUID -o value "${root_device}")
    fi
    if [ "${partlabel}" = "p.UEFI" ];then
        esp_device=$device
    fi
    if [ "${partlabel}" = "p.spare" ];then
        reg_instance_device=$device
    fi
done

# Preserve storage
mv var/lib/containers/storage /tmp

# umount write space
umount "${reg_instance_device}"

# create luks for RW registry with initial empty key
cryptsetup \
    -q \
    --key-file /dev/zero \
    --type luks2 \
    --keyfile-size 128 \
    luksFormat "${reg_instance_device}"
cryptsetup \
    --key-file /dev/zero \
    --keyfile-size 128 \
    luksOpen "${reg_instance_device}" luksInstances

# create XFS for RW registry
mkfs.xfs -f -L INSTANCE /dev/mapper/luksInstances

# mount root + ESP
mount "${root_device}" /mnt
mount "${esp_device}" /mnt/boot/efi

# restore storage
mount /dev/mapper/luksInstances /mnt/var/lib/containers/storage
mv /tmp/storage/* /mnt/var/lib/containers/storage/

# register fleet app
mount -t proc proc /mnt/proc
chroot /mnt /usr/bin/flake-ctl podman register \
    --container fleet \
    --target /usr/bin/fleet \
    --app /usr/share/flakes/bin/fleet \
    --base basesystem \
    --opt '\--rm' \
    --opt '\-i' \
    --opt '\--volume /run:/run'
umount /mnt/proc

# umount storage
umount /mnt/var/lib/containers/storage

# close crypt
cryptsetup luksClose luksInstances

# Create grub early boot script
uuid=$(readlink /mnt/boot/uuid)
cat >/mnt/boot/efi/EFI/BOOT/earlyboot.cfg <<-EOF
search --file --set=root ${uuid}
set rootdev=PARTUUID=${root_partuuid}
export rootdev
set prefix=(\$root)/boot/grub2
configfile (\$root)/boot/grub2/grub.cfg
EOF

# Rebuild EFI binary
efi_arch="arm64-efi"
efi_image="bootaa64.efi"
if [ "$(uname -m)" = "x86_64" ];then
    efi_arch="x86_64-efi"
    efi_image="bootx64.efi"
fi
grub2-mkimage \
    -O "${efi_arch}" \
    -o /mnt/boot/efi/EFI/BOOT/"${efi_image}" \
    -c /mnt/boot/efi/EFI/BOOT/earlyboot.cfg \
    -p /mnt/boot/grub2 \
    -d /mnt/usr/share/grub2/"${efi_arch}" \
    linux configfile search_fs_file search normal gzio fat font \
    minicmd gfxterm gfxmenu all_video squash4 loadenv part_gpt \
    part_msdos efi_gop serial test echo

# umount ROOT + ESP
umount /mnt/boot/efi
umount /mnt
