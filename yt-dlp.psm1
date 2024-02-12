<#
.SYNOPSIS 
	A collection of commandlets used to support the PowerShell-Yt-Dlp script.
	
.DESCRIPTION 
	This PowerShell module is used to support the PowerShell-Yt-Dlp.

.EXAMPLE 
	Import-Module -Force ".\yt-dlp.psm1"
	    Imports the module and allows all of the commandlets to be called elsewhere.
	
.NOTES 
	Requires Windows 7 or higher and PowerShell 5.0 or greater
	Author: mpb10
	Updated: February 12th, 2024
	Version: 0.1.0

.LINK 
	https://github.com/mpb10/powershell-yt-dlp
#>



# Function for simulating the 'pause' command of the Windows command line.
function Wait-Script {
    param(
        [Parameter(Mandatory = $false, HelpMessage = 'If true, do not wait for user input.')]
        [switch]
        $NonInteractive = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = 'Number of seconds to wait.')]
        [int]
        $Seconds = 0
    )

    # Wait for a specified number of seconds.
    Start-Sleep -Seconds $Seconds

    # If the '-NonInteractive' parameter is false, wait for the user to press a key before continuing.
    if ($NonInteractive -eq $false) {
		Write-Host "Press any key to continue ...`n" -ForegroundColor "Gray"
	    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") | Out-Null
	}
} # End Wait-Script function



# Function for writing messages to a log file.
function Write-Log {
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The message to output to the log.')]
        [string]
        $Message,

        [Parameter(Mandatory = $true, HelpMessage = 'The severity level of the message to log.')]
        [ValidateSet('Info','Warning','Error','Prompt')]
        [string]
        $Severity,

        [Parameter(Mandatory = $false, HelpMessage = 'Location of the log file.')]
        [string]
        $FilePath = "$(Get-Location)\powershell-yt-dlp.log",

        [Parameter(Mandatory = $false, HelpMessage = 'Whether to output to the console in addition to the log file.')]
        [switch]
        $Console = $false,

        [Parameter(Mandatory = $false, HelpMessage = 'Whether to output only to the console.')]
        [switch]
        $ConsoleOnly = $false
    )

    # Set the severity level formatting based on the user input.
    $SeverityLevel = switch ($Severity) {
        'Info'    { 'INFO:   '; break }
        'Warning' { 'WARNING:'; break }
        'Error'   { 'ERROR:  '; break }
        'Prompt'  { 'PROMPT: '; break }
        default   { 'INFO:   '; break }
    }

    # Return the user provided value if the $Severity is 'Prompt'
    if ($Severity -eq 'Prompt') {
        return (Read-Host "$(Get-Date -Format 's') $SeverityLevel $Message").Trim()
    }

    # If the '-ConsoleOnly' parameter is true, only write the output to the console.
    # If the '-Console' parameter is true, tee the output to both the console and log file.
    # Otherwise, only save the output to the log file.
    if ($ConsoleOnly) {
        Write-Host "$(Get-Date -Format 's') $SeverityLevel $Message"
    }
    elseif ($Console) {
        Tee-Object -Append -FilePath $FilePath -InputObject "$(Get-Date -Format 's') $SeverityLevel $Message"
    }
    else {
        Out-File -Append -FilePath $FilePath -InputObject "$(Get-Date -Format 's') $SeverityLevel $Message"
    }
} # End Write-Log function



