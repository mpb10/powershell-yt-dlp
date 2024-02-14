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
        [Parameter(Mandatory = $false, HelpMessage = 'If true, wait for user input.')]
        [switch]
        $Interactive = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = 'Number of seconds to wait.')]
        [int]
        $Seconds = 0
    )

    # Wait for a specified number of seconds.
    Start-Sleep -Seconds $Seconds

    # If the '-NonInteractive' parameter is false, wait for the user to press a key before continuing.
    if ($Interactive -eq $true) {
		$null = Read-Host "Press ENTER to continue..."
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

        [Parameter(Mandatory = $false, HelpMessage = 'Whether to create a local shortcut that is used to run the ''yt-dlp.ps1'' script.')]
        [switch]
        $LocalShortcut = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = 'Whether to create a desktop shortcut that is used to run the ''yt-dlp.ps1'' script.')]
        [switch]
        $DesktopShortcut = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = 'Whether to create a start menu shortcut that is used to run the ''yt-dlp.ps1'' script.')]
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
	if ((Test-Path -Path "$Path\bin\yt-dlp.psm1") -eq $false -or (Test-Path -Path "$Path\bin\yt-dlp.ps1") -eq $false -or (Test-Path -Path "$Path\README.md") -eq $false -or (Test-Path -Path "$Path\LICENSE") -eq $false) {
		Write-Log -ConsoleOnly -Severity 'Warning' -Message "One or more of the PowerShell script files were not found in '$Path'."
		Get-Download -Url "https://github.com/mpb10/powershell-yt-dlp/raw/$Branch/yt-dlp.psm1" -Path "$Path\bin\yt-dlp.psm1"
		Get-Download -Url "https://github.com/mpb10/powershell-yt-dlp/raw/$Branch/yt-dlp.ps1" -Path "$Path\bin\yt-dlp.ps1"
		Get-Download -Url "https://github.com/mpb10/powershell-yt-dlp/raw/$Branch/README.md" -Path "$Path\README.md"
		Get-Download -Url "https://github.com/mpb10/powershell-yt-dlp/raw/$Branch/LICENSE" -Path "$Path\LICENSE"       
	}

    if ((Test-Path -Path "$Path\etc\video-url-list.txt") -eq $false) { "# List video URLs to download, one URL on each line." | Out-File -Path "$Path\etc\video-url-list.txt" }
    if ((Test-Path -Path "$Path\etc\audio-url-list.txt") -eq $false) { "# List video URLs to download, one URL on each line." | Out-File -Path "$Path\etc\audio-url-list.txt" }
    if ((Test-Path -Path "$Path\var\download-archive.txt") -eq $false) { New-Item -Type File -Path "$Path\var\download-archive.txt" }

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
	
	# If the '-LocalShortcut' parameter is provided, create a shortcut in the same directory as the 'yt-dlp.ps1' script that is used to run it.
    if ($LocalShortcut) {
        if ((Test-Path -Path "$Path\powershell-yt-dlp.lnk") -eq $false) {
            # Create the shortcut.
            New-Shortcut -Path "$Path\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp.ps1""" -StartPath "$Path\bin"
            
            # Ensure that the shortcut was created.
            if (Test-Path -Path "$Path\powershell-yt-dlp.lnk") {
                Write-Log -ConsoleOnly -Severity 'Info' -Message "Created a shortcut for running 'yt-dlp.ps1' at: '$Path\powershell-yt-dlp.lnk'"
            }
            else {
                return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to create a shortcut at: '$Path\powershell-yt-dlp.lnk'"
            }
        } else {
            # Recreate the shortcut so that its values are up-to-date.
            New-Shortcut -Path "$Path\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp.ps1""" -StartPath "$Path\bin"
        }
    }

    # If the '-DesktopShortcut' parameter is provided, create a shortcut on the desktop that is used to run the 'yt-dlp.ps1' script.
    if ($DesktopShortcut) {
        $DesktopPath = [environment]::GetFolderPath('Desktop')

        if ((Test-Path -Path "$DesktopPath\powershell-yt-dlp.lnk") -eq $false) {
            # Create the shortcut.
            New-Shortcut -Path "$DesktopPath\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp.ps1""" -StartPath "$Path\bin"
            
            # Ensure that the shortcut was created.
            if (Test-Path -Path "$DesktopPath\powershell-yt-dlp.lnk") {
                Write-Log -ConsoleOnly -Severity 'Info' -Message "Created a shortcut for running 'yt-dlp.ps1' at: '$DesktopPath\powershell-yt-dlp.lnk'"
            }
            else {
                return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to create a shortcut at: '$DesktopPath\powershell-yt-dlp.lnk'"
            }
        } else {
            # Recreate the shortcut so that its values are up-to-date.
            New-Shortcut -Path "$DesktopPath\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp.ps1""" -StartPath "$Path\bin"
        }
    }

    # If the '-StartMenuShortcut' parameter is provided, create a start menu directory containing a shortcut used to run the 'yt-dlp.ps1' script.
    if ($StartMenuShortcut) {
        $AppDataPath = [Environment]::GetFolderPath('ApplicationData')

        if ((Test-Path -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk") -eq $false) {

            # Ensure the start menu directory exists.
            if ((Test-Path -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp" -PathType 'Container') -eq $false) {
                New-Item -Type 'Directory' -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp" | Out-Null
            }

            # Create the shortcut.
            New-Shortcut -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp.ps1""" -StartPath "$Path\bin"
            
            # Ensure that the shortcut was created.
            if (Test-Path -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk") {
                Write-Log -ConsoleOnly -Severity 'Info' -Message "Created a start menu directory and shortcut for running 'yt-dlp.ps1' at: '$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk'"
            }
            else {
                return Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to create a shortcut at: '$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk'"
            }
        } else {
            # Recreate the shortcut so that its values are up-to-date.
            New-Shortcut -Path "$AppDataPath\Microsoft\Windows\Start Menu\Programs\powershell-yt-dlp\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp.ps1""" -StartPath "$Path\bin"
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
        "$Path\bin\yt-dlp.ps1",
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
        $YtDlpOptions = "--output '$([environment]::GetFolderPath('MyVideos'))/%(uploader)s/%(upload_date)s - %(title)s.%(ext)s' --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters",

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
            Write-Log -ConsoleOnly -Severity 'Info' -Message "Getting video URLs from '$Path'."
            $UrlList += (Get-Content -Path $Path | Where-Object { $_.Trim() -ne '' -and $_.Trim() -notmatch '^#.*' })
        }
    }

    # Return an array of playlist URL string objects.
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Returning $($UrlList.Length) playlist URLs."
    return $UrlList
} # End Get-VideoList function



function Get-VideoFromList {
    param(
        [Parameter(Mandatory = $False, HelpMessage = 'The path to the yt-dlp video list file.')]
        [ValidateScript({Test-Path -Path $_})]
        [string]
        $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\etc\video-url-list.txt',
    
        [Parameter( Mandatory = $False, HelpMessage = 'The yt-dlp options to supply to the download command.')]
        [string]
        $YtDlpOptions = "--output '$([environment]::GetFolderPath('MyVideos'))' --download-archive '$([environment]::GetFolderPath('UserProfile'))\scripts\powershell-yt-dlp\var\download-archive.txt' --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
    )

    # Get the list of URLs from the video list file.
    $UrlList = Get-VideoList -Path $Path

    # Download from each URL.
    foreach ($Item in $UrlList) {
        Get-Video -Url $Item -YtDlpOptions $YtDlpOptions
        Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded video from URL '$Item'."
    }
}



Function Get-YtDlpMainMenu {
    $MenuOption = $null
    While ($MenuOption -notin @(1, 2, 3, 0)) {
		Clear-Host
		Write-Host "================================================================================"
		Write-Host "                             powershell-yt-dlp" -ForegroundColor "Yellow"
		Write-Host "================================================================================"
		Write-Host "`nPlease select an option:" -ForegroundColor "Yellow"
		Write-Host "  1 - Download video
  2 - Download audio
  3 - Update executables, open documentation, uninstall script, etc.
  `n  0 - Exit`n"
        $MenuOption = (Read-Host "Option").Trim()
		Write-Host ""
		
		Switch ($MenuOption) {
			1 {
				# Call the download menu with the default video settings configured.
				Get-YtDownloadMenu -Type video -Path ([environment]::GetFolderPath('MyVideos'))
                $MenuOption = $null
			}
			2 {
				# Call the download menu with the default audio settings configured.
				Get-YtDownloadMenu -Type audio -Path ([environment]::GetFolderPath('MyMusic'))
                $MenuOption = $null
			}
			3 {
				# Call the miscellaneous menu.
				Get-YtDlpSettingsMenu
                $MenuOption = $null
			}
			0 {
				# Exit the script.
				break
			}
			Default {
				# Ensure that a valid option is provided to the main menu.
				Write-Host "`nPlease enter a valid option.`n" -ForegroundColor "Red"
				$null = Read-Host "Press ENTER to continue..."
			}
		} # End Switch statement
	} # End While loop
}



Function Get-YtDownloadMenu {
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'Whether to download video or audio.')]
		[ValidateSet('video','audio')]
        [string]
        $Type,

        [Parameter(Mandatory = $false, HelpMessage = 'The URL of the video to download.')]
        [object]
        $Url = 'none',

        [Parameter(Mandatory = $false, HelpMessage = 'The directory to download the video/audio to.')]
        [string]
        $Path = (Get-Location),

        [Parameter(Mandatory = $false, HelpMessage = 'The path to the URL list file to download URLs from.')]
        [string]
        $VideoUrlListPath = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\etc\' + $Type + '-url-list.txt',

        [Parameter(Mandatory = $false, HelpMessage = 'yt-dlp options to use when downloading the video/audio.')]
        [string]
        $YtDlpOptions = $null
    )
	$MenuOption = $null
	While ($MenuOption -notin @(1, 2, 3, 4, 5, 6, 0)) {
		Clear-Host
		Write-Host "================================================================================"
		Write-Host "                                 Download $Type" -ForegroundColor "Yellow"
		Write-Host "================================================================================"
		Write-Host "`nURL:                $($Url -join "`n                    ")"
		Write-Host "Output path:        $Path"
		Write-Host "yt-dlp options: $YtDlpOptions"
		Write-Host "`nPlease select an option:" -ForegroundColor "Yellow"
		Write-Host "  1 - Download $Type"
		Write-Host "  2 - Configure URL"
		Write-Host "  3 - Configure yt-dlp options"
		Write-Host "  4 - Configure format to download"
		Write-Host "  5 - Get playlist URLs from file"
		Write-Host "`n  0 - Cancel`n"
		$MenuOption = (Read-Host 'Option').Trim()
		Write-Host ""
		
		Switch ($MenuOption) {
			1 {
				# If the URL value is an array of URLs, download each one.
				# If the URL value is not an array, download the single URL.
				if ($Url -is [array]) {
					foreach ($Item in $Url) {
						# Call the video download function for each URL in the array.
						Get-Video -Url $Item -YtDlpOptions $YtDlpOptions

						# If the URL was successfully downloaded, notified the user.
						# If the URL was not successfully downloaded, break out of the loop immediately.
						if ($LastExitCode -eq 0) {
							Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded $Type from '$Item' successfully.`n"
						} else {
                            Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to download $Type from '$Item'.`n"
                            $null = Read-Host "Press ENTER to continue..."
							$MenuOption = $null
							break
						} # End if ($LastExitCode -eq 0) statement
					} # End foreach loop
				} else {
					# Call the video download function.
					Get-Video -Url $Url -YtDlpOptions $YtDlpOptions

					# If the URL was successfully downloaded, notify the user.
					# If the URL was not successfully downloaded, return to the download menu.
					if ($LastExitCode -eq 0) {
						Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded $Type from '$Url' successfully.`n"
					} else {
                        Write-Log -ConsoleOnly -Severity 'Error' -Message "Failed to download $Type from '$Url'.`n"
						$null = Read-Host "Press ENTER to continue..."
						$MenuOption = $null
                        break
					} # End if ($LastExitCode -eq 0) statement
				} # End if ($Url -isnot [string] -and $Url -is [array]) statement
                $null = Read-Host "Press ENTER to continue..."
			}
			2 {
				# Prompt the user for the URL to download.
				$Url = (Read-Host 'URL').Trim()
				$MenuOption = $null
			}
			3 {
				# Prompt the user for the yt-dlp options
				$YtDlpOptions = (Read-Host 'yt-dlp options').Trim()
				$MenuOption = $null
			}
			4 {
				# If the URL is a single item (a string), get the formats available for download.
				if ($Url -is [string] -and $Url -isnot [array] -and $Url.Length -gt 0) {
					# Save the list of available download formats to a variable.
					$TestUrlValidity = Invoke-Expression "yt-dlp -F '$Url'"

					# If the 'yt-dlp -F $URL' command failed, display the output that it failed with.
					# If the 'yt-dlp -F $URL' command succeeded, display the formats that are available for download and prompt the user.
					if ($LastExitCode -ne 0) {
						Write-Host "$TestUrlValidity" -ForegroundColor "Red"
						$null = Read-Host "Press ENTER to continue..."
					} else {
						$AvailableFormats = Invoke-Expression "yt-dlp -F '$URL'" | Where-Object { ! $_.StartsWith('[') -and ! $_.StartsWith('format code') -and $_ -match '^[0-9]{3}' } | ForEach-Object {
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
							$null = Read-Host "Press ENTER to continue..."
							$AvailableFormats.GetEnumerator() | Sort-Object -Property FormatCode | Format-Table
							Write-Host "Enter the format code that you wish to download ([Enter] to cancel).`n"
							$FormatOption = Read-Host 'Format code'	
						}
						
						# If the user provided a valid format code, modify the yt-dlp options with that format code.
						if ($FormatOption.Length -gt 0) {
							if ($YtDlpOptions -clike '*-f*') {
								$YtDlpOptions = ($YtDlpOptions + ' ') -replace '-f ([a-zA-Z0-9]+) ', "-f $FormatOption "
							} else {
								$YtDlpOptions = $YtDlpOptions + " -f $FormatOption"
							}
						} # End if ($FormatOption.Length -gt 0) statement
					} # End if ($LastExitCode -ne 0) statement
				} else {
					Write-Host "Cannot display the format options for multiple URLs. Please set only one URL first.`n" -ForegroundColor "Red"
					$null = Read-Host "Press ENTER to continue..."
				} # End if ($Url -is [string] -and $Url -isnot [array] -and $Url.Length -gt 0) statement
				$MenuOption = $null
			}
			5 {
				# Retrieve the URL array from the URL list file.
				$Url = Get-VideoList -Path $VideoUrlListPath
				Write-Host ""
				$null = Read-Host "Press ENTER to continue..."
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
				$null = Read-Host "Press ENTER to continue..."
			}
		} # End Switch statement
	} # End While loop
} # End Get-DownloadMenu function



