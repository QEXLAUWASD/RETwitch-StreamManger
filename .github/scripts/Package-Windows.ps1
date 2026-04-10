[CmdletBinding()]
param(
    [ValidateSet('x64')]
    [string] $Target = 'x64',
    [ValidateSet('Debug', 'RelWithDebInfo', 'Release', 'MinSizeRel')]
    [string] $Configuration = 'RelWithDebInfo'
)

$ErrorActionPreference = 'Stop'

if ( $DebugPreference -eq 'Continue' ) {
    $VerbosePreference = 'Continue'
    $InformationPreference = 'Continue'
}

if ( $env:CI -eq $null ) {
    throw "Package-Windows.ps1 requires CI environment"
}

if ( ! ( [System.Environment]::Is64BitOperatingSystem ) ) {
    throw "Packaging script requires a 64-bit system to build and run."
}

if ( $PSVersionTable.PSVersion -lt '7.2.0' ) {
    Write-Warning 'The packaging script requires PowerShell Core 7. Install or upgrade your PowerShell version: https://aka.ms/pscore6'
    exit 2
}

function Package {
    trap {
        Write-Error $_
        exit 2
    }

    $ScriptHome = $PSScriptRoot
    $ProjectRoot = Resolve-Path -Path "$PSScriptRoot/../.."
    $BuildSpecFile = "${ProjectRoot}/buildspec.json"

    $UtilityFunctions = Get-ChildItem -Path $PSScriptRoot/utils.pwsh/*.ps1 -Recurse

    foreach( $Utility in $UtilityFunctions ) {
        Write-Debug "Loading $($Utility.FullName)"
        . $Utility.FullName
    }

    $BuildSpec = Get-Content -Path ${BuildSpecFile} -Raw | ConvertFrom-Json
    $ProductName = $BuildSpec.name
    $ProductVersion = $BuildSpec.version

    $OutputName = "${ProductName}-${ProductVersion}-windows-${Target}"

    $RemoveArgs = @{
        ErrorAction = 'SilentlyContinue'
        Path = @(
            "${ProjectRoot}/release/${ProductName}-*-windows-*.zip"
        )
    }

    Remove-Item @RemoveArgs

    Log-Group "Archiving ${ProductName}..."
    $CompressArgs = @{
        Path = (Get-ChildItem -Path "${ProjectRoot}/release/${Configuration}" -Exclude "${OutputName}*.*")
        CompressionLevel = 'Optimal'
        DestinationPath = "${ProjectRoot}/release/${OutputName}.zip"
        Verbose = ($Env:CI -ne $null)
    }
    Compress-Archive -Force @CompressArgs
    Log-Group

    Log-Group "Copying standalone DLL..."
    $DllSource = "${ProjectRoot}/release/${Configuration}/${ProductName}/bin/64bit/${ProductName}.dll"
    $DllDest = "${ProjectRoot}/release/${OutputName}.dll"
    if (Test-Path $DllSource) {
        Copy-Item -Path $DllSource -Destination $DllDest -Force
        Log-Information "Copied DLL to ${DllDest}"
    } else {
        Log-Warning "DLL not found at ${DllSource}, skipping standalone DLL copy"
    }
    Log-Group

    Log-Group "Building Windows Installer..."
    $NsisScript = "${ProjectRoot}/installer/installer.nsi"

    $MakeNsis = Get-Command makensis -ErrorAction SilentlyContinue
    if (-not $MakeNsis) {
        Log-Information "NSIS not found, installing via Chocolatey..."
        choco install nsis -y --no-progress 2>&1 | Out-Null
        $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + $env:PATH
        $MakeNsis = Get-Command makensis -ErrorAction SilentlyContinue
    }

    if ($MakeNsis) {
        $BuildDir = "${ProjectRoot}/release/${Configuration}"
        $NsisArgs = @(
            "/DPRODUCT_VERSION=${ProductVersion}",
            "/DBUILD_DIR=${BuildDir}",
            "/DOUTPUT_DIR=${ProjectRoot}/release",
            $NsisScript
        )
        Invoke-External makensis @NsisArgs

        $InstallerSource = "${ProjectRoot}/release/${ProductName}-${ProductVersion}-windows-x64-installer.exe"
        if (Test-Path $InstallerSource) {
            Log-Information "Installer created at ${InstallerSource}"
        } else {
            Log-Warning "Expected installer not found at ${InstallerSource}"
        }
    } else {
        Log-Warning "makensis not available – skipping installer creation"
    }
    Log-Group
}

Package