# Function for creating shortcuts.
function New-Shortcut {
    param (
        [Parameter(Mandatory = $false, HelpMessage = 'The full path of the shortcut to create.')]
        [string]
        $Path = "$(Get-Location)\newshortcut.lnk",

        [Parameter(Mandatory = $true, HelpMessage = 'The target path of the shortcut.')]
        [string]
        $TargetPath,

        [Parameter(Mandatory = $false, HelpMessage = 'Arguments to pass to the target path when the shortcut is ran.')]
        [string]
        $Arguments,

        [Parameter(Mandatory = $false, HelpMessage = 'The directory from which to run the target path.')]
        [string]
        $StartPath,
        
        [Parameter(Mandatory = $false, HelpMessage = 'Path to the file used as the icon.')]
        [string]
        $IconPath
    )

    $FullTargetPath = Resolve-Path -Path $TargetPath

    # Create the WScript.Shell object, assign it a file path, target path, and other optional settings.
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($Path)
    $Shortcut.TargetPath = $FullTargetPath.Path
    if ($Arguments) {
        $Shortcut.Arguments = $Arguments
    }
    if ($StartPath) {
        $Shortcut.WorkingDirectory = $StartPath
    }
    if ($IconPath) {
        $Shortcut.IconLocation = $IconPath
    }
    $Shortcut.Save()

    if (Test-Path -Path $Path) {
        Write-Log -ConsoleOnly -Severity 'Info' -Message "Created shortcut at '$Path'."
    }
    else {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to create a shortcut at '$Path'."
    }

} # End New-Shortcut function



# Function for downloading files from the internet.
function Get-Download {
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Web URL of the file to download.')]
        [string]
        $Url,

        [Parameter(Mandatory = $false, HelpMessage = 'The path to download the file to.')]
        [string]
        $Path = "$(Get-Location)\downloadfile"
    )

    # Check if the provided '-Path' parameter is a valid file path.
    if (Test-Path -Path $Path -PathType 'Container') {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message "Provided download path cannot be a directory."
    }
    else {
        $TempFile = "$(Split-Path -Path $Path -Parent)\download.tmp"
    }

    # Download the file to a temporary file.
    (New-Object System.Net.WebClient).DownloadFile("$Url", $TempFile)

    # Rename and move the downloaded temporary file to its permanent location.
    if (Test-Path -Path $TempFile) {
        Move-Item -Path $TempFile -Destination $Path -Force
        Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded file to '$Path'."
    }
    else {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to download file to '$Path'."
    }

    # Remove the temporary file if it still exists.
    if (Test-Path -Path $TempFile) {
        Remove-Item -Path $TempFile
    }
} # End Get-Download function



# Function for downloading the yt-dlp.exe executable file.
function Get-YtDlp {
    param(
        [Parameter(Mandatory = $true, HelpMessage = 'Download yt-dlp.exe to this directory.')]
        [string]
        $Path
    )

    # Check if the provided '-Path' parameter is a valid directory.
    if (Test-Path -Path $Path -PathType 'Container') {
        $Path = Resolve-Path -Path $Path
    }
    else {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message 'Provided download path either does not exist or is not a directory.'
    }

    # Use the 'Get-Download' function to download the yt-dlp.exe executable file.
    Get-Download -Url 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' -Path "$Path\yt-dlp.exe"

    # Check if the download was successful.
    if (Test-Path -Path "$Path\yt-dlp.exe") {
        Write-Log -ConsoleOnly -Severity 'Info' -Message "Finished downloading the yt-dlp executable to '$Path\yt-dlp.exe'."
    }
    else {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to download the yt-dlp executable to '$Path\yt-dlp.exe'."
    }
} # End Get-YtDlp function



# Function for downloading the ffmpeg executable files.
function Get-Ffmpeg {
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'Download ffmpeg executables to this directory.')]
        [string]
        $Path
    )

    # Check if the provided '-Path' parameter is a valid directory.
    if (Test-Path -Path $Path -PathType 'Container') {
        $Path = Resolve-Path -Path $Path
        $TempFile = "$Path\ffmpeg-download.zip"
    }
    else {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message 'Provided download path either does not exist or is not a directory.'
    }
    
    # Download the ffmpeg zip file.
    Get-Download -Url 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip' -Path $TempFile
    if (-Not (Test-Path -Path $TempFile)) {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to download the ffmpeg release file to '$Path'."
    }

    # Extract the ffmpeg executable files from the downloaded zip file.
    Expand-Archive -Path $TempFile -DestinationPath $Path
    Copy-Item -Path "$Path\ffmpeg-*\bin\*" -Destination $Path -Filter "*.exe" -Force
    Remove-Item -Path $TempFile, "$Path\ffmpeg-*" -Recurse

    # Ensure that the three ffmpeg executables exist.
    if ((Test-Path -Path "$Path\ffmpeg.exe") -and (Test-Path -Path "$Path\ffplay.exe") -and (Test-Path -Path "$Path\ffprobe.exe")) {
        Write-Log -ConsoleOnly -Severity 'Info' -Message "Finished downloading the ffmpeg executables to '$Path'."
    }
    else {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to download and extract the ffmpeg executables to '$Path'."
    }
} # End Get-Ffmpeg function



