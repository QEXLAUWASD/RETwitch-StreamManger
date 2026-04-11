# Twitch Title Updater

> [繁體中文](README.zh_TW.md)

An OBS Studio plugin that automatically updates your Twitch stream title and category based on the game process currently running on your PC.

## Features

- Detects running game processes and maps them to Twitch game categories
- Auto-updates stream title and category via the Twitch Helix API
- Configurable title template with `%game%` and `%date%` placeholders
- Optional custom text appended to every title
- "Keep last title" mode — when no game is detected, keeps the current title instead of switching to Just Chatting
- Process exclusion list (by exact name or prefix) to ignore system/background processes
- Hot-reload of `config.json` when edited externally
- Dark mode UI
- Automatic update check against the GitHub releases page

## Requirements

- OBS Studio 31.1.1 or newer
- Windows x64
- A Twitch developer application (Client ID + OAuth access token with `channel:manage:broadcast` scope)

## Installation

### Option A — Installer (recommended)

1. Download the latest `RETwitchTitleUpdater-*-windows-x64-installer.exe` from the [Releases](../../releases) page.
2. Run the installer. It will automatically detect your OBS Studio install directory and place all files in the correct locations.
3. Restart OBS Studio.

### Option B — Manual (ZIP / DLL)

1. Download the latest `.zip` (or standalone `.dll`) from the [Releases](../../releases) page.
2. Extract and copy the files to your OBS plugins folder:
   ```
   %ProgramFiles%\obs-studio\obs-plugins\64bit\RETwitchTitleUpdater.dll
   %ProgramFiles%\obs-studio\data\obs-plugins\RETwitchTitleUpdater\locale\en-US.ini
   ```
3. Restart OBS Studio.

4. Open **Tools → Twitch Auto-Title** and enter your Twitch credentials when prompted.

## Twitch Credentials

You need three values:

| Field | Where to get it |
|---|---|
| **Client ID** | [Twitch Developer Console](https://dev.twitch.tv/console) → your app |
| **Access Token** | OAuth token with `channel:manage:broadcast` scope |
| **Streamer ID** | Your numeric Twitch user ID |

Credentials are stored locally in `%AppData%\obs-studio\plugin_config\twitch-auto-title\config.ini`.

## Usage

1. Open **Tools → Twitch Auto-Title**.
2. Select a running process from the process list, fill in the **Game Name** and **Twitch Category**, then click **Add / Update Mapping**.
3. The plugin polls running processes every 5 seconds. When a mapped process is detected, it automatically updates your Twitch channel title and category.
4. Use **Edit Exclusions** to prevent background apps from being matched.
5. Use **Manual Update Title/Category** to trigger an immediate update.

### Title Template

The default template is `%game% %date%`. You can customise it in the dialog or by editing `config.json` and clicking **Reload config.json**:

```json
{
  "base": "Playing %game% — %date%"
}
```

| Placeholder | Replaced with |
|---|---|
| `%game%` | Detected game name |
| `%date%` | Current date (`YYYY-MM-DD`) |

## Building from Source

### Prerequisites

- CMake 3.28+
- Visual Studio 2022 (Build Tools) with the **Desktop development with C++** workload
- PowerShell 7.2+

### Steps

```powershell
git clone https://github.com/QEXLAUWASD/RETwitch-StreamManger
cd RETwitch-StreamManger

# Configure (downloads OBS sources, Qt6, obs-deps automatically)
cmake --preset windows-x64

# Build
cmake --build --preset windows-x64 --config RelWithDebInfo --parallel

# Install to release/
cmake --install build_x64 --prefix release/RelWithDebInfo --config RelWithDebInfo
```

The plugin DLL will be at `release\RelWithDebInfo\RETwitchTitleUpdater\bin\64bit\RETwitchTitleUpdater.dll`.

To also produce the installer, run (requires [NSIS](https://nsis.sourceforge.io/)):

```powershell
$env:CI = '1'
.github/scripts/Package-Windows.ps1
```

## License

[GPL-2.0-or-later](LICENSE)