Function Get-YtDlpSettingsMenu {
    param (
        [Parameter(Mandatory = $false, HelpMessage = 'The directory where the ''powershell-yt-dlp'' script is to be installed to.')]
        [string]
        $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp',

        [Parameter(Mandatory = $false, HelpMessage = 'The branch of the ''powershell-yt-dlp'' GitHub repository to download from.')]
        [string]
        $Branch = '0.1.0'
    )

    $MenuOption = $null
	While ($MenuOption -notin @(1, 2, 3, 4, 5, 6, 7, 8, 0)) {
		Clear-Host
		Write-Host "================================================================================"
		Write-Host "                             Miscellaneous Options" -ForegroundColor "Yellow"
		Write-Host "================================================================================"
		Write-Host "`nPlease select an option:" -ForegroundColor "Yellow"
		Write-Host "  1 - Update the 'yt-dlp.exe' executable
  2 - Update the ffmpeg executables
  3 - Create a desktop shortcut
  4 - Open powershell-yt-dlp documentation
  5 - Open yt-dlp documentation
  6 - Open ffmpeg documentation
  7 - Install/update powershell-yt-dlp
  8 - Uninstall powershell-yt-dlp
`n  0 - Cancel`n"
        $MenuOption = (Read-Host "Option").Trim()
		Write-Host ""
		
		Switch ($MenuOption) {
			1 {
				# Re-download the yt-dlp.exe executable file.
				Get-YtDlp -Path ($Path + '\bin')
				$null = Read-Host "Press ENTER to continue..."
                $MenuOption = $null
			}
			2 {
				# Re-download the ffmpeg executable files.
				Get-Ffmpeg -Path ($Path + '\bin')
				$null = Read-Host "Press ENTER to continue..."
                $MenuOption = $null
			}
			3 {
				# Create the desktop shortcut for the script.
                $DesktopPath = [environment]::GetFolderPath('Desktop')
				New-Shortcut -Path "$DesktopPath\powershell-yt-dlp.lnk" -TargetPath (Get-Command powershell.exe).Source -Arguments "-ExecutionPolicy Bypass -File ""$Path\bin\yt-dlp.ps1""" -StartPath "$Path\bin"
				$null = Read-Host "Press ENTER to continue..."
                $MenuOption = $null
			}
			4 {
				# Open the link to the powershell-yt-dlp documentation for the provided branch version.
				Start-Process "https://github.com/mpb10/powershell-yt-dlp/blob/$Branch/README.md"
				$MenuOption = $null
			}
			5 {
				# Open the link to the yt-dlp documentation.
				Start-Process "https://github.com/yt-dlp/yt-dlp/blob/master/README.md"
				$MenuOption = $null
			}
			6 {
				# Open the link to the ffmpeg documentation.
				Start-Process "https://www.ffmpeg.org/ffmpeg.html"
				$MenuOption = $null
			}
			7 {
				# Install the script and its shortcuts.
				Install-YtDlpScript -Path $Path -Branch $Branch -LocalShortcut -DesktopShortcut -StartMenuShortcut
				$null = Read-Host "Press ENTER to continue..."
                $MenuOption = $null
			}
			8 {
				# Uninstall the script and its shortcuts.
				Uninstall-YtDlpScript -Path $Path
				$null = Read-Host "Press ENTER to continue..."
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
				$null = Read-Host "Press ENTER to continue..."
			}
		} # End Switch statement
	} # End While loop
}



