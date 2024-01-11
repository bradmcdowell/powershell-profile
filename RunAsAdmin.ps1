# OMP Install
#
#winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh

# Choco install
#
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Terminal Icons Install
#
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

Set-ExecutionPolicy RemoteSigned