# neat-syspro

Files (file manager), Task Manager and Remote (SSH terminal, SFTP and Remote Desktop client) from
[Wild OS](https://github.com/wildorigins/wildos) (GPL-3.0-or-later), untied from the rest of Wild OS
so they run on a plain KDE desktop (Fedora, Debian, Ubuntu).

`packages/` holds upstream packages copied from the commit in `UPSTREAM` and renamed:

- `neat-ui`: the shared QML controls (upstream `wildos-ui`).
- `neat-files`: upstream `wildos-files`.
- `neat-taskmanager`: upstream `wildos-taskmanager`.
- `neat-remote`: upstream `wildos-remote`, with the Remote Desktop engine it needs from upstream
  `wildos-rdp` in `neat-remote/rdp-engine`.

## Build

In the `neat-syspro` Incus workspace (Fedora 44, same Qt/KF6 as the host):

    ws run -- make                # everything, into ./dist
    ws run -- make files          # or: make taskmanager, make remote

## Run on the host

    scripts/run neat-files
    scripts/run neat-taskmanager
    scripts/run neat-remote
    scripts/install-local         # app menu entries in ~/.local; --remove undoes it

## Install as RPMs

    ws run -- scripts/build-rpm        # in the container; writes ./rpm/*.rpm
    sudo dnf install ./rpm/*.rpm       # on the host

One package per app (`neat-files`, `neat-taskmanager`, `neat-remote`), the shared `neat-ui`, and
`neat-syspro`, which pulls in all three. dnf fetches what they need. Rebuild and reinstall after a
Fedora release upgrade or a Qt update. `sudo dnf remove neat-ui` takes everything out again.

## Install as .deb

In a Debian 13 or Ubuntu 26.04 container (as root for the first line):

    scripts/deb-build-deps             # build dependencies; on Debian 13 also turns on trixie-backports
    scripts/build-deb                  # writes ./deb/*.deb
    sudo apt install ./deb/*.deb       # on a machine running the same release

The same five packages as the RPMs. A package only installs on the release it was built on, which is
named at the end of its version (`~debian13`, `~ubuntu26.04`). On Debian 13, `neat-remote` needs
FreeRDP 3.32 from `trixie-backports`, so backports has to be enabled where it is installed; Files and
Task Manager do not need it. `sudo apt remove neat-ui` takes everything out again.

## Packages from GitHub

`.github/workflows/packages.yml` builds the RPMs (Fedora 44) and the .debs (Debian 13, Ubuntu 26.04)
on every push to `main` and every pull request; they are attached to the workflow run as artifacts.
To publish a release, set `Version:` in `packaging/neat-syspro.spec`, commit, and push the tag
`v<version>`: the packages are attached to a GitHub Release of that name.

## Requirements

The host needs the Qt 6 / KF6 runtime of a KDE Plasma install. Files uses Ark for archives. Remote also needs `qtermwidget`,
FreeRDP 3 (`freerdp-libs`), `qtkeychain-qt6` and `openssh-clients`. Remote uses Qt's private GUI
API, so it has to be rebuilt when Qt is updated.

## Changes from upstream

All apps:

- Named Neat (programs `neat-files`, `neat-taskmanager`, `neat-remote`; QML modules `Neat.*`; ids
  `io.github.neatpluszero.NeatFiles` / `NeatTaskManager` / `NeatRemote`) so they can sit beside a
  Wild OS install.
- No `wildosrc`, `/etc/wildos` or Wild OS theme files; colours come from the desktop's `kdeglobals`,
  the clock from the regional format. Upstream's Debian packaging is replaced by `packaging/`.
- Messages say "Task Manager", "Remote" or "the system" instead of "Wild OS".
- Settings saved under the old Wild OS names (`wildosfilesrc`, `wildos-taskmanagerrc`,
  `wildoswindowsrc`) are copied to the Neat names on first run; the old files are left in place.

Files:

- Sidebar: Recycle Bin is the first entry, above Home (`src/placesmodel.cpp`).
- Sidebar: dragging a folder onto empty sidebar space pins it (`qml/Sidebar.qml`); the right-click
  "Pin to sidebar" is unchanged.
- Sidebar: the top section is one list of pins, each marked with a pin at the right; drag them up
  and down to reorder (`PlacesModel::movePinned`). Recycle Bin, Home, Desktop… are pinned by
  default and can be unpinned like any other.
- Recycle Bin: items show thumbnails and open from where the bin keeps them, as in Dolphin
  (`src/localpaths.h` maps bin addresses to the real files KIO reports).
- The system disk is named after the running OS (os-release `NAME`, e.g. "Fedora Linux") instead of a
  hardcoded "Wild OS" (`src/drives.cpp`).
- Search and folder sizes stay out of kernel file systems (`/proc`, `/sys`, `/dev`); a whole disk is sized
  from its used space instead of being walked (`Drives::pseudoPath`, `src/foldermodel.cpp`, `src/iteminfo.cpp`).
- Details pane and Properties show real sizes, types and dates for items in the Recycle Bin (`src/iteminfo.cpp`).
- "Report a problem" opens this fork's GitHub issues (`qml/FilesView.qml`).
- Standalone: nothing is read from or sent to the rest of Wild OS.
  - No `wildosrc`, `/etc/wildos`, `/var/lib/wildos` or Wild OS theme files; colours, accent, dark mode and
    animation speed come from the desktop's `kdeglobals`, the clock from the regional format.
  - `Neat.UI` lost its `System` (PIN, fingerprint, password hint, window menu, graphics card choice) and
    `AccessShortcuts` types.
  - Name clashes are always asked in Files' own window (no `org.wildos.Dialogs`).
  - "Extract here" and "Compress…" use Ark instead of `wildos-archive`; "Open in Terminal" uses the
    desktop's terminal.
  - "Remove personal details" and "Open in safe box" are always offered where their tools exist
    (`exiftool`, `qpdf`, `python3-mutagen`; `bwrap`); the helpers are found beside the program.
  - "Pin to Start", "Dedicated graphics card" and the Emoji menu entry are gone.
  - The Debian packaging, systemd units and D-Bus activation files are gone.
  - Messages say "Files" or "the system" instead of "Wild OS".

Task Manager:

- Windows mode is never present: no `org.wildos.WindowsMode1` calls, no app registry read, no
  Windows apps page (`src/winmode.cpp` is a stub; what drew Windows mode stays hidden).
- "Open file location" asks the desktop's file manager (`org.freedesktop.FileManager1`).
- The disk heading is named after the running OS (os-release `NAME`).
- The friendly-name tables no longer list Wild OS's own programs; no links into Wild OS Settings.

Remote:

- The terminal's colours, font, cursor, history and copy/paste settings are in Remote's own
  `~/.config/neat-remote-terminalrc` (Wild OS reads them from its Terminal app). Settings has a button
  that opens the file; `ColourScheme` takes the name of any Konsole colour scheme.
- Saved passwords go in the keyring under "Neat Remote"; hosts and snippets in `~/.config/neat-remote`
  and `~/.local/share/neat-remote`. Nothing is migrated from a Wild OS Remote.
