# Install PowerShell 7
winget install --id Microsoft.Powershell --source winget
winget install --id Microsoft.Powershell.Preview --source winget

# Installl Oh My Posh
winget install --id PKG.Font.MesloLGM-NF --exact

$url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
$zip = "$env:TEMP\Meslo.zip"
$out = "$env:TEMP\MesloFont"

Invoke-WebRequest -Uri $url -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $out -Force

$destination = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination -Force }

Get-ChildItem -Path $out -Filter "*MesloLGM*.ttf" | ForEach-Object {
    Copy-Item $_.FullName -Destination "$destination\$($_.Name)" -Force
    New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "$($_.BaseName) (TrueType)" -Value "$destination\$($_.Name)" -PropertyType String -Force
}

Remove-Item $zip, $out -Recurse -Force

function Update-PSProfile { 
    $url = "https://raw.githubusercontent.com/bradmcdowell/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
    Invoke-RestMethod $url -OutFile $PROFILE
}

Update-PSProfile