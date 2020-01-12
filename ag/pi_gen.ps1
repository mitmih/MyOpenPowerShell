[cmdletbinding()]
param(
    [alias('1')][Parameter(position=0)][uint16] $lim_min = 0,  # точность, кол-во знаков после запятой
    [alias('2')][Parameter(position=1)][uint16] $lim_max = 2  # точность, кол-во знаков после запятой
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование

Clear-Host


$pi = '3.1415926535141592653526433832'

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
    {
        $a = [System.Math]::Floor($i * [math]::pi)      # вниз  до целого
        
        $b = [System.Math]::Ceiling($i * [math]::pi)    # вверх до целого
        
        for ($j = $a; $j -le $b; $j++)   # числитель в xPI раз больше знаменателя
        {
            $pi0 = $pi[0..($digits + 1)] -join ''
            
            $pi1 = ([string]( [decimal]$j / [decimal]$i ))[0..($digits + 1)] -join ''
            
            $err = $pi0 -eq $pi1
            
            if ($err) { break }
        }
        
        if ($err)
        {
            $x[[string]$digits] = $j
            
            $y[[string]$digits] = $i
            
            $t_min[[string]$digits] = $WatchDogTimer.Elapsed.TotalMinutes
            
            $t_sec[[string]$digits] = $WatchDogTimer.Elapsed.TotalSeconds
            
            $ticks[[string]$digits] = $WatchDogTimer.Elapsed.Ticks
            
            break
        }
        
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
   0                    3 / 1                3                      0  minutes       0  seconds          306 826
                                             3.14159265358979

   1                   19 / 6                3.1                    0  minutes       0  seconds          315 065
                                             3.14159265358979

   2                   22 / 7                3.14                   0  minutes       0  seconds          317 732
                                             3.14159265358979

   3                  245 / 78               3.141                  0  minutes       0  seconds          344 753
                                             3.14159265358979

   4                  333 / 106              3.1415                 0  minutes       0  seconds          360 735
                                             3.14159265358979

   5                  355 / 113              3.14159                0  minutes       0  seconds          363 729
                                             3.14159265358979

   6                  355 / 113              3.141592               0  minutes       0  seconds          364 143
                                             3.14159265358979

   7                86953 / 27678            3.1415926              0  minutes       1  seconds       13 036 415
                                             3.14159265358979

   8               102928 / 32763            3.14159265             0  minutes       2  seconds       15 528 828
                                             3.14159265358979

   9               103993 / 33102            3.141592653            0  minutes       2  seconds       15 708 169
                                             3.14159265358979

  10               521030 / 165849           3.1415926535           0  minutes       9  seconds       93 108 009
                                             3.14159265358979

  11               833719 / 265381           3.14159265358          0  minutes      16  seconds      156 813 657
                                             3.14159265358979

  12              4272943 / 1360120          3.141592653589         1  minutes      86  seconds      862 098 646
                                             3.14159265358979

  13             20530996 / 6535219          3.1415926535897        7  minutes     444  seconds    4 437 138 176
                                             3.14159265358979

  14             63885804 / 20335483         3.14159265358979      27  minutes   1 604  seconds   16 036 043 135
                                             3.14159265358979
#
20530996 / 6535219      3,1415926535 897_2667939 66659725
                        3,1415926535 897_9323846 2643383279 5028841971
63885804 / 20335483     3,1415926535 897_8687646 6125737

3,1415926535897266793966659725
#>
