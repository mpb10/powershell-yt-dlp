<#
.SYNOPSIS 
	Downloads video and audio using the 'youtube-dl' application.
	
.DESCRIPTION 
	This script downloads audio and video from the internet using the programs 'youtube-dl' and 'ffmpeg'. See README.md for more information.

.EXAMPLE 
	C:\Users\%USERNAME%\Scripts\Youtube-dl\youtube-dl-gui.ps1
	    Runs the script and installs the PowerShell-Youtube-dl script.
	
.NOTES 
	Requires Windows 7 or higher and PowerShell 5.0 or greater
	Author: mpb10
	Updated: April 27th 2021
	Version: 3.0.5

.LINK 
	https://github.com/mpb10/PowerShell-Youtube-dl
#>



# ======================================================================================================= #
# ======================================================================================================= #
# SCRIPT SETTINGS
# ======================================================================================================= #

# The default location to download videos to.
$DefaultVideoSaveLocation = [environment]::GetFolderPath('MyVideos')

# The default location to download audio to.
$DefaultAudioSaveLocation = [environment]::GetFolderPath('MyMusic')

# The default location to install the script and its files to.
$DefaultScriptInstallLocation = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-youtube-dl'

# The default location of the file containing a list of playlist URLs or batch URLs to download.
$DefaultPlaylistFileLocation = $DefaultScriptInstallLocation + '\etc\playlist-file.ini'

# The default location of the file in which URL IDs are saved so that they are not accidentally downloaded again.
# NOTE: This file is only used when the '--download-archive' youtube-dl option is specified.
$DefaultDownloadArchiveFileLocation = $DefaultScriptInstallLocation + '\var\download-archive.ini'

# A hash table of youtube-dl option presets for various formats and file types.
# NOTE: Youtube-dl options can be found here: https://github.com/ytdl-org/youtube-dl/blob/master/README.md#readme
$YoutubeDlOptionsList = @{
	DefaultVideo = "--no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
    DefaultVideoOld = "-o ""$DefaultVideoSaveLocation\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --no-playlist -f best"
	DefaultAudio = "-o ""$DefaultAudioSaveLocation\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --no-playlist -x --audio-format mp3 --audio-quality 0 --metadata-from-title ""(?P<artist>.+?) - (?P<title>.+)"" --add-metadata --prefer-ffmpeg"
    DefaultVideoPlaylist = "-o ""$VideoSaveLocation\%(playlist)s\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --yes-playlist"
    DefaultAudioPlaylist = "-o ""$VideoSaveLocation\%(playlist)s\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --yes-playlist -x --audio-format mp3 --audio-quality 0 --metadata-from-title ""(?P<artist>.+?) - (?P<title>.+)"" --add-metadata --prefer-ffmpeg"
    DefaultVideoPlaylistFile = "-o ""$VideoSaveLocation\%(playlist)s\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --download-archive ""$DefaultDownloadArchiveFileLocation"" --console-title --ignore-errors --no-mtime --yes-playlist"
    DefaultAudioPlaylistFile = "-o ""$VideoSaveLocation\%(playlist)s\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --download-archive ""$DefaultDownloadArchiveFileLocation"" --console-title --ignore-errors --no-mtime --yes-playlist -x --audio-format mp3 --audio-quality 0 --metadata-from-title ""(?P<artist>.+?) - (?P<title>.+)"" --add-metadata --prefer-ffmpeg"
    Mp3 = "-o ""$DefaultAudioSaveLocation\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --no-playlist -x --audio-format mp3 --audio-quality 0 --prefer-ffmpeg"
	Mp4 = "-o ""$DefaultVideoSaveLocation\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --no-playlist -f mp4"
    Webm = "-o ""$DefaultVideoSaveLocation\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --no-playlist -f webm"
	WebmNoAudio = "-o ""$DefaultVideoSaveLocation\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --no-playlist --recode-video webm --postprocessor-args ""-an"" -f webm"
	WebmForums = "-o ""$DefaultVideoSaveLocation\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --no-playlist --recode-video webm --postprocessor-args ""-b:v 800k -b:a 128k -s 640x360"" -f best"
	WebmForumsNoAudio = "-o ""$DefaultVideoSaveLocation\%(title)s.%(ext)s"" --cache-dir ""$DefaultScriptInstallLocation\var\cache"" --console-title --ignore-errors --no-mtime --no-playlist --recode-video webm --postprocessor-args ""-b:v 800k -b:a 128k -s 640x360 -an"" -f best"
}

