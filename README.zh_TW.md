# Twitch 標題自動更新器

> [English](README.md)

一個 OBS Studio 外掛程式，能根據目前電腦上執行的遊戲程序，自動更新你的 Twitch 直播標題與分類。

## 功能特色

- 偵測執行中的遊戲程序，並對應至 Twitch 遊戲分類
- 透過 Twitch Helix API 自動更新直播標題與分類
- 可自訂標題模板，支援 `%game%` 與 `%date%` 佔位符
- 可在每個標題後附加自訂文字
- 「保留上次標題」模式 — 未偵測到遊戲時，保持目前標題而非切換至 Just Chatting
- 程序排除清單（依完整名稱或前綴），用於過濾系統或背景程序
- 外部修改 `config.json` 時自動熱重載
- 深色模式介面
- 自動檢查 GitHub Releases 頁面的版本更新

## 系統需求

- OBS Studio 31.1.1 或更新版本
- Windows x64
- 一個 Twitch 開發者應用程式（Client ID + 具有 `channel:manage:broadcast` 範圍的 OAuth 存取權杖）

## 安裝方式

### 方法 A — 安裝程式（建議）

1. 從 [Releases](../../releases) 頁面下載最新的 `RETwitchTitleUpdater-*-windows-x64-installer.exe`。
2. 執行安裝程式，它會自動偵測你的 OBS Studio 安裝目錄，並將所有檔案放置至正確位置。
3. 重新啟動 OBS Studio。

### 方法 B — 手動安裝（ZIP / DLL）

1. 從 [Releases](../../releases) 頁面下載最新的 `.zip`（或獨立 `.dll`）。
2. 解壓縮後，將檔案複製至 OBS 外掛資料夾：
   ```
   %ProgramFiles%\obs-studio\obs-plugins\64bit\RETwitchTitleUpdater.dll
   %ProgramFiles%\obs-studio\data\obs-plugins\RETwitchTitleUpdater\locale\en-US.ini
   ```
3. 重新啟動 OBS Studio。

4. 開啟 **工具 → Twitch Auto-Title**，依提示輸入你的 Twitch 認證資訊。

## Twitch 認證資訊

你需要以下三個值：

| 欄位 | 取得方式 |
|---|---|
| **Client ID** | [Twitch 開發者主控台](https://dev.twitch.tv/console) → 你的應用程式 |
| **Access Token** | 具有 `channel:manage:broadcast` 範圍的 OAuth 權杖 |
| **Streamer ID** | 你的 Twitch 帳號數字 ID |

認證資訊儲存於本機的 `%AppData%\obs-studio\plugin_config\twitch-auto-title\config.ini`。

## 使用方式

1. 開啟 **工具 → Twitch Auto-Title**。
2. 從程序清單中選取執行中的遊戲，填入 **遊戲名稱** 與 **Twitch 分類**，然後點擊 **Add / Update Mapping**。
3. 外掛每 5 秒輪詢一次執行中的程序。偵測到已對應的程序時，自動更新 Twitch 頻道標題與分類。
4. 使用 **Edit Exclusions** 防止背景應用程式被誤判。
5. 使用 **Manual Update Title/Category** 立即觸發一次更新。

### 標題模板

預設模板為 `%game% %date%`。你可以在對話框中修改，或直接編輯 `config.json` 後點擊 **Reload config.json**：

```json
{
  "base": "正在玩 %game% — %date%"
}
```

| 佔位符 | 替換內容 |
|---|---|
| `%game%` | 偵測到的遊戲名稱 |
| `%date%` | 當前日期（`YYYY-MM-DD`） |

## 從原始碼建置

### 前置需求

- CMake 3.28+
- Visual Studio 2022（Build Tools），需安裝 **使用 C++ 的桌面開發** 工作負載
- PowerShell 7.2+

### 步驟

```powershell
git clone https://github.com/QEXLAUWASD/RETwitch-StreamManger
cd RETwitch-StreamManger

# 設定（自動下載 OBS 原始碼、Qt6、obs-deps）
cmake --preset windows-x64

# 建置
cmake --build --preset windows-x64 --config RelWithDebInfo --parallel

# 安裝至 release/
cmake --install build_x64 --prefix release/RelWithDebInfo --config RelWithDebInfo
```

外掛 DLL 位於 `release\RelWithDebInfo\RETwitchTitleUpdater\bin\64bit\RETwitchTitleUpdater.dll`。

若需同時產生安裝程式，請執行（需安裝 [NSIS](https://nsis.sourceforge.io/)）：

```powershell
$env:CI = '1'
.github/scripts/Package-Windows.ps1
```

## 授權條款

[GPL-2.0-or-later](LICENSE)
