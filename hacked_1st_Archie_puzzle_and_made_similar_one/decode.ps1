#Requires -Version 7.2  # скрипт разрабатывался и тестировался с интерпретатором "C:\Program Files\PowerShell\7\pwsh.exe"

<#
.SYNOPSIS
    decode txt file with morses to png image

.DESCRIPTION
    to decode your morse txt file to png image make this steps:
        save decode.ps1 to your downloads
        save https://pastebin.com/raw/zeFkDskS to 'zeFkDskS' file
        run script (see examples)

.EXAMPLE
    pwsh -f "%USERPROFILE%\Downloads\decode.ps1" -m "%USERPROFILE%\Downloads\zeFkDskS"

.EXAMPLE
    pwsh -f "%USERPROFILE%\Downloads\decode.ps1" -m "%USERPROFILE%\Downloads\morseA.txt"

.INPUTS
    txt file with bytes encodes by Morse codes, where
        ----- is 0
        .---- is 1

.OUTPUTS
    png file

.NOTES
    (c) Mitry Mikhaylov

.LINK
    https://github.com/mitmih/MyOpenPowerShell

#>


[CmdletBinding()]
param (
    # path to file with morse codes
    [Alias('m')]
    [string] $MorseFile = (Join-Path -Path "$env:USERPROFILE\Downloads" -ChildPath 'morse.txt')
)

$ErrorActionPreference = "Stop"

$MorseFile = Get-ChildItem -Path $MorseFile
$Morse = (Get-Content -Path $MorseFile) -replace '−', '-' -replace '•', '.'

if (($Morse | Measure-Object).Count -lt 2) { $Morse = $Morse -split '   ' }

$MorseCodes = @{
    '-----' = '0'
    '.----' = '1'
}

$lst = @()
$Morse | ForEach-Object {
    $bits = ($_ -split ' ' | ForEach-Object { $MorseCodes[$_] }) -join ''
    $lst += [PSCustomObject] @{
        'morse' = $_
        'bits'  = $bits
        'byte'  = [System.Convert]::ToByte($bits, 2)
        'char'  = [System.Convert]::ToChar([System.Convert]::ToByte($bits, 2))
    }
}
$lst[0..3],' ...', $lst[-3..-1] | Format-Table *

$pngFile = $MorseFile -replace 'txt', 'png'
try
{
    # если в морзе было закодировано "data:image/png;base64,..."
    [System.Convert]::FromBase64String(($lst.char -join '' -replace 'data:image/png;base64,', '')) | Set-Content -Force -AsByteStream -Path $pngFile
}
catch
{
    $lst.byte | Set-Content -Force -AsByteStream -Path $pngFile
}
finally
{
    Get-Item $pngFile | Format-Hex | Select-Object -First 5
}
