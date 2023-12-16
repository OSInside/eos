# SUSE EOS - Embedded OS

1. [Introduction](#introduction)
2. [OS and AppStore Projects](#projects)
3. [Run EOS on AWS](#aws)
4. [Run EOS in KVM](#kvm)
5. [Run EOS on RaspberryPI](#rpi)
6. [Run A container workload on EOS](#container)
7. [Run A VM workload on EOS](#firecracker)
8. [Update an EOS instance](#update)

## Introduction <a name="introduction"/>

EOS is an OS design for embedded use cases. Workloads on EOS are
expected to run as container or VM instances. The OS is fully
immutable, except for the firmware partition. It is not expected
that someone works with the system like with a classical server.
This means if the OS has to change, this change needs to be
performed in the OS project which builds the image, then tested
and then published to an EOS update server. Any instance of EOS
can then decide to fetch the update via the ```os-update```
tool. The update uses the A/B partition concept and kexec to
commit on success. The procedure can be compared to the way how
your smartphone runs an update.

EOS and its update server are currently provided on the following
target platforms:

* As AMI images in the AWS public cloud
* As KVM virtual disk images for testing in QEMU/VMware, etc...
* As RaspberryPI disk image for testing on the PIv4

Any platform that supports kexec + grub|u-boot can be
supported via EOS

## OS and AppStore Projects <a name="projects"/>

The value of EOS comes with the projects that builds it. The OS image
as well as the update server are build using the Open Build Service
connected to this git repo. Please find the EOS project here:

* https://build.opensuse.org/project/show/home:marcus.schaefer:EOS

Running applications on EOS are expected to be provided as containers
or VMs. An example registry for container based apps and firecracker
compatible VM images can be found here:

* https://build.opensuse.org/project/show/home:marcus.schaefer:delta_containers

## Run EOS on AWS <a name="aws"/>

I'm hosting EOS AMI images in my private AWS account. If you are
interested in running EOS in AWS please drop me a note and I will
share the AMI with your account.

## Run EOS in KVM <a name="kvm"/>

To run EOS in qemu-kvm fetch the following data and call the run script:

```bash
mkdir binaries
pushd binaries
wget https://download.opensuse.org/repositories/home:/marcus.schaefer:/EOS/images_ALP/EOS.x86_64-AB.raw.xz
popd
wget https://raw.githubusercontent.com/OSInside/eos/master/suse-eos/run
chmod u+x run
./run
```

## Run EOS on RaspberryPI <a name="rpi"/>

To run EOS on a RaspberryPI you need either an SD card or a USB storage disk.
Connect the SD card or the USB stick to your workstation. The following procedure
assumes your SD card or stick device appears as ```/dev/sdx```.

**_NOTE:_** If you dump data to the wrong device serious issues to your
workstation data can be the result. You have been warned !

```bash
wget https://download.opensuse.org/repositories/home:/marcus.schaefer:/EOS/images_ALP/EOS.aarch64-RPI.raw.xz
xz -d EOS.aarch64-RPI.raw.xz
dd if=EOS.aarch64-RPI.raw.xz of=/dev/sdx status=progress
```

Next plugin the SD card or stick to your RaspberryPI and boot up.

**_NOTE:_** There is no graphics system configured on EOS. Thus only console messages
will appear. I recommend to connect a serial console, at best via a TTL2USB switch.
You should be able to see a ```/dev/dri``` device which will allow you to run
a graphical compositor in a privileged container in case you want to run a graphical
workload.

## Run A container workload on EOS <a name="container"/>

EOS has been setup to provide a split OCI container registry. One part of the
registry lives in the read-only area of EOS itself. In this area EOS provides a
pre-populated ```basesystem``` container. The other part of the registry
points to a fully writable and encrypted partition. This area is used to
register and manage container instances. The read-write part of the container
registry can also consume the pre-registered read-only basesystem container.
Managing containers can be done via podman which is part of EOS or any other
container management system e.g k3s but this needs to be installed into EOS
first which requires adaptions to the EOS project.

Along with the well known ways of managing container workloads there is also
another relatively new project that can orchestrate different containers
into one prior launching them. For embedded use cases I find this particularly
interesting and we call this a ```flake```. More about flakes here:

* https://github.com/OSInside/flake-pilot

The AppStore project of EOS hosts OCI container images which are created
to be used as a flake. Some of the containers there are built as delta
base containers, which means they require a basesystem to function. The
advantage here, the delta containers providing the applications are very
small. For example there is the ```lynx``` console web browser. To use
it run the following flake registration:

```bash
flake-ctl podman register --container suse-apps/lynx --target /usr/bin/lynx --app /usr/share/flakes/bin/lynx --base basesystem
```

Once done you have now a new command on your EOS named ```lynx``` and you
can call it like a normal application:

```
lynx
```

The launch indicator gives you a hint that this is not a normal application
but a container workload.

## Run A VM workload on EOS <a name="firecracker"/>

EOS comes with firecracker which is a software by Amazon that allows to run
virtual machine images through KVM. This means for VM workloads it's required
that the machine you run EOS on supports KVM virtualization.

As a user you can run firecracker manually but there is also support for
firecracker in the flake-pilot firecracker backend. Thus starting a VM
workload can also be done as follows:

```bash
flake-ctl firecracker pull --name leap --kis-image https://download.opensuse.org/repositories/home:/marcus.schaefer:/delta_containers/images_leap/firecracker-basesystem.$(uname -m).tar.xz
flake-ctl firecracker register --vm leap --app /usr/share/flakes/bin/mybash --target /bin/bash --overlay-size 20GiB
```

Once done you have now a new command on your EOS named ```mybash``` and you
can call it like a normal application:

```
mybash --version
```

## Update an EOS instance <a name="update"/>

To update the OS part of EOS, not the registry, a tool called ```os-update``` exists.
os-update uses ```/etc/os-update.yml``` to get it's information about updates. There
is an update server image registered as AMI image in my private AWS account and an
instance of it is running to provide a public facing update server for testing.

Thus any instance of EOS can contact this server for updates of the EOS image.
As EOS is a fully immutable OS, the check for an update is based on a simple
checksum between the actual image on the update server and the current root
device of the running system. To check for updates just call

```bash
fleet --getkey
os-update --check
```

To access the update server a key is required. That key can be fetched via
the ```fleet``` container which is pre-populated on the EOS image. For non
public or production images this simple key deployment is of course not suitable.
To actually apply an OS update just call

```bash
os-update --apply
```

The update process will fetch the root OS partition and dump it in either A or B.
After that the system gets activated through kexec. The kexec boot will commit
the new system as the last systemd service in the chain. At this point we expect
the system update to be successful. Only after commit a reboot of the system
will effectively change the root partition device to either A or B. In case
of any issue prior commit, no damage to the system has happened because no
change was effectively committed. If the kexec turns the system into a dead
loop or bricks it a power cycle needs to be issued to return the machine into
a good state again. If after all the system committed the update but you
realize the update is not ok for some other reason you can rollback via

```bash
os-update --rollback
reboot
```

