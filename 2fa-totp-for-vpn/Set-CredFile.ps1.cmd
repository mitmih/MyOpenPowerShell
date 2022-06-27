@echo off && cls && echo Author Dmitriy Mikhaylov aka alt-air && chcp 65001>nul && setlocal ENABLEDELAYEDEXPANSION && echo.

@REM compute 2fa, set necessary files
    cd /D "%~dp0"
    set "file=%1"   && set "user=%2"    && set "init=%3"    && set "pfx=%4" && set "sfx=%5" && set "hide=!init:~0,2!********!init:~-2!"
    echo !file!     && echo !user!      && echo !hide!      && echo !pfx!   && echo !sfx!   && echo.
    
    PowerShell -Command "Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Force ; Get-ExecutionPolicy ; & './Set-CredFile.ps1' -f '!file!' -u '!user!' -i '!init!' -p '!pfx!' -s '!sfx!'"

@REM launching OpenVPN with the specified config

    start "!file!" /b "%ProgramFiles%\OpenVPN\bin\openvpn-gui.exe" --connect "!file!.ovpn" --config_dir "%USERPROFILE%\OpenVPN\config"
    @REM --show_balloon 0

@REM end
    timeout 3
    exit
