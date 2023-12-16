#!/bin/bash

set -e

OS_CHECK_INTERVAL=1h

ARGUMENT_LIST=(
    "image:"
    "oneshot"
)

usage() {
    echo "os-update-daemon"
    echo "  --image <PATH>"
    echo "      Path to .raw image"
    echo "  --oneshot"
    echo "      No daemon mode"
}

download_image() {
    image_path=$1
    local count
    local update_config=/etc/os-update.yml
    local image
    local image_dir
    local loop_and_part
    local checksum_file
    local name
    image=$(basename "${image_path}")
    image_dir=$(dirname "${image_path}")
    pushd "${image_dir}" || exit 1
    count=0
    for imageurl in $(yq '.update[].image' "${update_config}");do
        name=$(yq ".update[${count}].name" "${update_config}")
        checksum_file="${name}.sha"
        device_link="${name}.dev"
        count=$((count + 1))
        if [ ! "${name}" = "${image}" ];then
            continue
        fi
        logger -s "Downloading ${imageurl}..."
        wget "${imageurl}" --output-document "$$-${name}.xz"
        xz --force -d "$$-${name}.xz"
        if [ -e "${checksum_file}" ];then
            newsum=$(sha1sum "$$-${name}" | cut -f1 -d ' ')
            cursum=$(cut -f1 -d ' ' "${checksum_file}")
            if [ "${newsum}" = "${cursum}" ];then
                logger -s "Checksum unchanged... skipped"
                rm -f "$$-${name}"
                break
            fi
        fi
        if [ -e "${device_link}" ];then
            partition=$(readlink "${device_link}")
            loop_and_part=$(basename "${partition}" | cut -c5-)
            loop=/dev/loop$(echo "${loop_and_part}" | cut -f1 -dp)
            partid=$(echo "${loop_and_part}" | cut -f2 -dp)
            if [ -n "${partition}" ] && lsof "${partition}" &>/dev/null; then
                logger -s "Partition device has active readers... skipped"
                rm -f "$$-${name}" "${device_link}"
                break
            fi
            if ! partx --delete --nr "${partid}":"${partid}" "${loop}";then
                rm -f "$$-${name}" "${device_link}"
                break
            fi
            if ! losetup -d "${loop}";then
                rm -f "$$-${name}" "${device_link}"
                break
            fi
        fi
        mv "$$-${name}" "${name}"
        create_checksum "${name}"
        setup_stream "${image}"
        break
    done
    popd || exit 1
}

setup_stream() {
    image=$1
    device_link="${image}.dev"
    if [ ! -e "${image}" ];then
        logger -s "No such image ${image}"
        return
    fi
    loop=$(losetup -f --show "${image}")
    partid=$(gdisk -l "${loop}" | grep p.lxreadonly | cut -f4 -d" ")
    partx --add --nr "${partid}":"${partid}" "${loop}"
    partition="${loop}p${partid}"
    logger -s "Streaming setup for: $(blkid "${partition}")"
    logger -s "Linking stream to ${device_link}"
    ln -sf "${partition}" "${device_link}"
}

create_checksum() {
    local image=$1
    local checksum_file="${image}.sha"
    logger -s "Create image and checksum: ${checksum_file}"
    sha1sum "${image}" > "${checksum_file}"
}

setup() {
    if [ ! ${UID} = 0 ];then
        logger -s "Needs root permissions"
        exit 1
    fi
}

# read config file
if [ -e /etc/os-update-daemon.conf ];then
    source /etc/os-update-daemon.conf
fi

# read Arguments
if ! opts=$(getopt \
    --longoptions "$(printf "%s," "${ARGUMENT_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
); then
    usage
    exit 1
fi

eval set --"${opts}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)
            argImage=$2
            shift 2
            ;;

        --oneshot)
            argOneShot=1
            shift
            ;;

        *)
            break
            ;;
    esac
done

# setup
setup

# run
if [ "${argOneShot}" ];then
    download_image "${argImage}"
else
    while true; do
        download_image "${argImage}"
        logger -s "Waiting in line: ${OS_CHECK_INTERVAL}..."
        sleep "${OS_CHECK_INTERVAL}"
    done
fi
