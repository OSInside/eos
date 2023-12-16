#
# spec file for package eos-setup-base
#
# Copyright (c) 2022 SUE Linux Products GmbH.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.
#
Name:           eos-setup-base
Version:        1.1.1
Release:        0
License:        MIT
Summary:        EOS - base setup
Group:          System/Management
Source:         %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rsync
BuildArch:      noarch

%description
Provides base setup for EOS

%package -n eos-setup-base-vm
Summary:        EOS - base setup VM

%description -n eos-setup-base-vm
Provides base setup for EOS VM

%package -n eos-setup-base-ec2
Summary:        EOS - base setup EC2

%description -n eos-setup-base-ec2
Provides base setup for EOS EC2

%package -n eos-setup-base-rpi
Summary:        EOS - base setup RPI

%description -n eos-setup-base-rpi
Provides base setup for EOS RPI

%package -n eos-setup-base-ssh
Summary:        EOS - base setup ssh

%description -n eos-setup-base-ssh
Provides ssh setup for EOS

%package -n eos-setup-base-ssh-keys
Summary:        EOS - base ssh keys

%description -n eos-setup-base-ssh-keys
Provides ssh pub keys

%prep
%setup -q

%install
rsync -av eos-setup-base/* %{buildroot}/
mkdir -p %{buildroot}/var/lib/systemd/linger

%files
%defattr(-,root,root)
%dir /var/lib/systemd
%dir /var/lib/systemd/linger
%dir /etc/containers
%dir /etc/systemd
%dir /etc/systemd/network
%dir /etc/systemd/system
%dir /etc/systemd/system/serial-getty@ttyS0.service.d
%dir /etc/udev
%dir /etc/udev/rules.d
%dir /etc/systemd/journald.conf.d
%dir /etc/systemd/timesyncd.conf.d
%config /etc/fstab.script
%config /etc/systemd/journald.conf.d/journald.conf
%config /etc/systemd/timesyncd.conf.d/timesyncd.conf
%config /etc/systemd/network/20-local.network
%config /etc/containers/containers.conf
%config /etc/udev/rules.d/70-persistent-net.rules

%files -n eos-setup-base-ssh
%defattr(-,root,root)
%dir /etc/ssh
%dir /etc/ssh/sshd_config.d
%config /etc/ssh/sshd_config.d/10-root-login.conf

%files -n eos-setup-base-ssh-keys
%defattr(-,root,root)
%dir %attr(0700, root, root) /root/.ssh
/root/.ssh/authorized_keys

%files -n eos-setup-base-rpi
%defattr(-,root,root)

%files -n eos-setup-base-vm
%defattr(-,root,root)
%config /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf

%files -n eos-setup-base-ec2
%defattr(-,root,root)
%dir %attr(0750, root, root) /etc/sudoers.d
%dir /etc/cloud
%dir /etc/cloud/cloud.cfg.d
%dir /etc/dracut.conf.d
%config /etc/cloud/cloud.cfg.d/cloud.cfg
%config /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
%config /etc/dracut.conf.d/07-aws-type-switch.conf
%config /etc/udev/rules.d/69-nvme-timeout.rules
%config /etc/modprobe.d/50-nvme.conf
%config %attr(0440, root, root) /etc/sudoers.d/ec2

%changelog
