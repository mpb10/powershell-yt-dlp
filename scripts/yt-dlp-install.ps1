<#
.SYNOPSIS 
	Installs the 'powershell-yt-dlp' script to the users system.
	
.DESCRIPTION 
	Installs the 'powershell-yt-dlp' script to the users system.
    GitHub project: https://github.com/mpb10/powershell-yt-dlp

.EXAMPLE 
	yt-dlp-install.ps1
	    Runs the script using default parameter values.

    yt-dlp-install.ps1 -Path 'C:\Program Files'
        Installs the script files to an alternate location.
	
.NOTES 
	Requires Windows 7 or higher and PowerShell 5.0 or greater
	Author: mpb10
	Updated: February 13th, 2024
	Version: 1.0.0
#>

param(
    [Parameter(Mandatory = $False, HelpMessage = 'The directory to install the ''powershell-yt-dlp'' script and other files to.')]
    [string]
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp',

    [Parameter(Mandatory = $False, HelpMessage = 'The branch of the ''powershell-yt-dlp'' GitHub repository to download from.')]
    [string]
    $Branch = 'main'
)

# Save whether the 'yt-dlp' PowerShell module was already imported or not.
$ModuleState = Get-Command -Module 'yt-dlp'

# Find the 'yt-dlp.psm1' PowerShell module.
if (Test-Path -Path "$PSScriptRoot\yt-dlp.psm1") {
	$ModulePath = "$PSScriptRoot\yt-dlp.psm1"
} elseif (Test-Path -Path "$(Get-Location)\yt-dlp.psm1") {
	$ModulePath = "$(Get-Location)\yt-dlp.psm1"
} elseif (Test-Path -Path "$Path\bin\yt-dlp.psm1") {
	$ModulePath = "$Path\bin\yt-dlp.psm1"
} else {
	Write-Host "ERROR:  Could not find the 'yt-dlp.psm1' module file path."
}

# Import the 'yt-dlp' PowerShell module.
try { 
    Import-Module -Force $ModulePath
} catch {
    return Write-Host "ERROR:  Failed to import the 'yt-dlp.psm1' PowerShell module."
}

# Install/Update the 'powershell-yt-dlp' script.
Uninstall-YtDlpScript -Path $Path
Install-YtDlpScript -Path $Path -Branch $Branch -LocalShortcut -DesktopShortcut -StartMenuShortcut

# If the 'yt-dlp' PowerShell module was not imported before running this script, then remove the module.
if ($null -eq $ModuleState) { 
    Remove-Module 'yt-dlp'
}
