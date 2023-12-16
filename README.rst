SUSE EOS - Embedded OS
======================

OS design for embedded use cases, squashfs based, fully
immutable (except firmware partition), A/B update based on
kexec and update server included. Tested in the cloud,
on real hardware (rPI) and in QEMU/KVM.

Any platform that supports kexec + grub|u-boot can be
supported via EOS

EOS - Image
===========

The OS image as well as the update server are build using
this git sources here:

* https://build.opensuse.org/project/show/home:marcus.schaefer:EOS

Application - Registry
======================

An example application container registry, like an app-store
is the pre-configured container registry in suse-eos and can
be found here:

* https://build.opensuse.org/project/show/home:marcus.schaefer:delta_containers
