<#
.SYNOPSIS 
	Downloads content from Youtube or similar websites using the yt-dlp application.
	
.DESCRIPTION 
	This PowerShell script downloads content from Youtube or similar websites using the yt-dlp application.

.EXAMPLE 
	yt-dlp-video.ps1
	    Runs the script using default parameter values.

    yt-dlp-video.ps1 -YtDlpOptions '--no-playlist'
        Only downloads the single video provided via the URL and not all videos in the playlist.
	
.NOTES 
	Requires Windows 7 or higher and PowerShell 5.0 or greater
	Author: mpb10
	Updated: February 13th 2024
	Version: 1.0.0
#>

param(
    [Parameter(Mandatory = $False, HelpMessage = 'The path to the yt-dlp video list file.')]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\etc\video-url-list.txt',

    [Parameter( Mandatory = $False, HelpMessage = 'The yt-dlp options to supply to the download command.')]
    [string]
    $YtDlpOptions = "--output '$([environment]::GetFolderPath('MyVideos'))/%(uploader)s/%(upload_date)s - %(title)s.%(ext)s' --download-archive '$([environment]::GetFolderPath('UserProfile'))\scripts\powershell-yt-dlp\var\download-archive.txt' --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
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
