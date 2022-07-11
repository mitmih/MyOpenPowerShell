$MorseFile = Join-Path -Path "$env:USERPROFILE\Downloads" -ChildPath 'morse_A.txt' -Resolve | Get-Item

$Morse = ($MorseFile | Get-Content) -replace '−', '-' -replace '•', '.'

if (($Morse | Measure-Object).Count -lt 2) { $Morse = $Morse -split '   ' }

$MorseCodes = @{
    '0'     = '-----'
    '1'     = '.----'
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

$lst.byte | Set-Content -Force -AsByteStream -Path (Join-Path -Path "$env:USERPROFILE\Downloads" -ChildPath 'razgadka.png')
