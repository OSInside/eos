#
# spec file for package eos-setup-registry
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
Name:           eos-setup-registry
Version:        1.1.1
Release:        0
License:        MIT
Summary:        EOS - OCI container registry setup
Group:          System/Management
Source:         %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rsync
BuildArch:      noarch

%description
Provides registry setup services on first boot for EOS

%prep
%setup -q

%install
rsync -av eos-setup-registry/* %{buildroot}/

%files
%defattr(-,root,root)
/usr/sbin/set_rw_registry
/usr/sbin/set_tpmread
/usr/sbin/registry_resize
/usr/lib/systemd/system/registry-rw.service
/usr/lib/systemd/system/registry_resize.service

%changelog
