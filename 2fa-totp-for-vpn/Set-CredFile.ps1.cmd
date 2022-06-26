@echo off && cls && echo Author Dmitriy Mikhaylov aka alt-air && chcp 65001>nul && echo.

setlocal ENABLEDELAYEDEXPANSION

@REM compute 2fa, set necessary files
    cd /D "%~dp0"
    echo %CD%
    echo.
    echo %0
    echo %1
    echo %2
    echo %3
    echo %4
    echo %5
    echo.
    
    PowerShell -Command "Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Force ; Get-ExecutionPolicy ; & './Set-CredFile.ps1' -f '%1' -u '%2' -p '%3' -i '%4' -s '%5'"

@REM launching OpenVPN with the specified config

    start "%1" /b "%ProgramFiles%\OpenVPN\bin\openvpn-gui.exe" --connect "%1.ovpn" --config_dir "%USERPROFILE%\OpenVPN\config"
    @REM --show_balloon 0

@REM exit
    timeout 3 & exit