# The version of the PowerShell-Youtube-dl script to download and install.
# NOTE: This value must match the name of a remote branch of the PowerShell-Youtube-dl GitHub repository.
$DefaultRepositoryBranch = 'master'



# ======================================================================================================= #
# ======================================================================================================= #
# SCRIPT FUNCTIONS
# ======================================================================================================= #

# Display the main menu of the script.
Function Get-MainMenu {
	$MenuOption = $null
	While ($MenuOption -notin @(1, 2, 3, 0)) {
		Clear-Host
		Write-Host "================================================================================"
		Write-Host "                             PowerShell-Youtube-dl" -ForegroundColor "Yellow"
		Write-Host "================================================================================"
		Write-Host "`nPlease select an option:" -ForegroundColor "Yellow"
		Write-Host "  1 - Download video"
		Write-Host "  2 - Download audio"
		Write-Host "  3 - Update executables, open documentation, uninstall script, etc."
		Write-Host "`n  0 - Exit`n"
		$MenuOption = Read-Host "Option"
		
		Switch ($MenuOption.Trim()) {
			1 {
				# Call the download menu with the default video settings configured.
				Clear-Host
				Get-DownloadMenu -Type 'video' -Path $DefaultVideoSaveLocation -YoutubeDlOptions $YoutubeDlOptionsList.DefaultVideo
				$MenuOption = $null
			}
			2 {
				# Call the download menu with the default audio settings configured.
				Clear-Host
				Get-DownloadMenu -Type 'audio' -Path $DefaultAudioSaveLocation -YoutubeDlOptions $YoutubeDlOptionsList.DefaultAudio
				$MenuOption = $null
			}
			3 {
				# Call the miscellaneous menu.
				Clear-Host
				Get-MiscMenu
				$MenuOption = $null
			}
			0 {
				# Exit the script.
				Clear-Host
				break
			}
			Default {
				# Ensure that a valid option is provided to the main menu.
				Write-Host "`nPlease enter a valid option.`n" -ForegroundColor "Red"
				Wait-Script
			}
		} # End Switch statement
	} # End While loop
} # End Get-MainMenu function



