<# https://aakinshin.net/ru/posts/cheatsheet-rounding/

Math.Floor округляет вниз по направлению к отрицательной бесконечности.
Math.Ceiling округляет вверх по направлению к положительной бесконечности.
Math.Truncate округляет вниз или вверх по направлению к нулю.
#>

[cmdletbinding()]
param(
    [alias('l')][Parameter(position=0)][ValidateRange(0, 27)][uint16] $lim_min  = 1,        # нижняя граница точности, с которой нужно начать поиск дроби
    [alias('u')][Parameter(position=1)][ValidateRange(1, 28)][uint16] $lim_max  = 11,       # верхняя граница точности
    [alias('d')][Parameter(position=2)]                      [uint32] $delta    = 1000000,  # сколько чисел просчитывать в одном потоке
    [alias('k')][Parameter(position=3)]                      [uint16] $x        = 1         # потоков на одно ядро
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование


$piString  = '3.1415926535897932384626433832'

$piDecimal = [decimal] $piString

$MTCount = [int] $env:NUMBER_OF_PROCESSORS * $x

$PreCalcTable = @(
    <# 3, 1415926535893891715436873217 #> New-Object psobject -Property ([ordered] @{'acr' = 0; 'x' = 3; 'y' = 1})
    <# 3,1 666666666666666666666666667 #> New-Object psobject -Property ([ordered] @{'acr' = 1; 'x' = 19; 'y' = 6})
    <# 3,14 28571428571428571428571429 #> New-Object psobject -Property ([ordered] @{'acr' = 2; 'x' = 22; 'y' = 7})
    <# 3,141 0256410256410256410256410 #> New-Object psobject -Property ([ordered] @{'acr' = 3; 'x' = 245; 'y' = 78})
    <# 3,1415 094339622641509433962264 #> New-Object psobject -Property ([ordered] @{'acr' = 4; 'x' = 333; 'y' = 106})
    <# 3,14159 29203539823008849557522 #> New-Object psobject -Property ([ordered] @{'acr' = 5; 'x' = 355; 'y' = 113})
    <# 3,141592 9203539823008849557522 #> New-Object psobject -Property ([ordered] @{'acr' = 6; 'x' = 355; 'y' = 113})
    <# 3,1415926 006214321844063877448 #> New-Object psobject -Property ([ordered] @{'acr' = 7; 'x' = 86953; 'y' = 27678})
    <# 3,14159265 02457039953606202118 #> New-Object psobject -Property ([ordered] @{'acr' = 8; 'x' = 102928; 'y' = 32763})
    <# 3,141592653 0119026040722614948 #> New-Object psobject -Property ([ordered] @{'acr' = 9; 'x' = 103993; 'y' = 33102})
    <# 3,1415926535 583573009183052053 #> New-Object psobject -Property ([ordered] @{'acr' = 10; 'x' = 521030; 'y' = 165849})
    <# 3,14159265358 10777712044193066 #> New-Object psobject -Property ([ordered] @{'acr' = 11; 'x' = 833719; 'y' = 265381})
    <# 3,141592653589 3891715436873217 #> New-Object psobject -Property ([ordered] @{'acr' = 12; 'x' = 4272943; 'y' = 1360120})
    <# 3,1415926535897 266793966659725 #> New-Object psobject -Property ([ordered] @{'acr' = 13; 'x' = 20530996; 'y' = 6535219})
    <# 3,14159265358979 10113405412673 #> New-Object psobject -Property ([ordered] @{'acr' = 14; 'x' = 74724506; 'y' = 23785549})
    <# 3,141592653589793 4025461589202 #> New-Object psobject -Property ([ordered] @{'acr' = 15; 'x' = 165707065; 'y' = 52746197})
    <# 3,1415926535897932 578264481564 #> New-Object psobject -Property ([ordered] @{'acr' = 16; 'x' = 411557987; 'y' = 131002976})
    <# 3,14159265358979323 53925649295 #> New-Object psobject -Property ([ordered] @{'acr' = 17; 'x' = 1068966896; 'y' = 340262731})
    <# 3,141592653589793238 3863775064 #> New-Object psobject -Property ([ordered] @{'acr' = 18; 'x' = 6167950454; 'y' = 1963319607})
    <# 3,1415926535897932384 938750580 #> New-Object psobject -Property ([ordered] @{'acr' = 19; 'x' = 14885392687; 'y' = 4738167652})
    <# 3,14159265358979323846 23817428 #> New-Object psobject -Property ([ordered] @{'acr' = 20; 'x' = 21053343141; 'y' = 6701487259})
    <# 3,141592653589793238462 3817428 #> New-Object psobject -Property ([ordered] @{'acr' = 21; 'x' = 21053343141; 'y' = 6701487259})
)

$PreCalcTable | Add-Member -MemberType NoteProperty -Name 'PI' -Value $null    # значение π с заданной точностью
$PreCalcTable | Add-Member -MemberType NoteProperty -Name 'min' -Value $null   # время, затраченное на поиск пары x/y, в минутах
$PreCalcTable | Add-Member -MemberType NoteProperty -Name 'sec' -Value $null   # время, затраченное на поиск пары x/y, в секундах
$PreCalcTable | Add-Member -MemberType NoteProperty -Name 'tic' -Value $null   # время, затраченное на поиск пары x/y, в тактах

$PreCalcTable[0].PI = '3.'

$lim_min = [System.Math]::Max(1, $lim_min)

$RecalcTable = @($PreCalcTable | Where-Object {$_.acr -lt $lim_min})


#region Multi-Threading: распараллелим проверку доступности компа по сети

    #region: скрипт-блок задания, выполняемого в потоке
    $Payload =
    {
        Param
        (
            [decimal]   $piDecimal,     # 28 digit decimal precision
            [string]    $piString,      # PI максимальной точности, 28
            [int]       $accuracy,      # искомый уровень точности (кол-во знаков после запятой)
            [decimal]   $RangeStart,    # начало диапазона
            [decimal]   $RangeEnd,      # объём диапазона
            [decimal]   $step           # шаг диапазона
        )
        
        $table = @()
        
        for ($i = $RangeStart; $i -lt $RangeEnd; $i+=$step)
        {
            $skipA = $false
    
            $Floor = [System.Math]::Floor($i * $piDecimal)      # нижнее значение числителя-кандидата
            
            $mult = [decimal][System.Math]::Pow(10, ($accuracy + 0) )
            $piMult = [System.Math]::Truncate( $piDecimal * $mult )
            $piCalcMult = [System.Math]::Truncate( [decimal]$Floor / [decimal]$i * $mult )
            
            while ($piMult -eq $piCalcMult)
            {
                $skipA = $true
                
                $table += New-Object psobject -Property ([ordered]@{
                    'acr'   = $accuracy
                    'x'     = $Floor
                    'y'     = $i
                    'PI'    = ($piString[0..($accuracy + 1)] -join '') + '_<'  # ::Floor
                    'min'   = $null
                    'sec'   = $null
                    'tic'   = $null
                })
                
                $accuracy++
                
                $mult = [decimal][System.Math]::Pow(10, ($accuracy + 0) )
                $piMult = [System.Math]::Truncate( $piDecimal * $mult )
                $piCalcMult = [System.Math]::Truncate( [decimal]$Floor / [decimal]$i * $mult )
            }
            
            if($skipA) { continue }
            
            
            $Ceiling = [System.Math]::Ceiling($i * $piDecimal)    # вверхнее значение числителя-кандидата
            
            $mult = [decimal][System.Math]::Pow(10, ($accuracy + 0) )
            $piMult = [System.Math]::Truncate( $piDecimal * $mult )
            $piCalcMult = [System.Math]::Truncate( [decimal]$Ceiling / [decimal]$i * $mult )
            
            while ($piMult -eq $piCalcMult)
            {
                $table += New-Object psobject -Property ([ordered]@{
                    'acr'   = $accuracy
                    'x'     = $Ceiling
                    'y'     = $i
                    'PI'    = ($piString[0..($accuracy + 1)] -join '') + '_>'  # ::Ceiling
                    'min'   = $null
                    'sec'   = $null
                    'tic'   = $null
                })
                
                $accuracy++
                
                $mult = [decimal][System.Math]::Pow(10, ($accuracy + 0) )
                $piMult = [System.Math]::Truncate( $piDecimal * $mult )
                $piCalcMult = [System.Math]::Truncate( [decimal]$Ceiling / [decimal]$i * $mult )
            }
        }
        
        # $DebugObj = New-Object psobject -Property ([ordered]@{
        #     RangeStart  = $RangeStart
        #     accuracy    = $accuracy
        #     Current     = $i
        #     RangeEnd    = $RangeEnd
        # })
        
        # return $table, $DebugObj
        
        return $table
    }
    
    #endregion: скрипт-блок задания, выполняемого в потоке
    
    
    #region: запуск задания и добавление потоков в пул
    
    $NextRangeStartInWhile = [decimal]($RecalcTable | Where-Object {$_.acr -eq ($lim_min - 1)} | Select-Object -First 1).y
    
    for ($accuracy = $lim_min; $accuracy -lt $lim_max; $accuracy++)
    {
        $ContinueWhileCycle = $true
        
        $WhileCount = 0
        
        $RangeStart = $NextRangeStartInWhile
        
        while ($ContinueWhileCycle)
        {
            #region: инициализация пула
            
            $Pool = [RunspaceFactory]::CreateRunspacePool(1, $MTCount)
            
            $Pool.ApartmentState = "MTA"
            
            $Pool.Open()
            
            $RunSpaces = @()
            
            #endregion: инициализация пула
            
            
            #region: запуск потоков
            
            # $RangeStart +=  $MTCount * $delta * $WhileCount
            
            if ($WhileCount) { $RangeStart = $NextRangeStartInWhile }  # если этой 2й и более проход цикла - продолжим с последнего числа
            
            for ($i = 0; $i -lt $MTCount; $i++)
            {
                $NewShell = [PowerShell]::Create()
                
                $null = $NewShell.AddScript($Payload)
                
                $null = $NewShell.AddArgument($piDecimal)
                
                $null = $NewShell.AddArgument($piString)
                
                $null = $NewShell.AddArgument($accuracy)
                
                $null = $NewShell.AddArgument($RangeStart + $i)  # start
                
                $null = $NewShell.AddArgument($RangeStart + $i + <# $MTCount * #> $delta)  # end
                
                $null = $NewShell.AddArgument($MTCount)  # step
                
                $NewShell.RunspacePool = $Pool
                
                $RunSpace = [PSCustomObject]@{ Pipe = $NewShell; Status = $NewShell.BeginInvoke() }
                
                $RunSpaces += $RunSpace
            }
            
            "{0} .. {1}" -f ($RangeStart + $i),($RangeStart + $i + <# $MTCount * #> $delta) | Out-Null -Debug
            
            $NextRangeStartInWhile = ($RangeStart + $i + <# $MTCount * #> $delta)
            
            #endregion: запуск потоков
            
            
            while ($RunSpaces.Status.IsCompleted -contains $false) { Start-Sleep -Seconds 1 }  # ожидание завершения ВСЕХ потоков, в дальнейшем можно обрабатывать завершённые и сохранять обработанные в словарь, чтобы сократить время выполнения
            
            
            #region: обработка завершённых потоков
            
            $doExport = $false
            
            ### $dbgRanges = @()
            
            foreach ($RS in $RunSpaces | Where-Object -FilterScript {$_.Status.IsCompleted -eq $true})  # цикл по завершённым
            {
                $Result = $RS.Pipe.EndInvoke($RS.Status)
                
                # $qwe = $RS.Pipe.EndInvoke($RS.Status)
                
                # $Result = $qwe[0]
                
                ### $dbgRanges += $qwe[1]
                
                if ($Result.Count -gt 0)
                {
                    $doExport = $true
                    
                    $Result | ForEach-Object {
                        $_.min = $WatchDogTimer.Elapsed.TotalMinutes
                        $_.sec = $WatchDogTimer.Elapsed.TotalSeconds
                        $_.tic = $WatchDogTimer.Elapsed.Ticks
                    }
                    
                    $RecalcTable += $Result
                    
                    $ContinueWhileCycle = $false  # найдены дроби искомой точности, выход из цикла while для поиска дроби следующего уровня точности
                }
            }
            
            $RecalcTable = $RecalcTable | Sort-Object -Property 'acr', 'x'
            
            $RecalcTable[-1] | Format-Table -Property * #| Out-Null -Debug
            
            ### $dbgRanges | Format-Table * -Debug
            
            if ($doExport)
            {
                $RecalcTable | <# Select-Object -Property 'acr','x','y','PI' | #> Export-Csv -NoTypeInformation -Encoding Unicode -Path ("$env:HOMEPATH\Downloads\pi {0} x{1} {2} all.csv" -f $lim_max,$x, $delta) -Force  # сохранение результатов в csv-файл
            }
            
            #endregion: обработка завершённых потоков
            
            
            #region: после завершения всех потоков закрываем пул
            
            $Pool.Close()
            
            $Pool.Dispose()
            
            $WhileCount = 1  # сигнал, что уже был один проход цикла while и при следующей итерации $RangeStart начнётся с последнего $RangeEnd
            
            $accuracy = ($RecalcTable | Select-Object -Last 1).acr - 1
            
            #endregion: после завершения всех потоков закрываем пул
        }
    }
    
    #endregion: запуск задания и добавление потоков в пул
    
    

#endregion Multi-Threading

$RecalcTable | Format-Table -Property *

$RecalcTable | <# Select-Object -Property 'acr','x','y','PI' | #> Export-Csv -Force -NoTypeInformation -Encoding Unicode -Path ("$env:HOMEPATH\Downloads\pi {0} x{1} {2} all.csv" -f $lim_max,$x, $delta)  # сохранение результатов в csv-файл


$FirstOnly = @()

$RecalcTable | Group-Object -Property 'acr' | ForEach-Object {$FirstOnly += ($_ | Select-Object -ExpandProperty 'Group' | Select-Object -First 1) }

$FirstOnly |    Select-Object -Property 'acr','x','y','PI' |    Export-Csv -Force -NoTypeInformation -Encoding Unicode -Path ("$env:HOMEPATH\Downloads\pi {0} x{1} {2} first NO TIME.csv" -f $lim_max,$x, $delta)
$FirstOnly | <# Select-Object -Property 'acr','x','y','PI' | #> Export-Csv -Force -NoTypeInformation -Encoding Unicode -Path ("$env:HOMEPATH\Downloads\pi {0} x{1} {2} first.csv"         -f $lim_max,$x, $delta)

# [decimal]::MaxValue / 3                               = 26409387504754779197847983445
# [decimal]::MaxValue / 3.1415926535897910113405412673  = 25219107392466377863196895290
