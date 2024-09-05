# powershell-yt-dlp

https://github.com/mpb10/powershell-yt-dlp/

A PowerShell module and script used to operate the [yt-dlp](https://github.com/yt-dlp/yt-dlp) command line program.

**Author: mpb10**

**September 4th 2024**

**v0.1.0**

#

 - [INSTALLATION](#installation)
 - [USAGE](#usage)
 - [CHANGE LOG](#change-log)
 - [ADDITIONAL NOTES](#additional-notes)
 
#

# INSTALLATION

**Script download link:** https://github.com/mpb10/powershell-yt-dlp/archive/refs/tags/v0.1.0.zip

**Dependencies:**

* PowerShell 5.0 or greater

#

**To Install:** 

1. Download the release .zip file and extract it to a folder.
1. Run the `Install and upgrade powershell-yt-dlp` shortcut. This will install the script to `%USERPROFILE%\scripts\powershell-yt-dlp` and create start menu shortcuts.

#

To uninstall this script and its shortcuts, open a PowerShell command prompt and run the following commands:

```
Import-Module -Force [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\yt-dlp.psm1'
Uninstall-YtDlpScript -Path [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp'
```

To completely uninstall the script, including user modified files, run the following commands:

```
Import-Module -Force [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp\yt-dlp.psm1'
Uninstall-YtDlpScript -Path [environment]::GetFolderPath('UserProfile') + '\scripts\powershell-yt-dlp' -Force
```

# USAGE

* This script installs to the `C:\Users\mbitt\scripts\powershell-yt-dlp` folder.
* Files that are commonly modified by end-users are located in the `etc\` directory.
  * `video-url-list.txt` contains a user-defined list of URL's to download using the respective shortcut or `yt-dlp-download-video-url-list.ps1` script.
  * Each line should contain one URL.
  * The URL can be a specific video URL, a playlist URL, or even a Youtube channel URL.
  * List of supported sites to download from can be found [here](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
* Files that are modified as a result of running the script are located in the `var\` directory.
  * `download-archive-video.txt` contains a list of video ID's that are not to be downloaded again on subsequent runs of the script.
  * To re-download a video, copy the video's ID from its URL, use `CTRL + F` to search for it in the `download-archive-video.txt` file, and then remove that line.
* Script files, the yt-dlp executables, and ffmpeg executables are located in the `bin\` directory.
  * The script files and the executables can be updated by running the `Install and upgrade powershell-yt-dlp` shortcut again, which will re-download the latest versions of each.

# CHANGE LOG

	0.1.0	September 4th, 2024
		Initial version of the script.

# ADDITIONAL NOTES

Please support the development of yt-dlp and ffmpeg. The programs yt-dlp and ffmpeg and their source code can be found at the following links:

https://github.com/yt-dlp/yt-dlp

https://www.ffmpeg.org/


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