# Display the menu used to download video or audio.
Function Get-DownloadMenu {
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Whether to download video or audio.')]
		[ValidateSet('video','audio')]
        [string]
        $Type,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The URL of the video to download.')]
        [object]
        $Url = 'none',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'The directory to download the video/audio to.')]
        [string]
        $Path = (Get-Location),

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'youtube-dl options to use when downloading the video/audio.')]
        [string]
        $YoutubeDlOptions = $null
    )
	$MenuOption = $null
	$DownloadFunction = "Get-$Type"

	While ($MenuOption -notin @(1, 2, 3, 4, 5, 6, 0)) {
		Clear-Host
		Write-Host "================================================================================"
		Write-Host "                                 Download $Type" -ForegroundColor "Yellow"
		Write-Host "================================================================================"
		Write-Host "`nURL:                $($Url -join "`n                    ")"
		Write-Host "Output path:        $Path"
		Write-Host "youtube-dl options: $YoutubeDlOptions"
		Write-Host "`nPlease select an option:" -ForegroundColor "Yellow"
		Write-Host "  1 - Download $Type"
		Write-Host "  2 - Configure URL"
		Write-Host "  3 - Configure output path"
		Write-Host "  4 - Configure youtube-dl options"
		Write-Host "  5 - Configure format to download"
		Write-Host "  6 - Get playlist URLs from file"
		Write-Host "`n  0 - Cancel`n"
		$MenuOption = Read-Host 'Option'
		Write-Host ""
		
		Switch ($MenuOption.Trim()) {
			1 {
				# If the URL value is an array of URLs, download each one.
				# If the URL value is not an array, download the single URL.
				if ($Url -is [array]) {
					foreach ($Item in $Url) {
						# Call the appropriate download function for each URL in the array.
						& $DownloadFunction -Url $Item -Path $Path -YoutubeDlOptions $YoutubeDlOptions.Trim()

						# If the URL was successfully downloaded, notified the user.
						# If the URL was not successfully downloaded, break out of the loop immediately.
						if ($LastExitCode -eq 0) {
							Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded $Type successfully.`n"
						} else {
							$MenuOption = $null
							break
						} # End if ($LastExitCode -eq 0) statement
					} # End foreach loop
					Wait-Script
				} else {
					# Call the appropriate download function.
					& $DownloadFunction -Url $Url -Path $Path -YoutubeDlOptions $YoutubeDlOptions.Trim()

					# If the URL was successfully downloaded, notify the user.
					# If the URL was not successfully downloaded, return to the download menu.
					if ($LastExitCode -eq 0) {
						Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded $Type successfully.`n"
						Wait-Script
						break
					} else {
						Wait-Script
						$MenuOption = $null
					} # End if ($LastExitCode -eq 0) statement
				} # End if ($Url -isnot [string] -and $Url -is [array]) statement
			}
			2 {
				# Prompt the user for the URL to download.
				$Url = Read-Host 'URL'
				$MenuOption = $null
			}
			3 {
				# Prompt the user for the path to download the video to.
				$Path = Read-Host 'Output path'
				$MenuOption = $null
			}
			4 {
				# Prompt the user for the youtube-dl options or preset to download the URL with.
				Write-Host "Enter the name of the youtube-dl options preset or the youtube-dl options themselves ([Enter] to display presets).`n"
				$DownloadOptions = Read-Host 'youtube-dl options'

				# If the provided youtube-dl options value was empty, display a list of available presets until a value is provided.
				while ($DownloadOptions.Length -eq 0) {
					$YoutubeDlOptionsList.GetEnumerator() | Sort-Object -Property Name
					Write-Host "`nEnter the name of the youtube-dl options preset or the youtube-dl options themselves ([Enter] to display presets).`n"
					$DownloadOptions = Read-Host 'youtube-dl options'
				}

				# Assign the provided youtube-dl option or preset to the proper variable and return to the download menu.
				if ($YoutubeDlOptionsList.ContainsKey($DownloadOptions)) {
					$YoutubeDlOptions = $YoutubeDlOptionsList[$DownloadOptions]
				} else {
					$YoutubeDlOptions = $DownloadOptions
				}
				$MenuOption = $null
			}
			5 {
				# If the URL is a single item (a string), get the formats available for download.
				if ($Url -is [string] -and $Url -isnot [array] -and $Url.Length -gt 0) {
					# Save the list of available download formats to a variable.
					$TestUrlValidity = youtube-dl.exe -F "$URL"

					# If the 'youtube-dl.exe -F $URL' command failed, display the output that it failed with.
					# If the 'youtube-dl.exe -F $URL' command succeeded, display the formats that are available for download and prompt the user.
					if ($LastExitCode -ne 0) {
						Write-Host "$TestUrlValidity" -ForegroundColor "Red"
						Wait-Script
					} else {
						$AvailableFormats = youtube-dl.exe -F "$URL" | Where-Object { ! $_.StartsWith('[') -and ! $_.StartsWith('format code') -and $_ -match '^[0-9]{3}' } | ForEach-Object {
							[PSCustomObject]@{
								'FormatCode' = $_.Substring(0, 13).Trim() -as [Int]
								'Extension' = $_.Substring(13, 11).Trim()
								'Resolution' = $_.Substring(24, 11).Trim()
								'ResolutionPixels' = $_.Substring(35, 6).Trim()
								'Codec' = $_.Substring(41, $_.Length - 41).Trim() -replace '^.*, ([.\a-zA-Z0-9]+)@.*$', '$1'
								'Description' = $_.Substring(41, $_.Length - 41).Trim()
							} # End [PSCustomObject]
						} # End $AvailableFormats ForEach-Object loop
						$AvailableFormats.GetEnumerator() | Sort-Object -Property FormatCode | Format-Table
						Write-Host "Enter the format code that you wish to download ([Enter] to cancel).`n"
						$FormatOption = Read-Host 'Format code'
		
						# Ensure that the provided format code is valid.
						# Break out of the loop if the user provides an empty string.
						while ($FormatOption.Trim() -notin $AvailableFormats.FormatCode -and $FormatOption.Trim() -ne '') {
							Write-Host "`nPlease enter a valid option from the 'FormatCode' column.`n" -ForegroundColor "Red"
							Wait-Script
							$AvailableFormats.GetEnumerator() | Sort-Object -Property FormatCode | Format-Table
							Write-Host "Enter the format code that you wish to download ([Enter] to cancel).`n"
							$FormatOption = Read-Host 'Format code'	
						}
						
						# If the user provided a valid format code, modify the youtube-dl options with that format code.
						if ($FormatOption.Length -gt 0) {
							if ($YoutubeDlOptions -clike '*-f*') {
								$YoutubeDlOptions = ($YoutubeDlOptions + ' ') -replace '-f ([a-zA-Z0-9]+) ', "-f $FormatOption "
							} else {
								$YoutubeDlOptions = $YoutubeDlOptions + " -f $FormatOption"
							}
						} # End if ($FormatOption.Length -gt 0) statement
					} # End if ($LastExitCode -ne 0) statement
				} else {
					Write-Host "Cannot display the format options for multiple URLs. Please set only one URL first.`n" -ForegroundColor "Red"
					Wait-Script
				} # End if ($Url -is [string] -and $Url -isnot [array] -and $Url.Length -gt 0) statement
				$MenuOption = $null
			}
			6 {
				# Retrieve the playlist URL array from the playlist configuration file.
				$Url = Get-Playlist -Path $DefaultPlaylistFileLocation

				# Modify the youtube-dl options to support playlist downloading.
				$YoutubeDlOptions = $YoutubeDlOptions -replace '--no-playlist', '--yes-playlist'

				# Modify the youtube-dl options so that the path to which the playlist will be downloaded to contains the playlist name.
				if ($YoutubeDlOptions -notlike '*%(playlist)s\*') {
					$YoutubeDlOptions = $YoutubeDlOptions -replace "\%\(title\)s\.%\(ext\)s""", "%(playlist)s\%(title)s.%(ext)s"""
				}

				# Modify the youtube-dl options so that the download archive is enabled.
				if ($YoutubeDlOptions -notlike '*--download-archive*') {
					$YoutubeDlOptions = $YoutubeDlOptions + " --download-archive ""$DefaultDownloadArchiveFileLocation"""
				}
				Write-Host ""
				Wait-Script
				$MenuOption = $null
			}
			0 {
				# Return to the main menu.
				Clear-Host
				break
			}
			Default {
				# Ensure that a valid option is provided to the download menu.
				Write-Host "Please enter a valid option.`n" -ForegroundColor "Red"
				Wait-Script
			}
		} # End Switch statement
	} # End While loop
} # End Get-DownloadMenu function



