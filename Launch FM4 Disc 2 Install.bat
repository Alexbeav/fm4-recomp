@echo off
setlocal

if "%~1"=="" (
  echo Usage: %~nx0 ^<folder-containing-extracted-Disc-2-packages^>
  exit /b 2
)

set "FM4_DISC2_ROOT=%~f1"
if not exist "%FM4_DISC2_ROOT%\" (
  echo Disc 2 package folder not found: %FM4_DISC2_ROOT%
  exit /b 2
)

pwsh -NoProfile -File "%~dp0tools\Run-Local.ps1" -GameDataRoot "%~dp0extracted" -Disc2ContentRoot "%FM4_DISC2_ROOT%"
