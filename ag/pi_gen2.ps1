[cmdletbinding()]
param(
    [alias('1')][Parameter(position=0)][uint16] $lim_min = 0,  # точность, кол-во знаков после запятой
    [alias('2')][Parameter(position=1)][uint16] $lim_max = 2  # точность, кол-во знаков после запятой
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование

Clear-Host


$x = [ordered]@{'0' = 3}  # числители для заданной точности

$y = [ordered]@{'0' = 1}  # знаменатели для заданной точности


$t_sec = [ordered]@{'0' = $WatchDogTimer.Elapsed.TotalSeconds}  # отсечка таймера

$t_min = [ordered]@{'0' = $WatchDogTimer.Elapsed.TotalMinutes}  # отсечка таймера

$ticks = [ordered]@{'0' = $WatchDogTimer.Elapsed.Ticks}  # отсечка таймера


$ResultsTable = @()  # таблица с дробями для точностей из диапазона $lim_min..$lim_max


# поиск числителя и знаменателя
for ($digits = 1; $digits -le $lim_max; $digits++)
{
    $i = $y[($digits - 1)]
    do
    # $c = 0
    # for ($i = $y[($digits - 1)]; $i -lt ([System.Math]::Ceiling($y[($digits - 1)] * [math]::pi)); $i++)
    {
        $a = [System.Math]::Floor($i * [math]::pi)      # вниз  до целого
        
        $b = [System.Math]::Ceiling($i * [math]::pi)    # вверх до целого
        
        for ($j = $a; $j -le $b; $j++)   # числитель в xPI раз больше знаменателя
        {
            # $err = [System.Math]::Round( ($j/$i - [math]::pi), $digits, 1)
            
            # $err = ( ([string](   $j / $i  ))[0..($digits + 1)] -join '' ) -ieq ( ([string]( [math]::pi ))[0..($digits + 1)] -join '' )
            
            $pi0 = ([string]( [math]::pi ))[0..($digits + 1)] -join ''
            
            $pi1 = ([string](   $j / $i  ))[0..($digits + 1)] -join ''
            
            $err = $pi0 -eq $pi1
            
            if ($err)
            {
                $x[[string]$digits] = $j
                
                break
            }
        }
        
        if ($err)
        {
            $y[[string]$digits] = $i
            
            $t_min[[string]$digits] = $WatchDogTimer.Elapsed.TotalMinutes
            
            $t_sec[[string]$digits] = $WatchDogTimer.Elapsed.TotalSeconds
            
            $ticks[[string]$digits] = $WatchDogTimer.Elapsed.Ticks
            
            # $c++
            break
        }
        
        # if ($i % 1000 -eq 0 ) { @{$digits = ($j, $i)} }
        
        $i++
    } while ($true)
}


# формирование таблицы
for ($i = $lim_min; $i -le $lim_max; $i++)
{
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'          = "{0,4}" -f $i
        '     4uc/\uTE/\b'  = "{0,16}" -f $x["$i"]
        '/'                 = '/'
        '3HAMEHATE/\b    '  = "{0,-16}" -f $y["$i"]
        'PI              '  = "{0}" -f (( [string]( $x["$i"] / $y["$i"]) )[0..($i + 1)] -join '')
        '         minutes'  = "{0,7:n0}  {1,7}" -f $t_min["$i"], 'minutes'
        '         seconds'  = "{0,7:n0}  {1,7}" -f $t_sec["$i"], 'seconds'
        '           ticks'  = "{0,16:n0}" -f $ticks["$i"]
    }
    
    $ResultsTable += New-Object psobject -Property @{
        'PI              ' = "{0}" -f (([string]( [math]::pi ))[0..($lim_max + 1)] -join '')
    }
    
    $ResultsTable += New-Object psobject -Property @{}
}


# вывод таблицы на экран

[math]::pi  # 3,14159265358979

$ResultsTable.GetEnumerator() | Select-Object -Property `
    'TO4HOCTb'          , `
    '     4uc/\uTE/\b'  , `
    '/'                 , `
    '3HAMEHATE/\b    '  , `
    'PI              '  , `
    '         minutes'  ,`
    '         seconds'  ,`
    '           ticks'  | Format-Table -Property *
<#
3,14159265358979

TO4HOCTb      4uc/\uTE/\b / 3HAMEHATE/\b     PI                        minutes          seconds            ticks
-------- ---------------- - ---------------- ---------------- ---------------- ---------------- ----------------
   0                    3 / 1                3                      0  minutes       0  seconds          304 810
                                             3.141592653589

   1                   19 / 6                3.1                    0  minutes       0  seconds          312 746
                                             3.141592653589

   2                   22 / 7                3.14                   0  minutes       0  seconds          315 788
                                             3.141592653589

   3                  245 / 78               3.141                  0  minutes       0  seconds          353 510
                                             3.141592653589

   4                  333 / 106              3.1415                 0  minutes       0  seconds          364 496
                                             3.141592653589

   5                  355 / 113              3.14159                0  minutes       0  seconds          367 145
                                             3.141592653589

   6                  355 / 113              3.141592               0  minutes       0  seconds          367 791
                                             3.141592653589

   7                86953 / 27678            3.1415926              0  minutes       1  seconds       13 245 581
                                             3.141592653589

   8               102928 / 32763            3.14159265             0  minutes       2  seconds       15 839 636
                                             3.141592653589

   9               103993 / 33102            3.141592653            0  minutes       2  seconds       16 050 972
                                             3.141592653589

  10               521030 / 165849           3.1415926535           0  minutes       9  seconds       94 751 832
                                             3.141592653589

  11               833719 / 265381           3.14159265358          0  minutes      16  seconds      157 094 240
                                             3.141592653589

  12              4272943 / 1360120          3.141592653589         1  minutes      89  seconds      889 778 570
                                             3.141592653589
#>