# размеры логического блока (LBA) для конвертации адреса offset в адрес LBA либо делением либо битовым сдвигом вправо
#   в байтах,           LBA = offset    / lbaSB
#   как степень двойки, LBA = offset -shr lbaSS
$global:lbaSB = -1
$global:lbaSS = -2
$Global:psoPartitionTemplate = [PSCustomObject] @{
    'n'         = $null;
    'LBA'       = $null;
    'offset'    = $null;
    'size'      = $null;
    'end'       = $null;
    'isNew'     = $null;
    'dsc'       = $null;
    'GptType'   = $null;
    'fs'        = $null;
    'fsLabel'   = $null;
}


# если в названии функции использовать тире дважды, то при импорте вылезает предупреждение
#   WARNING: Some imported command names contain one or more of the following restricted characters: # , ( ) {{ }} [ ] & - / \ $ ^ ; : " ' < > | ? @ ` * % + = ~
function Test-Helper { # для проверки импорта этого модуля: если наз
    # [CmdletBinding()]
    param ( [Parameter(Mandatory, ValueFromPipeline)] [Alias('m')] [string] $message )
    return $message
}


function Get-LBA { # по адресу рассчитывает и возвращает LBA-блок, в котором этот адрес находится
    # [CmdletBinding()]
    param ( [Parameter(Mandatory, ValueFromPipeline)] [Alias('a')] [Int64] $address )
    
    $LBA = [PSCustomObject]@{
        'LBA'   = ($address -shr $lbaS)                         # /512, номер логического блока
        'offset'= ($address -shr $lbaS -shl $lbaS)              # адрес LBA-блока (0й, начальный байт)
        'size'  = $lbaB                                         # LogicalSectorSize
        'end'   = ($address -shr $lbaS -shl $lbaS) +$lbaB -1    # offset + size -1
    }
    
    return $LBA
}


function Show-Scheme { # визуализирует текущую схему разделов: шоу-схема = схема + пустые места между разделами
    # [CmdletBinding()]
    
    param (
        # схема разбивки диска, которую нужно визуализировать
        [Parameter(Mandatory)]
        $psoMap
    )
    
    $empty = Get-EmptySpace -psoMap $psoMap
    
    return $psoMap + $empty | Sort-Object 'offset'
}


function Test-Scheme {
    # [CmdletBinding()]
    param (
        # схема диска, которую нужно проверить
        [Parameter(Mandatory)]
        $psoMap
    )
    
    $show = @()
    foreach ($s in $psoMap | Sort-Object 'offset') {
        # текущая строка схемы (партиция, служебная область, ...), где
        #   cAdr    LBA * LogicalSectorSize = offset        контроль адресов LBA vs offset
        #   cLine   offset +size -1         = end           контроль строки (горизонтальный)
        #   cRow    offset -1               = prev end      контроль стролбца (вертикальный)
        $c = $s | Select-Object 'cAdr', 'cLine', 'cRow', *
        
        # контроль адресов LBA vs offset
        $c.cAdr     = [int](($c.LBA -shl $lbaS) -eq $c.offset)
        
        # контроль строки (горизонтальный)
        $c.cLine    = [int](($c.offset +$c.size -1) -eq $c.end)
        
        # контроль стролбца (вертикальный)
        $c.cRow     = [int](($c.offset -1) -eq $prev.end) + [int]($c.offset -eq 0) <# первую запись невозможно сравнить с предыдущей, поэтому результат её проверки равен True #>
        
        $show += $c
        $prev = $c
    }
    
    return ($show | Sort-Object 'offset')
}


function Reset-Debug { # очищает диск и добавляет на него несколько разделов в начале и конце для дальнейшей отладки математики разметки
    # [CmdletBinding()]
    param (
        # Storage-объект диска, которую нужно проверить
        [Parameter(Mandatory, ValueFromPipeline)] $Drive
    )
    
    # очистка разметки, установка GPT-стиля, ибо только отладочных разделов добавляется 6шт, а ещё появятся разделы из json-схемы
    $Drive | Clear-Disk -PassThru -RemoveData -RemoveOEM -Confirm:$false | Set-Disk -PartitionStyle 'GPT'
    
    # tail - разделы в конце диска
    $Drive | New-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -IsHidden -Size 1MB       -Offset ( ($Drive.Size -259*512) -1GB -1MB)
    $Drive | New-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -IsHidden -Size 2MB       -Offset ( ($Drive.Size -259*512) -1GB -1MB -3MB -2MB)
    # $Drive | New-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -IsHidden <# -Size 3MB #> -Offset ( ($Drive.Size -259*512) -1GB -1MB -3MB) -UseMaximumSize
    
    # head - разделы в начале диска
    $Drive | New-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -IsHidden -Size 1MB       -Offset ( 2048*512 +1GB )
    $Drive | New-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -IsHidden -Size 2MB       -Offset ( 2048*512 +1GB +1MB +3MB )
    # $Drive | New-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -IsHidden <# -Size 3MB #> -Offset ( 2048*512 +1GB +1MB ) -UseMaximumSize
}


