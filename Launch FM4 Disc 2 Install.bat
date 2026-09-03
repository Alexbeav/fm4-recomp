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

set "FM4_BUILD=%~dp0fm4\out\build\win-amd64-release"
copy /y "%~dp0fm4\fm4_runtime.toml" "%FM4_BUILD%\fm4.toml" >nul
cd /d "%FM4_BUILD%"
fm4.exe --game_data_root="%~dp0extracted" --fm4_disc2_content_root="%FM4_DISC2_ROOT%"
