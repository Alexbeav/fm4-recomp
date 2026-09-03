@echo off
setlocal
set "FM4_BUILD=%~dp0fm4\out\build\win-amd64-release"
copy /y "%~dp0fm4\fm4_runtime.toml" "%FM4_BUILD%\fm4.toml" >nul
cd /d "%FM4_BUILD%"
fm4.exe --game_data_root="%~dp0extracted"
