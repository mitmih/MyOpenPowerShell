@echo off && cls && echo Author Dmitriy Mikhaylov aka alt-air && chcp 65001>nul && echo.

setlocal ENABLEDELAYEDEXPANSION

@REM compute 2fa, set necessary files
    cd /D "%~dp0"
    echo.
    set "file=%1" && echo !file!
    set "user=%2" && echo !user!
    set "init=%3" && echo !init!
    set  "pfx=%4" && echo !pfx!
    set  "sfx=%5" && echo !sfx!
    echo.
    
    PowerShell -Command "Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Force ; Get-ExecutionPolicy ; & './Set-CredFile.ps1' -f '!file!' -u '!user!' -i '!init!' -p '!pfx!' -s '!sfx!'"

@REM launching OpenVPN with the specified config

    start "!file!" /b "%ProgramFiles%\OpenVPN\bin\openvpn-gui.exe" --connect "!file!.ovpn" --config_dir "%USERPROFILE%\OpenVPN\config"
    @REM --show_balloon 0

@REM end
    timeout 3
    @REM pause
    exit
