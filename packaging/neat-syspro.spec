# Built by scripts/build-rpm inside the workspace container; not meant for a
# distribution's build system (the whole tree is built in %%install).
%global debug_package %{nil}
%global qmldir %{_libdir}/qt6/qml

Name:           neat-syspro
Version:        0.1.0
Release:        %{?snapshot}%{!?snapshot:1}%{?dist}
Summary:        Files, Task Manager and Remote, from Wild OS, for a plain KDE desktop
License:        GPL-3.0-or-later
URL:            https://github.com/neatpluszero/neat-syspro
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake ninja-build gcc-c++ make pkgconf-pkg-config
BuildRequires:  qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel qt6-qttools-devel
BuildRequires:  kf6-kio-devel kf6-solid-devel kf6-kconfig-devel kf6-kcoreaddons-devel kf6-kservice-devel
BuildRequires:  kf6-kwindowsystem-devel kf6-purpose-devel kf6-karchive-devel kf6-kfilemetadata-devel
BuildRequires:  libseccomp-devel libksysguard-devel
BuildRequires:  freerdp-devel libwinpr-devel qtermwidget-devel qtkeychain-qt6-devel wayland-devel wayland-protocols-devel

Requires:       neat-files = %{version}-%{release}
Requires:       neat-taskmanager = %{version}-%{release}
Requires:       neat-remote = %{version}-%{release}

%description
Installs all three Neat apps: Files, Task Manager and Remote.

%package -n neat-ui
Summary:        The QML controls the Neat apps are drawn with
Requires:       qt6-qtdeclarative qt6-qtsvg

%description -n neat-ui
The Neat.UI QML module shared by Files, Task Manager and Remote.

%package -n neat-files
Summary:        File manager laid out like File Explorer
Requires:       neat-ui = %{version}-%{release}
Requires:       kf6-kio-core qt6-qtmultimedia qt6-qtpdf qt6-qtimageformats udisks2
Recommends:     ark kio-extras bubblewrap perl-Image-ExifTool qpdf python3-mutagen

%description -n neat-files
Tabs in the title bar, a breadcrumb address bar, a command bar, and the
Recycle Bin, Home folders and drives in the sidebar. Folders are read and
changed through KIO.

%package -n neat-taskmanager
Summary:        Task Manager: processes, performance, startup apps and services
Requires:       neat-ui = %{version}-%{release}
Requires:       ksystemstats libksysguard

%description -n neat-taskmanager
See and end what is running, and how hard the computer is working.

%package -n neat-remote
Summary:        SSH terminal, SFTP and Remote Desktop client
Requires:       neat-ui = %{version}-%{release}
Requires:       openssh-clients qt6-qtwayland

%description -n neat-remote
Hosts, keys, snippets and port forwarding for SSH, with a file browser over
SFTP, and Remote Desktop (RDP) sessions through FreeRDP.

%prep
%autosetup

%build

%install
make BUILD=%{_builddir}/neat-build PREFIX=%{_prefix} DESTDIR=%{buildroot} \
     CMAKE_EXTRA="-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=%{_lib}"

%files

%files -n neat-ui
%license LICENSE
%{qmldir}/Neat/
%dir %{_datadir}/neat
%dir %{_datadir}/neat/translations
%{_datadir}/neat/translations/neat-ui_*.qm

%files -n neat-files
%license LICENSE
%{_bindir}/neat-files
%{_bindir}/neat-safebox
%{_prefix}/libexec/neat-files/
%{_datadir}/applications/io.github.neatpluszero.NeatFiles.desktop
%{_datadir}/neat/translations/neat-files_*.qm

%files -n neat-taskmanager
%license LICENSE
%{_bindir}/neat-taskmanager
%{_datadir}/applications/io.github.neatpluszero.NeatTaskManager.desktop
%{_datadir}/icons/hicolor/scalable/apps/io.github.neatpluszero.NeatTaskManager.svg
%{_datadir}/icons/hicolor/scalable/apps/neat-process.svg
%{_datadir}/neat/translations/neat-taskmanager_*.qm

%files -n neat-remote
%license LICENSE
%{_bindir}/neat-remote
%{_datadir}/applications/io.github.neatpluszero.NeatRemote.desktop
%{_datadir}/icons/hicolor/scalable/apps/io.github.neatpluszero.NeatRemote.svg
%{_datadir}/neat-remote/
%{_datadir}/neat/translations/neat-remote_*.qm
