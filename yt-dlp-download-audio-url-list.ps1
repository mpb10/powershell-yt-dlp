<#
.SYNOPSIS 
	Downloads content from Youtube or similar websites using the yt-dlp application.
	
.DESCRIPTION 
	This PowerShell script downloads content from Youtube or similar websites using the yt-dlp application.

.EXAMPLE 
	yt-dlp-download-list.ps1
	    Runs the script using default parameter values.

    yt-dlp-download-list.ps1 -Path 'C:\Users\John\scripts\powershell-yt-dlp\etc\audio-url-list.txt' -YtDlpOptions "--output 'C:/Users/John/Music/yt-dlp/%(uploader)s/%(uploader)s - %(upload_date)s - %(title)s.%(ext)s' --download-archive 'C:\Users\John\scripts\powershell-yt-dlp\var\download-archive.txt' --no-mtime --extract-audio --audio-format mp3 --audio-quality 0"
        Downloads audio for each URL in the audio URL list file.
	
.NOTES 
	Requires Windows 7 or higher and PowerShell 5.0 or greater
	Author: mpb10
	Updated: February 13th, 2024
	Version: 1.0.0
#>

param(
    [Parameter(Mandatory = $False, HelpMessage = 'The path to the yt-dlp video list file.')]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\etc\video-url-list.txt',

    [Parameter( Mandatory = $False, HelpMessage = 'The yt-dlp options to supply to the download command.')]
    [string]
    $YtDlpOptions = "--output '$([environment]::GetFolderPath('MyMusic'))/yt-dlp/%(uploader)s/%(title)s.%(ext)s' --download-archive '$([environment]::GetFolderPath('UserProfile'))\scripts\powershell-yt-dlp\var\download-archive-audio.txt' --no-mtime --extract-audio --audio-format mp3 --audio-quality 0"
)

# Save whether the 'yt-dlp' PowerShell module was already imported or not.
$CheckModuleState = Get-Command -Module 'yt-dlp'

# Find the 'yt-dlp.psm1' PowerShell module.
if (Test-Path -Path "$PSScriptRoot\yt-dlp.psm1") {
	$ModulePath = "$PSScriptRoot\yt-dlp.psm1"
} elseif (Test-Path -Path "$(Get-Location)\yt-dlp.psm1") {
	$ModulePath = "$(Get-Location)\yt-dlp.psm1"
} elseif (Test-Path -Path "$DefaultScriptInstallLocation\bin\yt-dlp.psm1") {
	$ModulePath = "$DefaultScriptInstallLocation\bin\yt-dlp.psm1"
} else {
	Write-Host "ERROR:  Could not find the 'yt-dlp.psm1' module file path."
}

# Import the 'yt-dlp' PowerShell module.
try { 
    Import-Module -Force $ModulePath
} catch {
    return Write-Host "ERROR:  Failed to import the 'yt-dlp.psm1' PowerShell module."
}

# Download the videos from the video list file.
Get-VideoFromList -Path $Path -YtDlpOptions $YtDlpOptions
Write-Log -ConsoleOnly -Severity 'Info' -Message "Script complete."

# If the 'yt-dlp' PowerShell module was not imported before running this script, then remove the module.
if ($null -eq $CheckModuleState) { 
    Remove-Module 'yt-dlp'
}