# Function for downloading and installing powershell-yt-dlp script files and executables.
function Install-YtDlpScript {
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The directory to install the ''powershell-yt-dlp'' script and other files to.')]
        [string]
        $Path,

        [Parameter(Mandatory = $false, HelpMessage = 'The branch of the ''powershell-yt-dlp'' GitHub repository to download from.')]
        [string]
        $Branch = 'master',

        [Parameter(Mandatory = $false, HelpMessage = 'Whether to create a local shortcut that is used to run the ''yt-dlp-gui.ps1'' script.')]
        [switch]
        $LocalShortcut = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = 'Whether to create a desktop shortcut that is used to run the ''yt-dlp-gui.ps1'' script.')]
        [switch]
        $DesktopShortcut = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = 'Whether to create a start menu shortcut that is used to run the ''yt-dlp-gui.ps1'' script.')]
        [switch]
        $StartMenuShortcut = $false
    )

	# Ensure that the install directory is present.
	if ((Test-Path -Path $Path -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path $Path | Out-Null
	}

	# Ensure that the 'bin' directory is present.
	if ((Test-Path -Path "$Path\bin" -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path "$Path\bin" | Out-Null
	}

	# Ensure that the 'var' directory is present.
	if ((Test-Path -Path "$Path\var" -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path "$Path\var" | Out-Null
	}

	# Ensure that the 'etc' directory is present.
	if ((Test-Path -Path "$Path\etc" -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path "$Path\etc" | Out-Null
	}

	# Ensure that 'yt-dlp' is installed.
	if ((Test-Path "$Path\bin\yt-dlp.exe") -eq $False) {
		Write-Log -ConsoleOnly -Severity 'Warning' -Message "The yt-dlp executable was not found at '$Path\bin\yt-dlp.exe'."

		Get-YtDlp -Path "$Path\bin"
	}

	# Ensure that 'ffmpeg' is installed.
	if ((Test-Path -Path "$Path\bin\ffmpeg.exe") -eq $false -or (Test-Path -Path "$Path\bin\ffplay.exe") -eq $false -or (Test-Path -Path "$Path\bin\ffprobe.exe") -eq $false) {
		Write-Log -ConsoleOnly -Severity 'Warning' -Message "One or more of the ffmpeg executables were not found in '$Path\bin\'."

		Get-Ffmpeg -Path "$Path\bin"
	}

	# Ensure that the script files are installed.
	if ((Test-Path -Path "$Path\bin\yt-dlp.psm1") -eq $false -or (Test-Path -Path "$Path\bin\yt-dlp-gui.ps1") -eq $false -or (Test-Path -Path "$Path\README.md") -eq $false -or (Test-Path -Path "$Path\LICENSE") -eq $false) {
		Write-Log -ConsoleOnly -Severity 'Warning' -Message "One or more of the PowerShell script files were not found in '$Path'."

		Get-Download -Url "https://github.com/mpb10/powershell-yt-dlp/raw/$Branch/yt-dlp.psm1" -Path "$Path\bin\yt-dlp.psm1"
		Get-Download -Url "https://github.com/mpb10/powershell-yt-dlp/raw/$Branch/yt-dlp-gui.ps1" -Path "$Path\bin\yt-dlp-gui.ps1"
		Get-Download -Url "https://github.com/mpb10/powershell-yt-dlp/raw/$Branch/README.md" -Path "$Path\README.md"
		Get-Download -Url "https://github.com/mpb10/powershell-yt-dlp/raw/$Branch/LICENSE" -Path "$Path\LICENSE"        
	}

	# Ensure that the 'bin' directory containing the executable files is in the system PATH variable.
	if ($ENV:PATH.Split(';') -notcontains "$Path\bin") {
		Write-Log -ConsoleOnly -Severity 'Warning' -Message "The '$Path\bin' directory was not found in the system PATH variable."

		# Add the bin directory to the system PATH variable.
		if ($ENV:PATH.LastIndexOf(';') -eq ($ENV:PATH.Length - 1)) {
			$ENV:PATH += "$Path\bin"
		}
		else {
			$ENV:PATH += ";$Path\bin"
		}

		# Check that the bin directory was actually added to the system PATH variable.
		if ($ENV:PATH.Split(';') -contains "$Path\bin") {
			Write-Log -ConsoleOnly -Severity 'Info' -Message "Added the '$Path\bin' directory to the system PATH variable."
		} else {
			return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to add the '$Path\bin' directory to the system PATH variable."
		}
	}
	
	# If the '-LocalShortcut' parameter is provided, create a shortcut in the same directory as the 'yt-dlp-gui.ps1' script that is used to run it.
    if ($LocalShortcut) {
        if ((Test-Path -Path "$Path\powershell-yt-dlp.lnk") -eq $false) {
            # Create the shortcut.
            New-Shortcut -Path "$Path\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp-gui.ps1""" -StartPath "$Path\bin"
            
            # Ensure that the shortcut was created.
            if (Test-Path -Path "$Path\powershell-yt-dlp.lnk") {
                Write-Log -ConsoleOnly -Severity 'Info' -Message "Created a shortcut for running 'yt-dlp-gui.ps1' at: '$Path\powershell-yt-dlp.lnk'"
            }
            else {
                return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to create a shortcut at: '$Path\powershell-yt-dlp.lnk'"
            }
        } else {
            # Recreate the shortcut so that its values are up-to-date.
            New-Shortcut -Path "$Path\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp-gui.ps1""" -StartPath "$Path\bin"
        }
    }

    # If the '-DesktopShortcut' parameter is provided, create a shortcut on the desktop that is used to run the 'yt-dlp-gui.ps1' script.
    if ($DesktopShortcut) {
        $DesktopPath = [environment]::GetFolderPath('Desktop')

        if ((Test-Path -Path "$DesktopPath\powershell-yt-dlp.lnk") -eq $false) {
            # Create the shortcut.
            New-Shortcut -Path "$DesktopPath\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp-gui.ps1""" -StartPath "$Path\bin"
            
            # Ensure that the shortcut was created.
            if (Test-Path -Path "$DesktopPath\powershell-yt-dlp.lnk") {
                Write-Log -ConsoleOnly -Severity 'Info' -Message "Created a shortcut for running 'yt-dlp-gui.ps1' at: '$DesktopPath\powershell-yt-dlp.lnk'"
            }
            else {
                return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to create a shortcut at: '$DesktopPath\powershell-yt-dlp.lnk'"
            }
        } else {
            # Recreate the shortcut so that its values are up-to-date.
            New-Shortcut -Path "$DesktopPath\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp-gui.ps1""" -StartPath "$Path\bin"
        }
    }

    # If the '-StartMenuShortcut' parameter is provided, create a start menu directory containing a shortcut used to run the 'yt-dlp-gui.ps1' script.
    if ($StartMenuShortcut) {
        $AppDataPath = [Environment]::GetFolderPath('ApplicationData')

        if ((Test-Path -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk") -eq $false) {

            # Ensure the start menu directory exists.
            if ((Test-Path -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp" -PathType 'Container') -eq $false) {
                New-Item -Type 'Directory' -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp" | Out-Null
            }

            # Create the shortcut.
            New-Shortcut -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp-gui.ps1""" -StartPath "$Path\bin"
            
            # Ensure that the shortcut was created.
            if (Test-Path -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk") {
                Write-Log -ConsoleOnly -Severity 'Info' -Message "Created a start menu directory and shortcut for running 'yt-dlp-gui.ps1' at: '$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk'"
            }
            else {
                return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to create a shortcut at: '$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk'"
            }
        } else {
            # Recreate the shortcut so that its values are up-to-date.
            New-Shortcut -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp-gui.ps1""" -StartPath "$Path\bin"
        }
    }

    Write-Log -ConsoleOnly -Severity 'Info' -Message "Finished installing 'powershell-yt-dlp' to '$Path'."
} # End Install-YtDlpScript function



# Function for uninstalling the powershell-yt-dlp script files and directories.
function Uninstall-YtDlpScript {
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The directory where the ''powershell-yt-dlp'' script and executables are currently installed to.')]
        [string]
        $Path,

        [Parameter(Mandatory = $false, HelpMessage = 'Whether to remove all files that reside in the ''powershell-yt-dlp'' install directory.')]
        [switch]
        $Force = $false
    )
    $DesktopPath = [environment]::GetFolderPath('Desktop')
    $AppDataPath = [Environment]::GetFolderPath('ApplicationData')

    # Remove the script files, executables, and shortcuts
    $FileList = @(
        "$Path\bin\yt-dlp.exe",
        "$Path\bin\ffmpeg.exe",
        "$Path\bin\ffplay.exe",
        "$Path\bin\ffprobe.exe",
        "$Path\bin\yt-dlp.psm1",
        "$Path\bin\yt-dlp-gui.ps1",
        "$Path\README.md",
        "$Path\LICENSE",
        "$Path\powershell-yt-dlp.lnk",
        "$DesktopPath\powershell-yt-dlp.lnk",
        "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk"
    )
    foreach ($Item in $FileList) {
        try { 
            Remove-Item -Path $Item -ErrorAction Stop
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Log -ConsoleOnly -Severity 'Warning' -Message "$_"
        } catch {
            return Write-Log -ConsoleOnly -Severity 'Error' -Message "$_"
        }
    }

    # Remove the directories that were created by the script only if they are empty.
    $FileListDirectories = @(
        "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp",
        "$Path\bin",
        "$Path\etc",
        "$Path\var",
        "$Path"
    )
    foreach ($Item in $FileListDirectories) {
        if ((Get-ChildItem -Path $Item -Recurse | Measure-Object).Count -eq 0 -or $Force) {
            try { 
                Remove-Item -Path $Item -Recurse -Force -ErrorAction Stop
            } catch [System.Management.Automation.ItemNotFoundException] {
                Write-Log -ConsoleOnly -Severity 'Warning' -Message "$_"
            } catch {
                return Write-Log -ConsoleOnly -Severity 'Error' -Message "$_"
            }
        }
    }

    Write-Log -ConsoleOnly -Severity 'Info' -Message 'Finished uninstalling ''powershell-yt-dlp''.'
} # End Uninstall-YtDlpScript function



function Get-Video {
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The URL of the video to download.')]
        [string]
        $Url,

        [Parameter(Mandatory = $false, HelpMessage = 'Additional yt-dlp options to pass to the download command.')]
        [string]
        $YtDlpOptions = "--output './%(uploader)s/%(upload_date)s - %(title)s.%(ext)s' --download-archive '.\var\download-archive.txt' --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters",

        [Parameter(Mandatory = $false, HelpMessage = 'The path to the directory containing the yt-dlp and ffmpeg executable files.')]
        [string]
        $ExecutablePath = ''
    )

    $Url = $Url.Trim()
    $YtDlpOptions = $YtDlpOptions.Trim()
    $ExecutablePath = $ExecutablePath.Trim()
    
    if ($ExecutablePath.Length -gt 0) {
        # Check if the provided '-ExecutablePath' parameter is a valid directory.
        if (Test-Path -Path $ExecutablePath -PathType 'Container') {
            $ExecutablePath = "$(Resolve-Path -Path $ExecutablePath)\yt-dlp.exe"
        }
        else {
            return Write-Log -ConsoleOnly -Severity 'Error' -Message 'Provided executable directory path either does not exist or is not a directory.'
        }

        if (Test-Path -Path "$ExecutablePath\yt-dlp.exe") {
            $ExecutablePath = Resolve-Path -Path "$ExecutablePath\yt-dlp.exe"
        }
    } else {
        $ExecutablePath = "yt-dlp"

        # Check whether the 'yt-dlp' command is in the system's PATH variable
        if ($null -eq (Get-Command "yt-dlp" -ErrorAction SilentlyContinue)) 
        { 
            return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to find 'yt-dlp' in the system PATH variable."
        }
    }

    # Check whether the 'ffmpeg' command is in the system's PATH variable
    if ($null -eq (Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) 
    { 
        return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to find 'ffmpeg' in the system PATH variable."
    }

    # Download the video.
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading video from URL '$Url' using yt-dlp options of '$YtDlpOptions'."
    Invoke-Expression "$ExecutablePath $YtDlpOptions '$Url'"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Finished downloading video from URL '$Url'."
} # End Get-Video function



# Function for retrieving an array of Yt playlist URLs.
function Get-VideoList {
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Path to the file containing a list of video URLs to download.')]
        [string]
        $Path,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Array object containing a list of playlist URLs to download.')]
        [array]
        $UrlList = @()
    )
    
    # If the '-UrlList' parameter was provided, check if it's a valid array.
    if ($UrlList.Length -gt 0 -and $UrlList -isnot [array]) {
        return Write-Log -ConsoleOnly -Severity 'Error' -Message 'Provided ''-UrlList'' parameter value is not an array or is empty.'
        return @()
    } 
    
    # If the '-Path' parameter was provided, check if it's a valid file and add its contents to the '$UrlList' variable.
    if ($Path.Length -gt 0) {
        $Path = Resolve-Path -Path $Path

        if ((Test-Path -Path $Path -PathType 'Leaf') -eq $false) {
            return Write-Log -ConsoleOnly -Severity 'Error' -Message 'Provided path either does not exist or is not a file.'
            return @()
        }
        else {
            $UrlList += (Get-Content -Path $Path | Where-Object { $_.Trim() -ne '' -and $_.Trim() -notmatch '^#.*' })
        }
    }

    # Return an array of playlist URL string objects.
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Returning $($UrlList.Length) playlist URLs."
    return $UrlList
} # End Get-VideoList function



Function Get-MainMenu {

}



Function Get-DownloadMenu {

}



Function Get-SettingsMenu {

}



# ################################
# Testing functions
# ################################



Function Test-GetYtDlpExecutables {
    $ErrorActionPreference = "Stop"
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\tests'
    if ((Test-Path -Path $Path -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path $Path | Out-Null
	}
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading yt-dlp to '$Path\yt-dlp.exe'."
    Get-YtDlp -Path $Path
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading ffmpeg to '$Path'."
    Get-Ffmpeg -Path $Path
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing downloaded executables."
    Remove-Item -Path "$Path\yt-dlp.exe" -ErrorAction Stop
    Remove-Item -Path "$Path\ffmpeg.exe" -ErrorAction Stop
    Remove-Item -Path "$Path\ffplay.exe" -ErrorAction Stop
    Remove-Item -Path "$Path\ffprobe.exe" -ErrorAction Stop
    Remove-Item -Path $Path -ErrorAction Stop
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpInstall {
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The branch of the ''powershell-yt-dlp'' GitHub repository to download from.')]
        [string]
        $Branch
    )
    $ErrorActionPreference = "Stop"
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\tests'
    if ((Test-Path -Path $Path -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path $Path | Out-Null
	}
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Installing 'powershell-yt-dlp' from branch '$Branch' to '$Path'."
    Install-YtDlpScript -Path $Path -Branch $Branch -LocalShortcut -DesktopShortcut -StartMenuShortcut
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpUninstall {
    $ErrorActionPreference = "Stop"
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\tests'
    if ((Test-Path -Path $Path -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path $Path | Out-Null
	}
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Uninstalling 'powershell-yt-dlp' from '$Path'."
    Uninstall-YtDlpScript -Path $Path
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpUninstallForce {
    $ErrorActionPreference = "Stop"
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\tests'
    if ((Test-Path -Path $Path -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path $Path | Out-Null
	}
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Uninstalling 'powershell-yt-dlp' from '$Path' with the '-Force' option."
    Uninstall-YtDlpScript -Path $Path -Force
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpVideo {
    $ErrorActionPreference = "Stop"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading video."
    Get-Video -Url 'https://www.youtube.com/watch?v=C0DPdy98e4c' -YtDlpOptions "--output 'test-video.%(ext)s' --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path "test-video.*").Name), Length: $((Get-ChildItem -Path "test-video.*").Length), LastWriteTime: $((Get-ChildItem -Path "test-video.*").LastWriteTime)"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing '$((Get-ChildItem -Path "test-video.*").Name)'."
    Get-ChildItem -Path "test-video.*" | Remove-Item
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpAudio {
    $ErrorActionPreference = "Stop"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading audio."
    Get-Video -Url 'https://www.youtube.com/watch?v=C0DPdy98e4c' -YtDlpOptions "--output 'test-audio.%(ext)s' --no-mtime --extract-audio --audio-format mp3 --audio-quality 0"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path "test-audio.*").Name), Length: $((Get-ChildItem -Path "test-audio.*").Length), LastWriteTime: $((Get-ChildItem -Path "test-audio.*").LastWriteTime)"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing '$((Get-ChildItem -Path "test-audio.*").Name)'."
    Get-ChildItem -Path "test-audio.*" | Remove-Item
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpVideoArchive {
    $ErrorActionPreference = "Stop"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading video with '--download-archive' option enabled."
    Get-Video -Url 'https://www.youtube.com/watch?v=C0DPdy98e4c' -YtDlpOptions "--output 'test-video.%(ext)s' --download-archive test-yt-dlp-archive.txt --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path "test-video.*").Name), Length: $((Get-ChildItem -Path "test-video.*").Length), LastWriteTime: $((Get-ChildItem -Path "test-video.*").LastWriteTime)"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path 'test-yt-dlp-archive.txt').Name), Length: $((Get-ChildItem -Path 'test-yt-dlp-archive.txt').Length), LastWriteTime: $((Get-ChildItem -Path 'test-yt-dlp-archive.txt').LastWriteTime)"    
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Contents of 'test-yt-dlp-archive.txt': $(Get-Content 'test-yt-dlp-archive.txt')"    
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing '$((Get-ChildItem -Path "test-video.*").Name)'."
    Get-ChildItem -Path "test-video.*" | Remove-Item
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading video with '--download-archive' option enabled a second time."
    Get-Video -Url 'https://www.youtube.com/watch?v=C0DPdy98e4c' -YtDlpOptions "--output 'test-video.%(ext)s' --download-archive test-yt-dlp-archive.txt --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
    if (Test-Path -Path "test-video.*") {
		return Write-Log -ConsoleOnly -Severity 'Error' -Message "The video '$((Get-ChildItem -Path "test-video.*").Name)' was re-downloaded despite having the '--download-archive' option set."
	}
    else {
        Write-Log -ConsoleOnly -Severity 'Info' -Message "The video was not re-downloaded due to the '--download-archive' option being set."
    }
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing 'test-yt-dlp-archive.txt'."
    Remove-Item -Path 'test-yt-dlp-archive.txt'
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpVideoList {
    $ErrorActionPreference = "Stop"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Creating video list file 'test-yt-dlp-video-list.txt'."
    "https://www.youtube.com/watch?v=C0DPdy98e4c
https://www.youtube.com/watch?v=QC8iQqtG0hg" | Out-File -FilePath 'test-yt-dlp-video-list.txt'
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading videos from video list file 'test-yt-dlp-video-list.txt'."
    $UrlList = Get-VideoList -Path 'test-yt-dlp-video-list.txt' 
    $Counter = 1
    foreach ($Item in $UrlList) {
        Get-Video -Url "$Item" -YtDlpOptions "--output 'test-video-$Counter.%(ext)s' --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
        $Counter++
    }
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded the following videos:"
    foreach ($Item in (Get-ChildItem -Path "test-video-*")) {
        Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path $Item).Name), Length: $((Get-ChildItem -Path $Item).Length), LastWriteTime: $((Get-ChildItem -Path $Item).LastWriteTime)"
    }
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing the downloaded videos."
    Get-ChildItem -Path "test-video-*" | Remove-Item
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing the video list file 'test-yt-dlp-video-list.txt'."
    Remove-Item -Path 'test-yt-dlp-video-list.txt'
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}