# Display the miscellaneous menu of the script.
Function Get-MiscMenu {
	$MenuOption = $null
	While ($MenuOption -notin @(1, 2, 3, 4, 5, 6, 7, 0)) {
		Clear-Host
		Write-Host "================================================================================"
		Write-Host "                             Miscellaneous Options" -ForegroundColor "Yellow"
		Write-Host "================================================================================"
		Write-Host "`nPlease select an option:" -ForegroundColor "Yellow"
		Write-Host "  1 - Update the youtube-dl executable"
		Write-Host "  2 - Update the ffmpeg executables"
		Write-Host "  3 - Create a desktop shortcut"
		Write-Host "  4 - Open PowerShell-Youtube-dl documentation"
		Write-Host "  5 - Open youtube-dl documentation"
		Write-Host "  6 - Open ffmpeg documentation"
		Write-Host "  7 - Uninstall PowerShell-Youtube-dl"
		Write-Host "`n  0 - Cancel`n"
		$MenuOption = Read-Host "Option"
		Write-Host ""
		
		Switch ($MenuOption.Trim()) {
			1 {
				# Re-download the youtube-dl.exe executable file.
				Get-YoutubeDlp -Path ($DefaultScriptInstallLocation + '\bin')
				Write-Host ""
				Wait-Script
				$MenuOption = $null
			}
			2 {
				# Re-download the ffmpeg executable files.
				Get-Ffmpeg -Path ($DefaultScriptInstallLocation + '\bin')
				Write-Host ""
				Wait-Script
				$MenuOption = $null
			}
			3 {
				# Get the path to the desktop.
				$DesktopPath = [environment]::GetFolderPath('Desktop')

				# Create the desktop shortcut for the script.
				New-Shortcut -Path "$DesktopPath\PowerShell-Youtube-dl.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$DefaultScriptInstallLocation\bin\youtube-dl-gui.ps1""" -StartPath "$DefaultScriptInstallLocation\bin"

				# Ensure that the desktop shortcut was created.
				if (Test-Path -Path "$DesktopPath\PowerShell-Youtube-dl.lnk") {
					Write-Log -ConsoleOnly -Severity 'Info' -Message "Created a shortcut for running 'youtube-dl-gui.ps1' at: '$DesktopPath\PowerShell-Youtube-dl.lnk'`n"
				}
				else {
					return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to create a shortcut at: '$DesktopPath\PowerShell-Youtube-dl.lnk'`n"
				}
				Wait-Script
				$MenuOption = $null
			}
			4 {
				# Open the link to the PowerShell-Youtube-dl documentation for the provided branch version.
				Start-Process "https://github.com/mpb10/PowerShell-Youtube-dl/blob/$DefaultRepositoryBranch/README.md#readme"
				$MenuOption = $null
			}
			5 {
				# Open the link to the youtube-dl documentation.
				Start-Process "https://github.com/ytdl-org/youtube-dl/blob/master/README.md#readme"
				$MenuOption = $null
			}
			6 {
				# Open the link to the ffmpeg documentation.
				Start-Process "https://www.ffmpeg.org/ffmpeg.html"
				$MenuOption = $null
			}
			7 {
				# Uninstall the script and its shortcuts.
				Uninstall-Script -Path $DefaultScriptInstallLocation
				Write-Host ""
				Wait-Script
				Exit
			}
			0 {
				# Return to the main menu.
				Clear-Host
				break
			}
			Default {
				# Ensure that a valid option is provided to the menu.
				Write-Host "Please enter a valid option.`n" -ForegroundColor "Red"
				Wait-Script
			}
		} # End Switch statement
	} # End While loop
} # End Get-MiscMenu function



# ======================================================================================================= #
# ======================================================================================================= #
# MAIN PROCESS
# ======================================================================================================= #

# Save whether the 'youtube-dl' PowerShell module was already imported or not.
$CheckModuleState = Get-Command -Module 'youtube-dl'

# Import the 'youtube-dl.psm1' PowerShell module.
if (Test-Path -Path "$PSScriptRoot\youtube-dl.psm1") {
	Import-Module -Force "$PSScriptRoot\youtube-dl.psm1"
} elseif (Test-Path -Path "$(Get-Location)\youtube-dl.psm1") {
	Import-Module -Force "$(Get-Location)\youtube-dl.psm1"
} elseif (Test-Path -Path "$DefaultScriptInstallLocation\bin\youtube-dl.psm1") {
	Import-Module -Force "$DefaultScriptInstallLocation\bin\youtube-dl.psm1"
} else {
	return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to find and import the 'youtube-dl.psm1' PowerShell module."
}

# Install the script, executables, and shortcuts.
Install-Script -Path $DefaultScriptInstallLocation -Branch $DefaultRepositoryBranch -LocalShortcut -StartMenuShortcut
Write-Log -ConsoleOnly -Severity 'Info' -Message "Script setup complete.`n"
Wait-Script

# Display the main menu of the script.
Get-MainMenu
Write-Log -ConsoleOnly -Severity 'Info' -Message "Script complete."

# If the 'youtube-dl' PowerShell module was not imported before running this script, then remove the module.
if ($null -eq $CheckModuleState) { Remove-Module 'youtube-dl' }
