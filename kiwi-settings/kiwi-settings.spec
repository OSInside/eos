#
# spec file for package kiwi-settings
#
# Copyright (c) 2022 Elektrobit Automotive GmbH.
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
Name:           kiwi-settings
Version:        1.1.1
Release:        0
License:        MIT
%if "%{_vendor}" == "debbuild"
Packager:       Marcus Schaefer <marcus.schaefer@elektrobit.com>
%endif
Summary:        KIWI - runtime config file
Group:          System/Management
Source:         %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires:       sudo
BuildArch:      noarch

%description
Provides a KIWI runtime config file suitable for building
embedded images at Elektrobit

%prep
%setup -q

%install
install -D -m 644 kiwi-settings/kiwi.yml %{buildroot}/etc/kiwi.yml

%post
echo 'abuild ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

%preun
sed -i "/abuild ALL=(ALL) NOPASSWD: ALL/d" /etc/sudoers

%files
%defattr(-,root,root)
%config /etc/kiwi.yml

%changelog
