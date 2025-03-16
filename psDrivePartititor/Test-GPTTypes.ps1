param (
    [CmdletBinding()]
    
    # флажок очистки диска и установки новой таблицы разделов
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('cd')][switch]  $ClearDisk
)

$ErrorActionPreference = 'Stop'

<#  Какие GptType, типы (GUID) GPT-разделов, использует ОС Win
    Basic data          {ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}
        + в чужом проводнике
        + автобуква в чужом проводнике
    
    Microsoft Recovery  {de94bba4-06d1-4d40-a16a-bfd50179d6ac}
        + видно в чужом проводнике
        + автобуква в чужом проводнике
    
    Microsoft Reserved  {e3c9e316-0b5c-4db8-817d-f92df00215ae}
        - не видно в чужом проводнике
        - не видно в своём/чужом diskmgmt.msc
        - разделу не назначаются UNC-пути (проверял на другом ПК ОС win11)
            $fd | Get-Partition | select PartitionNumber, DriveLetter, Type, Size, AccessPaths | ft *
        + видно в PS, назначить букву можно, удалить нет, но буква исчезает после переподключения:
            $fd | Get-Partition | ? {!$_.AccessPaths} | Set-Partition -NewDriveLetter 'R'
    
    System Partition    {c12a7328-f81f-11d2-ba4b-00a0c93ec93b}
        - не видно в чужом проводнике
        - отказ в доступе после форматирования и назначения буквы
    
#>

$fd = Get-Disk | Where-Object { $_.BusType -eq 'USB' -and $_.FriendlyName -match 'KDI-MSFT'}
if (!$fd) { 'insert flash drive and re-run me' | Write-Warning ; break }

if ($ClearDisk) {
    Clear-Host
    $fd | Clear-Disk -PassThru -RemoveData -RemoveOEM -Confirm:$false | Set-Disk -PartitionStyle 'GPT'
    $fd | New-Partition -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -Size 1GB     # Basic
    $fd | New-Partition -GptType '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}' -Size 2GB     # Recovery
    $fd | New-Partition -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size 3GB     # Reserved
    $fd | New-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -Size 4GB     # System
}

# тест 1, назначаем букву диска и проверяем видимость на этом/другом ПК в проводнике/diskmgmt.msc
# j 106, k 107, l 108, m 109, n 110
$fd | Get-Partition | ForEach-Object { if (!$_.DriveLetter) { $_ | Set-Partition -NewDriveLetter ([char](106 + $_.PartitionNumber)) } }

# тест 2, форматируем, проверяем видимость/доступность
$fd | Get-Partition | ForEach-Object { $_ | Format-Volume -NewFileSystemLabel $_.PartitionNumber -FileSystem exFAT }

# тест 3, удаляем буквы, тома дисков по прежнему доступны по UNC-путям, все пути см. в (Get-Partition).AccessPaths
$fd | Get-Partition | ForEach-Object { $_ | Remove-PartitionAccessPath -AccessPath ($_.AccessPaths | Where-Object {$_ -match ':'}) }
