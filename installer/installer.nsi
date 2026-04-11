; Twitch OBS Title Updater - NSIS Installer Script
;
; Build manually:
;   makensis /DPRODUCT_VERSION=1.0.0 /DBUILD_DIR="..\release\RelWithDebInfo" /DOUTPUT_DIR="..\release" installer.nsi
;
; Built automatically by Package-Windows.ps1 during CI packaging.

!ifndef PRODUCT_VERSION
  !define PRODUCT_VERSION "0.0.0"
!endif

!ifndef BUILD_DIR
  !define BUILD_DIR "..\release\RelWithDebInfo"
!endif

!ifndef OUTPUT_DIR
  !define OUTPUT_DIR "..\release"
!endif

Unicode True

!define PRODUCT_NAME    "RETwitch Title Updater"
!define PLUGIN_NAME     "RETwitchTitleUpdater"
!define OBS_REG_KEY     "SOFTWARE\OBS Studio"
!define UNINST_REG_KEY  "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PLUGIN_NAME}"

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

; --------------------------------------------------------------------------
; Installer metadata
; --------------------------------------------------------------------------
Name    "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "${OUTPUT_DIR}\${PLUGIN_NAME}-${PRODUCT_VERSION}-windows-x64-installer.exe"

ShowInstDetails   show
ShowUninstDetails show
RequestExecutionLevel admin

; Default install dir – overridden in .onInit if OBS registry key is found
InstallDir "$PROGRAMFILES64\obs-studio"

; --------------------------------------------------------------------------
; MUI pages
; --------------------------------------------------------------------------
!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; --------------------------------------------------------------------------
; Detect OBS install directory from registry (64-bit hive)
; --------------------------------------------------------------------------
Function .onInit
  ${If} ${RunningX64}
    SetRegView 64
  ${EndIf}

  ReadRegStr $0 HKLM "${OBS_REG_KEY}" ""
  ${If} $0 != ""
    StrCpy $INSTDIR "$0"
  ${EndIf}
FunctionEnd

; --------------------------------------------------------------------------
; Main install section
; --------------------------------------------------------------------------
Section "!${PRODUCT_NAME} Plugin" SecPlugin
  SectionIn RO

  ; --- Plugin DLL ----------------------------------------------------------
  SetOutPath "$INSTDIR\obs-plugins\64bit"
  File "${BUILD_DIR}\${PLUGIN_NAME}\bin\64bit\${PLUGIN_NAME}.dll"

  ; --- Qt TLS backend (Schannel) – present only when Qt HTTPS is enabled --
  IfFileExists "${BUILD_DIR}\${PLUGIN_NAME}\bin\64bit\tls\qschannelbackend.dll" 0 +3
    SetOutPath "$INSTDIR\obs-plugins\64bit\tls"
    File /nonfatal "${BUILD_DIR}\${PLUGIN_NAME}\bin\64bit\tls\qschannelbackend.dll"

  ; --- Locale data ---------------------------------------------------------
  SetOutPath "$INSTDIR\data\obs-plugins\${PLUGIN_NAME}\locale"
  File "${BUILD_DIR}\${PLUGIN_NAME}\data\locale\en-US.ini"

  ; --- Uninstaller ---------------------------------------------------------
  SetOutPath "$INSTDIR\data\obs-plugins\${PLUGIN_NAME}"
  WriteUninstaller "$INSTDIR\data\obs-plugins\${PLUGIN_NAME}\uninstall.exe"

  ; --- Add/Remove Programs entry (64-bit hive) ----------------------------
  ${If} ${RunningX64}
    SetRegView 64
  ${EndIf}

  WriteRegStr   HKLM "${UNINST_REG_KEY}" "DisplayName"          "${PRODUCT_NAME}"
  WriteRegStr   HKLM "${UNINST_REG_KEY}" "UninstallString"      '"$INSTDIR\data\obs-plugins\${PLUGIN_NAME}\uninstall.exe"'
  WriteRegStr   HKLM "${UNINST_REG_KEY}" "QuietUninstallString" '"$INSTDIR\data\obs-plugins\${PLUGIN_NAME}\uninstall.exe" /S'
  WriteRegStr   HKLM "${UNINST_REG_KEY}" "InstallLocation"      "$INSTDIR"
  WriteRegStr   HKLM "${UNINST_REG_KEY}" "DisplayVersion"       "${PRODUCT_VERSION}"
  WriteRegStr   HKLM "${UNINST_REG_KEY}" "Publisher"            "LiuLian"
  WriteRegStr   HKLM "${UNINST_REG_KEY}" "URLInfoAbout"         "https://github.com/QEXLAUWASD/RETwitch-StreamManger"
  WriteRegDWORD HKLM "${UNINST_REG_KEY}" "NoModify"             1
  WriteRegDWORD HKLM "${UNINST_REG_KEY}" "NoRepair"             1
SectionEnd

; --------------------------------------------------------------------------
; Uninstall section
; --------------------------------------------------------------------------
Section "Uninstall"
  ${If} ${RunningX64}
    SetRegView 64
  ${EndIf}

  Delete "$INSTDIR\obs-plugins\64bit\${PLUGIN_NAME}.dll"
  Delete "$INSTDIR\obs-plugins\64bit\tls\qschannelbackend.dll"
  Delete "$INSTDIR\data\obs-plugins\${PLUGIN_NAME}\locale\en-US.ini"
  Delete "$INSTDIR\data\obs-plugins\${PLUGIN_NAME}\uninstall.exe"

  ; Remove directories only if empty
  RMDir "$INSTDIR\obs-plugins\64bit\tls"
  RMDir "$INSTDIR\data\obs-plugins\${PLUGIN_NAME}\locale"
  RMDir "$INSTDIR\data\obs-plugins\${PLUGIN_NAME}"

  DeleteRegKey HKLM "${UNINST_REG_KEY}"
SectionEnd
