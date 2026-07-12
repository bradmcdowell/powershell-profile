$MSProfileVersion = "2026.07.12.4"
Write-Output "PowerShell Profile Version: $MSProfileVersion"

# ==============================================================================
# 1. CORE SHELL ENHANCEMENTS & COMPLETIONS
# ==============================================================================
Import-Module -Name PSReadLine -ErrorAction SilentlyContinue

# Only apply modern prediction features and terminal icons if we are on PowerShell 7+
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
} else {
    # Fallback basic configuration safe for legacy PowerShell 5.1
    Set-PSReadLineOption -EditMode Windows
}

# ==============================================================================
# 2. APPLICATION ALIASES & EXECUTABLES
# ==============================================================================
Set-Alias subl 'C:\Program Files\Sublime Text\sublime_text.exe'
Set-Alias sub 'C:\Program Files\Sublime Text\sublime_text.exe'
Set-Alias gst _git_status

if (Test-Path 'C:\Kube\kubectl.exe') {
    Set-Alias k 'C:\Kube\kubectl.exe'
    Set-Alias kubectl 'C:\Kube\kubectl.exe'
}

# Check for best available terminal editor
Function Test-CommandExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { if (Get-Command $command) { RETURN $true } }
    Catch { RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

if (Test-CommandExists nvim) { $EDITOR='nvim' }
elseif (Test-CommandExists pvim) { $EDITOR='pvim' }
elseif (Test-CommandExists vim) { $EDITOR='vim' }
elseif (Test-CommandExists vi) { $EDITOR='vi' }
elseif (Test-CommandExists code) { $EDITOR='code' }
elseif (Test-CommandExists notepad++) { $EDITOR='notepad++' }
elseif (Test-CommandExists sublime_text) { $EDITOR='sublime_text' }
else { $EDITOR='notepad' }

Set-Alias -Name vim -Value $EDITOR

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
        $editorCmd = Get-Command $EDITOR -ErrorAction SilentlyContinue
        if ($editorCmd) { & $editorCmd.Definition $PROFILE } else { notepad $PROFILE }
    }
}

function cd...  { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }
function g      { Set-Location $HOME\Documents\Github }
function ll     { Get-ChildItem -Path $pwd -File }
function n      { notepad $args }

function HKLM: { Set-Location HKLM: }
function HKCU: { Set-Location HKCU: }
function Env:  { Set-Location Env: }

# File Hash Shortcuts
function md5    { Get-FileHash -Algorithm MD5 $args }
function sha1   { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

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

function dirs {
    if ($args.Count -gt 0) {
        Get-ChildItem -Recurse -Include "$args" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    } else {
        Get-ChildItem -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    }
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
        Get-WmiObject win32_operatingsystem | Select-Object @{EXPRESSION={ $_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
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

Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin

$AdminTag = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}{1}" -f $PSVersionTable.PSVersion.ToString(), $AdminTag

function gcom { git add .; git commit -m "$args" }
function lazyg { git add .; git commit -m "$args"; git push }

# ONLY initialize Oh My Posh if we are on PowerShell 7+
if ($PSVersionTable.PSVersion.Major -ge 7 -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    $UserThemePath = "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes\emodipt-extend.omp.json"
    $SharedThemePath = "$env:POSH_THEMES_PATH\emodipt-extend.omp.json"

    if (Test-Path $UserThemePath) {
        oh-my-posh init pwsh --config $UserThemePath | Invoke-Expression
    } elseif (Test-Path $SharedThemePath) {
        oh-my-posh init pwsh --config $SharedThemePath | Invoke-Expression
    } else {
        oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/emodipt-extend.omp.json" | Invoke-Expression
    }
} else {
    # Clean, lightweight fallback prompt for legacy PowerShell 5.1
    function prompt {
        "[" + (Get-Location) + "] $(if ($isAdmin) { '#' } else { '$' }) "
    }
}