# ################################################################################################
# Testing functions
# ################################################################################################



Function Test-GetYtDlpExecutables {
    $ErrorActionPreference = "Stop"
    $Path = Get-Location
    if ((Test-Path -Path $Path -PathType 'Container') -eq $false) {
		New-Item -Type 'Directory' -Path $Path | Out-Null
	}
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading yt-dlp to '.\yt-dlp.exe'."
    Get-YtDlp -Path $Path
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading ffmpeg to '.\'."
    Get-Ffmpeg -Path $Path
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing downloaded executables."
    Remove-Item -Path "$Path\yt-dlp.exe" -ErrorAction Stop
    Remove-Item -Path "$Path\ffmpeg.exe" -ErrorAction Stop
    Remove-Item -Path "$Path\ffplay.exe" -ErrorAction Stop
    Remove-Item -Path "$Path\ffprobe.exe" -ErrorAction Stop
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
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Uninstalling 'powershell-yt-dlp' from '$Path'."
    Uninstall-YtDlpScript -Path $Path
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpUninstallForce {
    $ErrorActionPreference = "Stop"
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\tests'
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Uninstalling 'powershell-yt-dlp' from '$Path' with the '-Force' option."
    Uninstall-YtDlpScript -Path $Path -Force
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpVideo {
    $ErrorActionPreference = "Stop"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading video."
    Get-Video -Url 'https://www.youtube.com/watch?v=C0DPdy98e4c' -YtDlpOptions "--output 'test-video.%(ext)s' --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded video from URL 'https://www.youtube.com/watch?v=C0DPdy98e4c'."
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path "test-video.*").Name), Length: $((Get-ChildItem -Path "test-video.*").Length), LastWriteTime: $((Get-ChildItem -Path "test-video.*").LastWriteTime)"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing '$((Get-ChildItem -Path "test-video.*").Name)'."
    Get-ChildItem -Path "test-video.*" | Remove-Item
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpAudio {
    $ErrorActionPreference = "Stop"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading audio."
    Get-Video -Url 'https://www.youtube.com/watch?v=C0DPdy98e4c' -YtDlpOptions "--output 'test-audio.%(ext)s' --no-mtime --extract-audio --audio-format mp3 --audio-quality 0"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded video from URL 'https://www.youtube.com/watch?v=C0DPdy98e4c'."
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path "test-audio.*").Name), Length: $((Get-ChildItem -Path "test-audio.*").Length), LastWriteTime: $((Get-ChildItem -Path "test-audio.*").LastWriteTime)"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing '$((Get-ChildItem -Path "test-audio.*").Name)'."
    Get-ChildItem -Path "test-audio.*" | Remove-Item
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Test complete."
}



