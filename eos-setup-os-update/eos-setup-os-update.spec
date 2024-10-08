#
# spec file for package eos-setup-os-update
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
Name:           eos-setup-os-update
Version:        1.1.1
Release:        0
License:        MIT
Summary:        EOS - osupdate tool and service
Group:          System/Management
Source:         %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rsync
Requires:       yq
BuildArch:      noarch

%description
Provides os update tool and commit service for EOS

%package -n eos-setup-os-update-server
Requires:       yq
Summary:        EOS - base setup update server

%description -n eos-setup-os-update-server
Provides tools and services to run the EOS update server

%prep
%setup -q

%install
rsync -av eos-setup-os-update/* %{buildroot}/

%files
%defattr(-,root,root)
/usr/lib/systemd/system/update_commit.service
/usr/sbin/os-update

%files -n eos-setup-os-update-server
%defattr(-,root,root)
%dir /srv/www
%dir /srv/www/fleet
%dir /srv/www/fleet/os-images
/usr/lib/systemd/system/os-update-daemon@.service
/usr/lib/systemd/system/os-update-daemon@.timer
/usr/lib/systemd/system/os-fetch.service
/srv/www/fleet/os-images/fetch
/usr/bin/os-update-daemon.sh
/usr/bin/os-update-restricted.sh
%config /etc/os-update-daemon.conf

%changelog
