#
# spec file for package eos-setup-grub
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
Name:           eos-setup-grub
Version:        1.1.1
Release:        0
License:        MIT
Summary:        EOS - grub setup
Group:          System/Management
Source:         %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
Provides grub setup for EOS variants

%package -n eos-setup-grub-rpi
Summary:        EOS - grub setup rPI

%description -n eos-setup-grub-rpi
Provides grub setup for EOS raspberry PI

%package -n eos-setup-grub-ec2
Summary:        EOS - grub setup EC2

%description -n eos-setup-grub-ec2
Provides grub setup for EOS EC2

%package -n eos-setup-grub-ab
Summary:        EOS - grub setup AB

%description -n eos-setup-grub-ab
Provides grub setup for EOS AB

%package -n eos-setup-grub-static
Summary:        EOS - grub setup Static

%description -n eos-setup-grub-static
Provides grub setup for EOS Static

%prep
%setup -q

%install
mkdir -p %{buildroot}/boot/grub2
cp eos-setup-grub/* %{buildroot}/boot/grub2 

%files -n eos-setup-grub-rpi
%defattr(-,root,root)
%dir /boot/grub2
/boot/grub2/grub.cfg.RPI.aarch64

%files -n eos-setup-grub-ec2
%defattr(-,root,root)
%dir /boot/grub2
/boot/grub2/grub.cfg.EC2.aarch64
/boot/grub2/grub.cfg.EC2.x86_64

%files -n eos-setup-grub-ab
%defattr(-,root,root)
%dir /boot/grub2
/boot/grub2/grub.cfg.AB.aarch64
/boot/grub2/grub.cfg.AB.x86_64

%files -n eos-setup-grub-static
%defattr(-,root,root)
%dir /boot/grub2
/boot/grub2/grub.cfg.Static.aarch64
/boot/grub2/grub.cfg.Static.x86_64

%changelog
