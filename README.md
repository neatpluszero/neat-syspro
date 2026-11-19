# neat-syspro

Files (file manager), Task Manager and Remote (SSH terminal, SFTP and Remote Desktop client) from
[Wild OS](https://github.com/wildorigins/wildos) (GPL-3.0-or-later), untied from the rest of Wild OS
so they run on a plain Fedora KDE desktop.

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

The host needs the Qt 6 / KF6 runtime of a KDE Plasma install. Files uses Ark for archives. Remote also needs `qtermwidget`,
FreeRDP 3 (`freerdp-libs`), `qtkeychain-qt6` and `openssh-clients`. Remote uses Qt's private GUI
API, so it has to be rebuilt when Qt is updated.

## Changes from upstream

All apps:

- Named Neat (programs `neat-files`, `neat-taskmanager`, `neat-remote`; QML modules `Neat.*`; ids
  `io.github.neatpluszero.NeatFiles` / `NeatTaskManager` / `NeatRemote`) so they can sit beside a
  Wild OS install.
- No `wildosrc`, `/etc/wildos` or Wild OS theme files; colours come from the desktop's `kdeglobals`,
  the clock from the regional format. The Debian packaging is gone.
- Messages say "Task Manager", "Remote" or "the system" instead of "Wild OS".
- Settings saved under the old Wild OS names (`wildosfilesrc`, `wildos-taskmanagerrc`,
  `wildoswindowsrc`) are copied to the Neat names on first run; the old files are left in place.

Files:

- Sidebar: Recycle Bin is the first entry, above Home (`src/placesmodel.cpp`).
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
