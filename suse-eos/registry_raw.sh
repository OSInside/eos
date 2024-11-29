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

# umount write space
umount "${reg_instance_device}"

# mount root + ESP
mount "${root_device}" /mnt
mount "${esp_device}" /mnt/boot/efi

# mount storage
mount "${reg_instance_device}" /mnt/var/lib/containers/storage

# register fleet app
mount -t proc proc /mnt/proc
chroot /mnt /usr/bin/flake-ctl podman register \
    --container tw-apps/fleet \
    --target /usr/bin/fleet \
    --app /usr/share/flakes/bin/fleet \
    --base tw-apps/basesystem \
    --opt '\--rm' \
    --opt '\-i' \
    --opt '\--volume /run:/run'

# register core app
chroot /mnt /usr/bin/flake-ctl podman register \
    --container tw-apps/basesystem \
    --target /usr/lib/systemd/systemd \
    --app /usr/share/flakes/bin/core \
    --attach \
    --opt '\--privileged' \
    --opt '\--net host' \
    --opt '\-ti'
umount /mnt/proc

# umount storage
umount /mnt/var/lib/containers/storage

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
    all_video boot cat configfile efi_gop fat font gfxmenu \
    gfxterm gzio halt iso9660 jpeg linux loadenv loopback minicmd \
    normal part_gpt part_msdos password password_pbkdf2 png \
    reboot search search_fs_file search_fs_uuid search_label \
    serial squash4 video test true sleep echo

# umount ROOT + ESP
umount /mnt/boot/efi
umount /mnt
