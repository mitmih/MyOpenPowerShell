<#  TODO [ ]
    [ ] явно преобразовать offset'ы и др. числа в [Int64]
        проблема в том, что 64ГБ выходит за диапазон [Int32],
        поэтому даже при простых расчётах вроде offset +size -1 = end
        на выходе получается [Double], число с запятой и нулями, напр., 68719476737,00
        что, как минимум, смотрится так себе при выводе pso-схем на экран
        # 
#>
<#  DONE [v]
    [v] подумать, может стоит отрефакторить и заменить psoScheme на psoMap (pso-карта диска), + сделать единообразие в комментах pso-схему на pso-карту?
        порефакторил и др. моменты тоже
        # 
    [v] концепция json-директивы "placement" ("head" и "tail") идёт нафиг, из-за неё много головняка с кодом, размещающим разделы по головным/хвостовым пустышкам...
        гораздо проще размещать ненулевые разделы в наименьшей подходящей по размеру области, а нулевые - в наибольшей
        в связи с этим нужно выпилить из json "placement" ("head" и "tail") и протестить код, исправить возникшие баги
        # 
    [v] заменить обратно .placement на .dsc из-за отказда от концепции head/tail в pso-объектах, ибо пока между pso и json описаниями разделов в этом моменте рассинхрон
        # 
    [v] исправить баг - в размещении ненулевых разделов ровно та же проблема, что с нулевыми:
            чтобы разместить новый раздел в указанной половине диска, надо рассчитать его смещение по уже занятому месту
            для этого pso-схема фильтруется, отбрасывая разделы из др половины диска,
            значит при схеме, когда первая половина уже вся расписана, эта логика будет выделять одно и то последнее занятое смещение каждый раз
            см. как текущая json-схема посчиталась в pso-карту:
                cAdr cLine cRow       LBA      offset        size         end isNew n placement        GptType                                fs    fsLabel
                ---- ----- ----       ---      ------        ----         --- ----- - ---------        -------                                --    -------
                1       1     1         0           0     1048576     1048575         head reserve
                1       1     1      2048     1048576 39728447488 39729496063 True  1                  {ebd0a0a2-b9e5-4433-87c0-68b6b72699c7} NTFS  vAir   
                1       1     1  77596672 39729496064  5368709120 45098205183 True  3 head             {e3c9e316-0b5c-4db8-817d-f92df00215ae} exFAT vi11   
                1       1     0  77596672 39729496064     1048576 39730544639 True  4 head             {c12a7328-f81f-11d2-ba4b-00a0c93ec93b} exFAT vi12   
                1       1     0  77596672 39729496064     1048576 39730544639 True  5 head             {e3c9e316-0b5c-4db8-817d-f92df00215ae} exFAT vi13   
                1       1     1  77598720 39730544640    -1048576 39729496063         tail empty space
                1       1     0  77598720 39730544640 19061014528 58791559167         tail empty space
                1       1     0  88082432 45098205184 -5368709120 39729496063         tail empty space
            LBA 77596672 был выделен трижды -> математика сбойнула, рассчитав отрицательные смещения пустышек...
        решением должна быть сортировка пустышек вместо отсеивания
        # 
    [v] заменить .dsc на .placement в pso-объектах, ибо пока между pso и json описаниями разделов в этом моменте рассинхрон
        # 
    [v] НЕ НАДО - все равно при переименовании поля придётся рефакторить весь код целиком
        заменить в коде
            ... = [PSCustomObject]@{ 'n' = $null  ; 'LBA' = ...
        на копирование из шаблончика
            $p = $psoPartitionTemplate | Select-Object *
        чтобы редактировать поля в одном месте, а не по всем исходникам
        # 
    [v] заменить везде /512
        во-первых, на /LogicalSectorSize
        
        во-вторых, вместо деления нужно использовать сдвиг, /512 это -shr 9
        для неизв. LogicalSectorSize нужно знать степень двойки, напр., так
            ([System.Convert]::ToString($fd.LogicalSectorSize, 2) | Select-Object -ExpandProperty 'Length') -1
        тогда
            /$fd.LogicalSectorSize
        будет эквивалентно
            -shr ([System.Convert]::ToString($fd.LogicalSectorSize, 2) | Select-Object -ExpandProperty 'Length') -1
        проверка
            1MB /$fd.LogicalSectorSize
            1MB -shr (([System.Convert]::ToString($fd.LogicalSectorSize, 2) | Select-Object -ExpandProperty 'Length') -1)
        # 
#>

#Requires -PSEdition 'Core' -Version 7

param (
    [CmdletBinding()]
    
    # имя файла со схемой разбивки диска
    [Parameter(ValueFromPipeline<# , Mandatory #>)]
    [Alias('s', 'js')][string] $scheme = 'test 1.jsonc',
    
    # если флажок отладки математики $true, то разметка целевого диска будет стёрта, затем добавятся несколько разделов в голове и хвосте диска для отладки математики
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('dm')][switch]       $debugMath
)


# magic numbers:
# 1 размер LBA, логического блока, по умолчанию равен 512 байт, предположительно записан в поле LogicalSectorSize командлета Get-Disk
#   Специально я не проверял случай ручной установки размера блока,
#   поэтому не могу сказать, как измениться количество зарезервированных блоков
#   Предполагаю, что при х2 увеличении размера LBA 512 -> 1024 байт, кол-во резервных блоков пропорционально снизится 2048 -> 1024,
#   ибо, раз по умолчанию один блок хранит 4 записи по 128 байт о 4х разделах, то увеличенный в х2 блок сможет хранить в х2 раза больше записей,
#   а (предположительно) при установки на диск новой таблицы разделов резервируется место под определённое кол-во записей про разделы, а кол-во блоков вторично,
#   т.е. кол-во записей постоянно, значит размер резервируемой области (2048*512 или 1024*1024) тоже
# 
# 2 зарезервированные блоки
#   ОС Win10 резервирует первые 2048 (с 0 по 2047) и последние 259 блоков (с -259 по -1) в служебных целях под нужды GPT


#region # Define variables
$ErrorActionPreference = 'Stop'

$SchemeViewOrder = @(
    'cAdr'
    'cLine'
    'cRow'
    @{'n' = ' '; 'e' = {$null}}
    'LBA'
    'offset'
    <# 'size' #> @{'e' = {[int]($_.size/1MB)} ; 'l' = 'size, MB'}
    'end'
    'isNew'
    'n'
    'dsc'
    'GptType'
    'fs'
    'fsLabel'
)
#endregion


#region # get myself as FSObject, import helper module
    try     { $MySelf = Get-Item -Path ($MyInvocation.MyCommand.Definition) }
    catch   { Throw $_ ; return -1 }
    finally {}
    
    # вспомогательный модуль с функциями
    try     { Import-Module -Force -Name (Join-Path -Path $MySelf.Directory.FullName -ChildPath 'psDrivePartititor.psm1') <# -Verbose #> }
    catch   { Throw $_ ; return -1 }
    finally { "+psDrivePartititor.psm1" | Test-Helper | Out-Null }
#endregion


#region # read json partitions scheme
    try     {
        $jsFile = Get-Item -Path $scheme
        $js = $jsFile | Get-Content | ConvertFrom-Json
        
        # контроль выбора json именно со схемой разбивки, а не какого-то другого
        if ($js.CheckPoint -ne 'DrivePartititor Scheme') { return -2 }
    }
    catch   { Throw $_ ; return -2 }
    finally {}
#endregion


#region # set point to target USB flash drive
    try     { $fd = Get-Disk | Where-Object { $_.BusType -eq $js.BusType -and $_.FriendlyName -match $js.FriendlyName} }
    catch   { Throw $_ }
    finally {
        # вычисляем размеры логического блока, это глобальные переменные из вспомогательного модуля
        $Global:lbaB = $fd.LogicalSectorSize
        $Global:lbaS = ([System.Convert]::ToString($fd.LogicalSectorSize, 2) | Select-Object -ExpandProperty 'Length') -1
    }
#endregion


# debug - бахним несколько разделов для отладки математики шашечной разметки
if ($debugMath) { "Reset-Debug: {0}" -f (Reset-Debug -Drive $fd) | Write-Warning }


#region # составление текущей схемы разделов диска
    # во-первых, обозначим области, которые обычно резервируются
    $DriveScheme = @(
        #                               ;                                   ;                               ;                   ;                       ;                   ;                               ;               ;           ;               ;
        [PSCustomObject]@{ 'n' = $null  ; 'LBA' = 0                         ; 'offset' = 0                  ; 'size' = 2048*512 ; 'end' = 2048*512 -1   ; 'isNew' = $null   ; 'dsc' = 'head reserve'  ; 'GptType' = ''; 'fs' = '' ; 'fsLabel' = ''; }
        <# empty or misinformated space #>
        [PSCustomObject]@{ 'n' = $null  ; 'LBA' = ($fd.Size -shr $lbaS) -259; 'offset' = $fd.Size -259*512  ; 'size' = 259*512  ; 'end' = $fd.Size -1   ; 'isNew' = $null   ; 'dsc' = 'tail reserve'  ; 'GptType' = ''; 'fs' = '' ; 'fsLabel' = ''; }
    )
    
    # во-вторых, если диск НЕ будет обнуляться, отразим на схеме существующие разделы
    if (!$js.ClearDisk) {
        $fd | Get-Partition <# | Select-Object 'PartitionNumber', 'Offset', 'Size', 'GptType' | Sort-Object 'PartitionNumber' #> | ForEach-Object {
            $p = $_
            
            $DriveScheme += [PSCustomObject]@{ 'n' = $p.PartitionNumber ; 'LBA' = $p.Offset -shr $lbaS ; 'offset' = $p.Offset ; 'size' = $p.Size ; 'end' = $p.Offset + $p.Size -1 ; 'isNew' = $null ; 'dsc' = '' ; 'GptType' = $p.GptType ; 'fs' = ''; 'fsLabel' = ''; }
        }
    }
#endregion


# визуальный контроль pso-схемы
Clear-Host ; Test-Scheme -psoMap (Show-Scheme -psoMap $DriveScheme) | Select-Object $SchemeViewOrder | Format-Table * -AutoSize


#region # добавление на pso-карту диска разделов из json-схемы
    # 
    $js.DriveScheme | ForEach-Object {
        $psoPart = $_ | Convert-PartitionJsonToPSO
        $DriveScheme = Add-PartitionToScheme -psoMap ($DriveScheme + $psoPart)
    }
    # 
#endregion


# визуальный контроль pso-схемы
Clear-Host ; Test-Scheme -psoMap (Show-Scheme -psoMap $DriveScheme) | Select-Object $SchemeViewOrder | Format-Table * -AutoSize


#region # очистка диска от прежней таблицы разделов и установка новой при необходимости
    # 
    if ($js.ClearDisk) {
        try     { $fd | Clear-Disk -PassThru -RemoveData -RemoveOEM -Confirm:$false | Set-Disk -PartitionStyle $js.PartitioningStyle }
        catch   { Throw $_ }
        finally { $fd = $fd | Get-Disk }
    }
    # 
#endregion


#region # применение pso-схемы к диску
    # 
    # $DriveScheme | Where-Object { $_.isNew } | ForEach-Object {
    foreach ( $r in ($DriveScheme | Where-Object { $_.isNew }) ) {
        try     {
            # + новый раздел
            if ($r.size) {
                $p = $fd | New-Partition -GptType $r.GptType -Offset $r.offset -Size $r.size
            } else {
                $p = $fd | New-Partition -GptType $r.GptType -UseMaximumSize
            }
            
            # форматирование тома на новом разделе, буква диска необязательна, можно форматнуть по UNC/Literal пути вида \\?\Volume{xxxxxxxx-...}
            Format-Volume -Path $p.AccessPaths -FileSystem $r.fs -NewFileSystemLabel $r.fsLabel
            
            # чекаем конфиг: если надо, то открываем раздел в проводнике по его UNC-пути
            $AfterOpen = $js.DriveScheme | Where-Object {$_.fsLabel -eq $r.fsLabel -and $_.fs -eq $r.fs -and $_.GptType -eq $r.GptType} | Select-Object -ExpandProperty 'AfterOpen'
            if ($AfterOpen) {
                Start-Process ($p.AccessPaths | Select-Object -First 1)
            }
        }
        catch   {
            # возникает либо при повторном вызове $fd | New-Partition -GptType $r.GptType -UseMaximumSize,
            # когда единственное свободное место было выделено под прошлый нулевик
            # либо из-за нестыковок в json-разметке, напр., разметели больше, чем фактический размер диска
            # кидаем оператору скрипта warning и живём дальше
            $r | Write-Warning
            $_.Exception.Message | Write-Warning
            'проверь свою json-схему: либо ты накосорезил при распределении объёма диска по разделам, либо нарисовал лишних нулевых разделов, которые негде разместить' | Write-Warning
        }
        finally {}
    }
    # 
#endregion
