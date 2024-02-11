# PowerShell-Youtube-dl
https://github.com/mpb10/PowerShell-Youtube-dl

A PowerShell module and script used to operate the [youtube-dl](https://github.com/ytdl-org/youtube-dl) command line program.


**Author: mpb10**

**April 27th 2021**

**v3.0.5**

#

 - [INSTALLATION](#installation)
 - [USAGE](#usage)
 - [CHANGE LOG](#change-log)
 - [ADDITIONAL NOTES](#additional-notes)
 
#

# INSTALLATION

**Script download link:** https://github.com/mpb10/PowerShell-Youtube-dl/archive/refs/tags/v3.0.5.zip

**Dependencies:**

* PowerShell 5.0 or greater (Comes pre-installed with Windows 10)*

#

**To Install:** 

1. Download the release .zip file and extract it to a folder.
1. Run the `Youtube-dl Setup` shortcut. This will install the script to `%USERPROFILE%\scripts\powershell-youtube-dl` and create a start menu shortcut named `PowerShell-Youtube-dl`.
1. Either exit the script by providing option `0`.

#

To uninstall this script and its files, run the script and choose option `3` to display the miscellaneous menu options, and choose option `7` to uninstall the script and its shortcuts. This will remove all files created by the script and will leave behind any files in `%USERPROFILE%\scripts\powershell-youtube-dl` that were not created by the script.

# USAGE

Run the script by using one of the shortcuts that were generated upon installation or by opening a PowerShell window and running the `youtube-dl-gui.ps1` file. The script can also be ran via the `Win+R` shortcut and pasting in the command `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\scripts\powershell-youtube-dl\bin\youtube-dl-gui.ps1"`.

Once at the main menu of the script, select option `1` or `2` to download video or audio. Once on the download menu, choose option `2` and enter the URL of the video that you wish to download. Youtube-dl supports video URLs from a variety of different websites, and the full list can be found [here](https://github.com/ytdl-org/youtube-dl/blob/master/docs/supportedsites.md).

Once a URL is configured, choose option `1` to download the video. By default, youtube-dl will download the best quality video or audio available, regardless of format. With the URL configured, option `5` of the download menu will display all of the file formats available for download and allow the user to choose a specific one to download.

If attempting to download from Youtube or another website results in an error while downloading, it is likely due to an outdated version of the youtube-dl executable. To update the youtube-dl executable, choose option `3` of the main menu to open the miscellaneous menu and then choose option `1` which will redownload the youtube-dl executable.

Multiple video URLs or playlist URLs can be downloaded in a batch operation via the `%USERPROFILE%\scripts\powershell-youtube-dl\etc\playlist-file.ini` file. To do this, create a file named `playlist-file.ini` in the `%USERPROFILE%\scripts\powershell-youtube-dl\etc` directory. List the video or playlist URLs on separate lines within the file and save it. Run the script, navigate to the download menu, and then choose option `6` to retrieve the URLs from the `playlist-file.ini` file. This option will add the `--yes-playlist` and `--download-archive` youtube-dl options to the download command (Note that the `--download-archive` option will cause the script to skip downloading any video that was previously downloaded). With the URLs retrieved from the file, choose option `1` to download each URL in a batch operation.


# CHANGE LOG

	3.0.5   April 27th, 2021
		Fixed download link for real this time.

	3.0.3   April 27th, 2021
		Fixed download link

	3.0.2   April 27th, 2021
		Updated changelogs

	3.0.1   April 27th, 2021
		Fixed mistakes in README.md

	3.0.0   April 27th, 2021
		!!! FULL RE-INSTALL IS REQUIRED FOR THIS VERSION !!!
		Previous playlist files and download archive files contents must be copied to the new locations at `%USERPROFILE%\scripts\powershell-youtube-dl\etc\playlist-file.ini` and `%USERPROFILE%\scripts\powershell-youtube-dl\var\download-archive.ini`.
		Added a new `youtube-dl.psm1` PowerShell module containing commandlets used to install and operate youtube-dl.
		Refactored and re-wrote the majority of the `youtube-dl-gui.ps1` GUI script.
		Added youtube-dl options presets for different file formats.
		Adjusted the installation path of the script and the different files used by it.

	2.0.3	May 7th, 2018
		!!! FULL RE-INSTALL IS REQUIRED FOR THIS VERSION !!! Just updating the script file won't cut it.
		\scripts folder has been removed and youtube-dl.ps1 file moved to root folder.
		DownloadArchive.txt split up into two separate files. One for video and one for audio.
		Changes and fixes to updating and installing.
		Any cache data that is downloaded is now downloaded to the new \cache folder.
		Script automatically checks for updates on startup by default. Can be toggled in script file settings.
		Video and audio are now downloaded to the same folder as the script when running in portable mode.
		Added update notes feature when updating the script file.
		Newest stable version of ffmpeg is now automatically chosen when downloaded.

	2.0.2	April 3rd, 2018
		Fixed some issues with the shortcuts.
		Added $VerboseDownloading option to the script file settings.
		Combined the videoplaylistfile.txt and audioplaylistfile.txt into one file called PlaylistFile.txt
	
	2.0.1	March 6th, 2018
		Minor bug fixes.

	2.0.0	February 28th, 2018
		Finished re-writing the script.

	1.2.6	November 16th, 2017
		Added option to download the entire playlist that a video resides in.

	1.2.5	November 15th, 2017
		Simplified and cleaned up some code.
		Updated the readme file.

	1.2.4	July 12th, 2017
		Added ability to choose whether to use the youtube-dl download archive when downloading playlists.

	1.2.3	July 11th, 2017
		Edited Youtube-dl_Installer.ps1 to uninstall the script using the -Uninstall parameter.
		Added a shortcut for uninstalling the script and its files.

	1.2.2	July 3rd, 2017
		Cleaned up code.

	1.2.1	June 22nd, 2017
		Uploaded the project to Github.
		Condensed installer to one PowerShell script.
		Edited documentation.
		
	1.2.0	March 30th, 2017
		Implemented ffmpeg video conversion.
		
	1.1.0	March 27th, 2017
		Implemented videoplaylist.txt and audioplaylist.txt downloading.


# ADDITIONAL NOTES

Please support the development of youtube-dl and ffmpeg. The programs youtube-dl and ffmpeg and their source code can be found at the following links:

https://youtube-dl.org/

https://www.ffmpeg.org/


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
