[cmdletbinding()]
param(
    [alias('l')][Parameter(position=0)][ValidateRange(0, 27)][uint16] $lim_min = 6,  # нижняя граница точности, для которой нужно начать поиск дроби
    [alias('u')][Parameter(position=1)][ValidateRange(1, 28)][uint16] $lim_max = 8   # верхняя граница точности
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование


$pi_string  = '3.1415926535897932384626433832'

$pi_decimal = [decimal] $pi_string

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
            [decimal]   $i,
            [int]       $accuracy,
            [string]    $pi0,
            [string]    $pi2,
            [decimal]   $pi_decimal
        )
        
        # $SolutionFound = $false
        
        $Solution = New-Object psobject -Property ([ordered]@{
            'acr'   = $accuracy
            'x'     = $null
            'y'     = $i
            'PI'    = $null
            'min'    = $null
            'sec'    = $null
            'tic'    = $null
        })
        
        $a = [System.Math]::Floor($i * $pi_decimal)      # нижнее значение числителя-кандидата
        
        $piA = ([string]( [decimal]$a / [decimal]$i ))[0..($accuracy + 1)] -join ''
        
        $piAA = ([string]( [decimal]$a / [decimal]$i ))[0..($accuracy + 2)] -join ''
        
        if ($pi0 -eq $piA)  # Floor подходит, достигнут текущий уровень точности, запоминание результатов
        {
            # $SolutionFound = $true
            
            $Solution.'x'    = $a
            
            if ($pi2 -ne $piAA) { $Solution.'PI'    = $piA + '_<' } else { $Solution.'PI'    = $piAA + '_<' }
        }
        
        
        $b = [System.Math]::Ceiling($i * $pi_decimal)    # вверхнее значение числителя-кандидата
        
        $piB = ([string]( [decimal]$b / [decimal]$i ))[0..($accuracy + 1)] -join ''
        
        $piBB = ([string]( [decimal]$b / [decimal]$i ))[0..($accuracy + 2)] -join ''
        
        if ($pi0 -eq $piB)  # Ceiling подходит, достигнут текущий уровень точности, запоминание результатов
        {
            # $SolutionFound = $true
            
            $Solution.'x'    = $b
            
            if ($pi2 -ne $piBB) { $Solution.'PI'    = $piB + '_>' } else { $Solution.'PI'    = $piBB + '_>' }
        }
        
        
        if ($pi2 -eq $piAA -or $pi2 -eq $piBB)
        {
            $Solution.'acr' = $accuracy + 1
            
        }
        
        return $Solution
    }
    
    #endregion: скрипт-блок задания, выполняемого в потоке
    
    
    #region: запуск задания и добавление потоков в пул
    
    # нужно извлечь из таблицы следующий y_max, соответстующий следующему уровню точности (если есть) или самомоу большому возможному y (если нет в таблице) и внутренний цикл делать до этого y_max
    for ($accuracy = $lim_min; $accuracy -le $lim_max; $accuracy++)
    {
        $pi0 = $pi_string[0..($accuracy + 1)] -join ''
        
        $pi2 = $pi_string[0..($accuracy + 2)] -join ''  # +1 точность, при котором прерывается поиск дроби текущей точности
        
        
        $ContinueWhileCycle = $true
        
        $k = 1
        
        while ($ContinueWhileCycle)
        {
            #region: инициализация пула
            
            $Pool = [RunspaceFactory]::CreateRunspacePool(1, [int] $env:NUMBER_OF_PROCESSORS * 30)
            
            $Pool.ApartmentState = "MTA"
            
            $Pool.Open()
            
            $RunSpaces = @()
            
            #endregion: инициализация пула
            
            
            
            $RangeStart = [decimal]($RecalcTable | Where-Object {$_.acr -eq $accuracy} | Select-Object -First 1).y + 120 * ($k - 1)
            
            $RangeEnd   = [decimal]($RecalcTable | Where-Object {$_.acr -eq $accuracy} | Select-Object -First 1).y + 120 * $k
            
            for ($i = $RangeStart; $i -lt $RangeEnd; $i++)
            {
                $NewShell = [PowerShell]::Create()
                
                $null = $NewShell.AddScript($Payload)
                
                $null = $NewShell.AddArgument($i)
                
                $null = $NewShell.AddArgument($accuracy)
                
                $null = $NewShell.AddArgument($pi0)
                
                $null = $NewShell.AddArgument($pi2)
                
                $null = $NewShell.AddArgument($pi_decimal)
                
                $NewShell.RunspacePool = $Pool
                
                $RunSpace = [PSCustomObject]@{ Pipe = $NewShell; Status = $NewShell.BeginInvoke() }
                
                $RunSpaces += $RunSpace
            }
            
            # Write-Host ("accuracy {0} `t runspaces count {1}" -f $accuracy, $RunSpaces.Count)
            
            
            foreach ($RS in $RunSpaces | Where-Object -FilterScript {$_.Status.IsCompleted -eq $true})  # цикл по завершённым
            {
                $Result = $RS.Pipe.EndInvoke($RS.Status)
                if ($Result[0].x)
                {
                    $Result[0].min = $WatchDogTimer.Elapsed.TotalMinutes
                    $Result[0].sec = $WatchDogTimer.Elapsed.TotalSeconds
                    $Result[0].tic = $WatchDogTimer.Elapsed.Ticks
                    
                    $RecalcTable += $Result[0]
                    
                    $RecalcTable | Export-Csv -NoTypeInformation -Encoding Unicode -Path ".\pi_all_$lim_max.csv" -Force  # сохранение результатов в csv-файл
                    
                    if ($Result[0].acr -gt $accuracy)  # NextLevelofAccuracy
                    {
                        $RecalcTable[-3..-1] | Format-Table -Property *  # вывод результатов на экран
                        
                        $ContinueWhileCycle = $false  # нужно тут прервать цикл while
                        
                        break
                    }
                }
            }
        
            #region: после завершения всех потоков закрываем пул
            
            $Pool.Close()
            
            $Pool.Dispose()
            
            $k++
            
            #endregion: после завершения всех потоков закрываем пул
        }
    }
    
    #endregion: запуск задания и добавление потоков в пул
    
    

#endregion Multi-Threading

$RecalcTable | Format-Table -Property *

# [decimal]::MaxValue / 3                               = 26409387504754779197847983445
# [decimal]::MaxValue / 3.1415926535897910113405412673  = 25219107392466377863196895290
