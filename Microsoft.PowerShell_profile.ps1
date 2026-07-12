$MSProfileVesion = "2026.07.12"
Write-Output $MSProfileVesion 
# ==============================================================================
# 1. CORE SHELL ENHANCEMENTS & COMPLETIONS
# ==============================================================================
Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
Import-Module -Name PSReadLine -ErrorAction SilentlyContinue

# Only apply modern prediction features if we are on PowerShell 7+
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
} else {
    # Fallback basic configuration safe for PowerShell 5.1
    Set-PSReadLineOption -EditMode Windows
}

# ==============================================================================
# 2. APPLICATION ALIASES & EXECUTABLES
# ==============================================================================
$SublimePath = 'C:\Program Files\Sublime Text\sublime_text.exe'
if (Test-Path $SublimePath) {
    Set-Alias subl $SublimePath
    Set-Alias sub $SublimePath
}

if (Test-Path 'C:\Kube\kubectl.exe') {
    Set-Alias k 'C:\Kube\kubectl.exe'
    Set-Alias kubectl 'C:\Kube\kubectl.exe'
}

Set-Alias gst _git_status
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin

# Set fallback $EDITOR cleanly without verbose loops
$Editors = @('nvim', 'pvim', 'vim', 'vi', 'code', 'notepad++', 'sublime_text', 'notepad')
foreach ($ed in $Editors) {
    if (Get-Command $ed -ErrorAction SilentlyContinue) {
        Set-Alias -Name vim -Value $ed
        break
    }
}

# ==============================================================================
# 3. SHORTCUTS & QUALITY OF LIFE FUNCTIONS
# ==============================================================================
function Update-PSProfile { 
    $url = "https://raw.githubusercontent.com/bradmcdowell/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
    Invoke-RestMethod $url -OutFile $PROFILE
}

function reload-profile { & $PROFILE }

function Edit-Profile {
    if ($host.Name -match "ise") {
        $psISE.CurrentPowerShellTab.Files.Add($PROFILE)
    } else {
        $editorCmd = Get-Command vim -ErrorAction SilentlyContinue
        if ($editorCmd) { & $editorCmd.Definition $PROFILE } else { notepad $PROFILE }
    }
}

# Navigation & Directory Traversal
function cd...  { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }
function g      { Set-Location $HOME\Documents\Github }
function ll     { Get-ChildItem -Path $pwd -File }

# Drive Registry Shortcuts
function HKLM: { Set-Location HKLM: }
function HKCU: { Set-Location HKCU: }
function Env:  { Set-Location Env: }

if (Test-Path "$env:USERPROFILE\Work Folders") {
    New-PSDrive -Name Work -PSProvider FileSystem -Root "$env:USERPROFILE\Work Folders" -Description "Work Folders" -ErrorAction SilentlyContinue
    function Work: { Set-Location Work: }
}

# ==============================================================================
# 4. UNIX-LIKE UTILITIES FOR WINDOWS
# ==============================================================================
function touch($file)           { "" | Out-File $file -Encoding ASCII }
function df                     { Get-Volume }
function which($name)           { (Get-Command $name).Definition }
function export($name, $value)  { Set-Item -Force -Path "env:$name" -Value $value }
function pgrep($name)           { Get-Process $name -ErrorAction SilentlyContinue }
function pkill($name)           { Get-Process $name -ErrorAction SilentlyContinue | Stop-Process }
function ix ($file)             { curl.exe -F "f:1=@$file" ix.io }
function Get-PubIP              { (Invoke-WebRequest http://ifconfig.me/ip).Content.Trim() }

function sed($file, $find, $replace) {
    (Get-Content $file).Replace($find, $replace) | Set-Content $file
}

function grep($regex, $dir) {
    if ($dir) { Get-ChildItem $dir | Select-String $regex } else { $input | Select-String $regex }
}

function dirs ($filter = "*") {
    Get-ChildItem -Recurse -Filter $filter -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
}

function find-file($name) {
    Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
}

function unzip ($file) {
    if (Test-Path $file) {
        Write-Output "Extracting $file to $pwd..."
        Expand-Archive -Path $file -DestinationPath $pwd -Force
    } else {
        Write-Error "File not found: $file"
    }
}

function uptime {
    if ($PSVersionTable.PSVersion.Major -le 5) {
        (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    } else {
        Get-Uptime -Since
    }
}

# ==============================================================================
# 5. ELEVATION MANAGEMENT & PROMPT ENGINE
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function admin {
    $targetHost = if ($PSVersionTable.PSVersion.Major -le 5) { "$psHome\powershell.exe" } else { "$psHome\pwsh.exe" }
    if ($args.Count -gt 0) {   
        Start-Process $targetHost -Verb runAs -ArgumentList ("-NoExit -Command & `'" + $args + "`'")
    } else {
        Start-Process $targetHost -Verb runAs
    }
}

# Window Title Configuration
$AdminTag = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}{1}" -f $PSVersionTable.PSVersion.ToString(), $AdminTag

# Custom Git Macros
function gcom { git add .; git commit -m "$args" }
function lazyg { git add .; git commit -m "$args"; git push }

# Initialize Oh My Posh safely across versions
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $UserThemePath = "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes\emodipt-extend.omp.json"
    $SharedThemePath = "$env:POSH_THEMES_PATH\emodipt-extend.omp.json"

    if (Test-Path $UserThemePath) {
        oh-my-posh init pwsh --config $UserThemePath | Invoke-Expression
    } elseif (Test-Path $SharedThemePath) {
        oh-my-posh init pwsh --config $SharedThemePath | Invoke-Expression
    } else {
        # Fallback to web theme if local files aren't found in this profile's context
        oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/emodipt-extend.omp.json" | Invoke-Expression
    }
} else {
    # Clean fallback prompt if Oh My Posh isn't globally registered/installed for PS5
    function prompt {
        "[" + (Get-Location) + "] $(if ($isAdmin) { '#' } else { '$' }) "
    }
}