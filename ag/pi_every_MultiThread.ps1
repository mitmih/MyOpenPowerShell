[cmdletbinding()]
param(
    [alias('l')][Parameter(position=0)][ValidateRange(0, 27)][uint16] $lim_min  = 1,    # нижняя граница точности, для которой нужно начать поиск дроби
    [alias('u')][Parameter(position=1)][ValidateRange(1, 28)][uint16] $lim_max  = 11,    # верхняя граница точности
    [alias('k')][Parameter(position=2)]                      [uint16] $x        = 1,    # потоков на одно ядро
    [alias('d')][Parameter(position=3)]                      [uint16] $delta    = 24000   # сколько чисел просчитывать в одном потоке
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
            $a = [System.Math]::Floor($i * $piDecimal)      # нижнее значение числителя-кандидата
            
            $piCalc = [string] ([decimal]$a / [decimal]$i)
            
            if (($piString[0..($accuracy + 1)] -join '') -eq ($piCalc[0..($accuracy + 1)] -join ''))  # Floor подходит, достигнут текущий уровень точности, запоминание результатов
            {
                while (($piString[0..($accuracy + 1)] -join '') -eq ($piCalc[0..($accuracy + 1)] -join ''))
                {
                    $table += New-Object psobject -Property ([ordered]@{
                        'acr'   = $accuracy
                        'x'     = $a
                        'y'     = $i
                        'PI'    = ($piCalc[0..($accuracy + 1)] -join '') + '_<'  # ::Floor
                        'min'   = $WatchDogTimer.Elapsed.TotalMinutes
                        'sec'   = $WatchDogTimer.Elapsed.TotalSeconds
                        'tic'   = $WatchDogTimer.Elapsed.Ticks
                    })
                    
                    $accuracy++
                }
                
                continue
            }
            
            
            $b = [System.Math]::Ceiling($i * $piDecimal)    # вверхнее значение числителя-кандидата
            
            $piCalc = [string] ([decimal]$b / [decimal]$i)
            
            if (($piString[0..($accuracy + 1)] -join '') -eq ($piCalc[0..($accuracy + 1)] -join ''))  # Ceiling подходит, достигнут текущий уровень точности, запоминание результатов
            {
                while (($piString[0..($accuracy + 1)] -join '') -eq ($piCalc[0..($accuracy + 1)] -join ''))
                {
                    $table += New-Object psobject -Property ([ordered]@{
                        'acr'   = $accuracy
                        'x'     = $b
                        'y'     = $i
                        'PI'    = ($piCalc[0..($accuracy + 1)] -join '') + '_>'  # ::Ceiling
                        'min'   = $WatchDogTimer.Elapsed.TotalMinutes
                        'sec'   = $WatchDogTimer.Elapsed.TotalSeconds
                        'tic'   = $WatchDogTimer.Elapsed.Ticks
                    })
                    
                    $accuracy++
                }
                
                continue
            }
        }
        
        return $table
    }
    
    #endregion: скрипт-блок задания, выполняемого в потоке
    
    
    #region: запуск задания и добавление потоков в пул
    
    for ($accuracy = $lim_min; $accuracy -le $lim_max; $accuracy++)
    {
        # $accuracy = [System.Math]::Max(($RecalcTable | Select-Object -Last 1).acr + 1, $lim_min)
        
        $ContinueWhileCycle = $true
        
        $WhileCount = 0
        
        $RangeStart = [decimal]($RecalcTable | Where-Object {$_.acr -le $accuracy} | Select-Object -Last 1).y #+ 1
        
        while ($ContinueWhileCycle)
        {
            #region: инициализация пула
            
            $Pool = [RunspaceFactory]::CreateRunspacePool(1, $MTCount)
            
            $Pool.ApartmentState = "MTA"
            
            $Pool.Open()
            
            $RunSpaces = @()
            
            #endregion: инициализация пула
            
            
            #region: запуск потоков
            
            $RangeStart +=  $MTCount * $delta * $WhileCount
            
            for ($i = 0; $i -lt $MTCount; $i++)
            {
                $NewShell = [PowerShell]::Create()
                
                $null = $NewShell.AddScript($Payload)
                
                $null = $NewShell.AddArgument($piDecimal)
                
                $null = $NewShell.AddArgument($piString)
                
                $null = $NewShell.AddArgument($accuracy)
                
                $null = $NewShell.AddArgument($RangeStart + $i)  # start
                
                $null = $NewShell.AddArgument($RangeStart + $i + $MTCount * $delta)  # end
                
                $null = $NewShell.AddArgument($MTCount)  # step
                
                $NewShell.RunspacePool = $Pool
                
                $RunSpace = [PSCustomObject]@{ Pipe = $NewShell; Status = $NewShell.BeginInvoke() }
                
                $RunSpaces += $RunSpace
            }
            
            "{0} .. {1}" -f ($RangeStart + $i),($RangeStart + $i + $MTCount * $delta)
            
            #endregion: запуск потоков
            
            
            while ($RunSpaces.Status.IsCompleted -contains $false) { Start-Sleep -Seconds 1 }  # ожидание завершения ВСЕХ потоков, в дальнейшем можно обрабатывать завершённые и сохранять обработанные в словарь, чтобы сократить время выполнения
            
            
            #region: обработка завершённых потоков
            
            $doExport = $false
            
            foreach ($RS in $RunSpaces | Where-Object -FilterScript {$_.Status.IsCompleted -eq $true})  # цикл по завершённым
            {
                $Result = $RS.Pipe.EndInvoke($RS.Status)
                if ($Result.Count -gt 0)
                {
                    $doExport = $true
                    $Result | ForEach-Object {
                        $_.min = $WatchDogTimer.Elapsed.TotalMinutes
                        $_.sec = $WatchDogTimer.Elapsed.TotalSeconds
                        $_.tic = $WatchDogTimer.Elapsed.Ticks
                    }
                    
                    $RecalcTable += $Result
                    
                    $ContinueWhileCycle = $false
                    # if ($null -ne ($Result | Where-Object {$_.acr -ge $accuracy})) {
                    #     $ContinueWhileCycle = $false
                    # }  # найдена дробь следующего уровня точности, цикл while нужно прервать и начать заново для +1 точности
                }
            }
            
            
            if ($doExport)
            {
                $RecalcTable = $RecalcTable | Sort-Object -Property 'acr', 'x'
                
                $RecalcTable | Export-Csv -NoTypeInformation -Encoding Unicode -Path ".\pi_all_$lim_max.csv" -Force  # сохранение результатов в csv-файл
                
                $RecalcTable[-2..-1] | Format-Table -Property *
            }
            
            #endregion: обработка завершённых потоков
            
            
            #region: после завершения всех потоков закрываем пул
            
            $Pool.Close()
            
            $Pool.Dispose()
            
            $WhileCount = 1
            
            $accuracy = ($RecalcTable | Select-Object -Last 1).acr
            
            #endregion: после завершения всех потоков закрываем пул
        }
    }
    
    #endregion: запуск задания и добавление потоков в пул
    
    

#endregion Multi-Threading

$RecalcTable | Format-Table -Property *

# [decimal]::MaxValue / 3                               = 26409387504754779197847983445
# [decimal]::MaxValue / 3.1415926535897910113405412673  = 25219107392466377863196895290
