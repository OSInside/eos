#!/bin/bash
# Put this to .ssh/authorized_keys as
# command="/usr/bin/os-update-restricted.sh" ssh-rsa ...
# to restrict the key to os-update only

if [[ "${SSH_ORIGINAL_COMMAND}" =~ ^"sudo cat" ]];then
    exec ${SSH_ORIGINAL_COMMAND}
elif [[ "${SSH_ORIGINAL_COMMAND}" =~ ^test ]];then
    exec ${SSH_ORIGINAL_COMMAND}
else
    exit 1
fi
