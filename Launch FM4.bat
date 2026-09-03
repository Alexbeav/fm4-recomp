@echo off
setlocal
pwsh -NoProfile -File "%~dp0tools\Run-Local.ps1" -GameDataRoot "%~dp0extracted"