function Convert-PartitionJsonToPSO { # преобразует json-описание партиции в pso-раздел, готовый для вставки 
    # [CmdletBinding()]
    param (
        # конфиг нового раздела из json-разметки диска
        [Parameter(Mandatory, ValueFromPipeline)] [Alias('jp')] $jsPart
    )
    
    # заготовка партиции из шаблончика
    $p = $psoPartitionTemplate | Select-Object *
    
    # переносим json-параметры в pso
    $p.fsLabel  =           $jsPart.fsLabel
    $p.size     = [Int64]   $jsPart.Size  # ибо из json прилетает строка вида "37GB", которую нужно преобразовать в число байт
    $p.GptType  =           $jsPart.GptType
    $p.fs       =           $jsPart.fs
    $p.fs       =           $jsPart.fs
    $p.isNew    =           $true
    $p.dsc      =           $jsPart.dsc
    
    return $p
}


function Add-PartitionToScheme { # размещает раздел на pso-схеме диска, рассчитывая его смещение и др. числа
    # [CmdletBinding()]
    param (
        # pso-схема диска, в которую нужно куда нужно добавить партицию
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)] [Alias('ps')] $psoMap
    )
    
    # новый раздел, чьи параметры нужно рассчитать, фильтр такой подробный потому, что в схеме их может быть несколько, но другие уже должны быть посчитаны, ибо расчитывается один раздел за раз
    $p = $psoMap | Where-Object {!$_.LBA -and !$_.offset -and $null -eq $_.n -and !$_.end -and $_.isNew}
    
    # для размещения текущего раздела, независимо от его размера, надо знать все свободные места - пустышки
    $empty = Get-EmptySpace -psoMap ($psoMap | Where-Object {$_ -ne $p})
    
    # пустышки должны подходить по размеру новому разделу, а среди подходящих выбираться наименьшая по размеру для ненулевых разделов и наибольшая - для нулевых
    if ($p.size) { $sort = @{'e' = 'size' ; Descending = $false} } else { $sort = @{'e' = 'size' ; Descending = $true} }
    
    $e = $empty | Sort-Object $sort | Where-Object {$_.size -ge $p.size} | Select-Object -First 1
    if ($e) { # есть пустышка, размещаемся
        $p.n        = [int](($psoMap.n | Measure-Object -Maximum | Select-Object -ExpandProperty 'Maximum') +1)  # предполагаемый номер нового раздела, для доп. контроля
        $p.LBA      = $e.LBA
        $p.offset   = $e.offset
        $p.size     = $p.size  # оставляем как есть для последующей корректной работы New-Partition -UseMaximumSize 
        $p.end      = if ($p.size) {$p.offset + $p.size -1} else {$e.end}
    } else { # пустышки закончились, а может их и изначально не было... в общем, если что-то нужно разместить, но негде - проблема с json-схемой
        # можно было бы удалить этот "лишний" раздел, но лучше отобразить оператору скрипта сбой при попытке разметить этот раздел на диске
        # $psoMap = $psoMap | Where-Object {$_ -ne $p}
        $null <# debug #> <# breakpoint #>
    }
    
    return $psoMap
}


function Get-EmptySpace { # определяет на pso-схеме диска пустые места и вовзращает их отдельным списком pso-элементов схемы
    # [CmdletBinding()]
    param (
        # pso-схема диска, в которой нужно найти пустые пространства
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)] $psoMap
    )
    
    # список обнаруженных пустот
    $empty = @()
    
    # если в схеме болтается "лишний" нулевик или несколько, т.е. нулевой раздел, который уже негде разместить,
    # а в схеме он потому, что оператор должен увидеть сбой New-Partition -UseMaximumSize, чтобы проанализировать и исправить json-схему,
    # то его нужно пропустить при расчётах, чтобы математика не разъехалась, это "нечестная" первая запись,
    foreach ($r in $psoMap | Sort-Object 'offset' | Where-Object {$null -ne $_.offset}) {
        # первая "честная" запись в схеме диска - это его головная служебная зона: запоминаем её край (последний байт), добавляем запись в шоу-схему и переходим к следущей записи в схеме
        if ($r.offset -eq 0) {
            $prev = $r.end
            continue
        }
        
        # нестыковка предыдущей записи схемы с текущей означает наличие пустого места
        if ($r.offset -eq ($prev + 1)) {} else {
            $e          = $psoPartitionTemplate | Select-Object *
            $e.LBA      = ($prev + 1) -shr $lbaS
            $e.offset   = $prev + 1
            $e.size     = $r.offset -1 -$prev
            $e.end      = $r.offset - 1
            $e.dsc      = 'empty'
            
            # добавим пустышку в список
            $empty += $e
        }
        
        # и запоминаем край (последний байт) текущей записи схемы диска
        $prev = $r.end
    }
    
    return $empty
}
