# PowerShell 7
#oh-my-posh --init --shell pwsh --config "C:\Users\Brad\AppData\Local\Programs\oh-my-posh\themes\jandedobbeleer.omp.json" | Invoke-Expression
oh-my-posh --init --shell pwsh --config "C:\Users\Brad\AppData\Local\Programs\oh-my-posh\themes\sonicboom_dark.omp.json" | Invoke-Expression


Import-Module -Name Terminal-Icons
Import-Module -Name PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -EditMode Windows

set-alias subl 'C:\Program Files\Sublime Text\sublime_text.exe'
set-alias sub 'C:\Program Files\Sublime Text\sublime_text.exe'
Set-Alias gst _git_status

Set-Alias k 'C:\Kube\kubectl.exe'
Set-Alias kubectl 'C:\Kube\kubectl.exe'

# quick ways to navigate around the system, e.g. cd $documents
# $tools = "c:\tools"
# $code = "c:\code"
# $winsitter = "c:\code\winsitter"
# $vstools = "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\Tools"
# $documents = $home + "\Documents"
# $desktop = $home + "\Desktop"
# $downloads = $home + "\Downloads"
# $modules = $home + "\Documents\WindowsPowerShell\Modules"