Function Test-YtDlpVideoArchive {
    $ErrorActionPreference = "Stop"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading video with '--download-archive' option enabled."
    Get-Video -Url 'https://www.youtube.com/watch?v=C0DPdy98e4c' -YtDlpOptions "--output 'test-video.%(ext)s' --download-archive test-yt-dlp-archive.txt --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded video from URL 'https://www.youtube.com/watch?v=C0DPdy98e4c'."
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path "test-video.*").Name), Length: $((Get-ChildItem -Path "test-video.*").Length), LastWriteTime: $((Get-ChildItem -Path "test-video.*").LastWriteTime)"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Filename: $((Get-ChildItem -Path 'test-yt-dlp-archive.txt').Name), Length: $((Get-ChildItem -Path 'test-yt-dlp-archive.txt').Length), LastWriteTime: $((Get-ChildItem -Path 'test-yt-dlp-archive.txt').LastWriteTime)"    
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Contents of 'test-yt-dlp-archive.txt': $(Get-Content 'test-yt-dlp-archive.txt')"    
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Removing '$((Get-ChildItem -Path "test-video.*").Name)'."
    Get-ChildItem -Path "test-video.*" | Remove-Item
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloading video with '--download-archive' option enabled a second time."
    Get-Video -Url 'https://www.youtube.com/watch?v=C0DPdy98e4c' -YtDlpOptions "--output 'test-video.%(ext)s' --download-archive test-yt-dlp-archive.txt --no-mtime --limit-rate 15M --format `"(bv*[vcodec~='^((he|a)vc|h26[45])']+ba) / (bv*+ba/b)`" --embed-subs --write-auto-subs --sub-format srt --sub-langs en --convert-subs srt --convert-thumbnails png --embed-thumbnail --embed-metadata --embed-chapters"
    Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded video from URL 'https://www.youtube.com/watch?v=C0DPdy98e4c'."
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
        Write-Log -ConsoleOnly -Severity 'Info' -Message "Downloaded video from URL '$Item'."
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



Function Test-YtDlpAll {
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'The branch of the ''powershell-yt-dlp'' GitHub repository to download from.')]
        [string]
        $Branch
    )
    $ErrorActionPreference = "Stop"
    $Path = [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\tests'
    Test-YtDlpInstall -Branch $Branch
    Set-Location -Path $Path
    Test-GetYtDlpExecutables
    Test-YtDlpVideo
    Test-YtDlpAudio
    Test-YtDlpVideoArchive
    Test-YtDlpVideoList
    Set-Location -Path $(Split-Path -Path $Path -Parent)
    Test-YtDlpUninstall
}