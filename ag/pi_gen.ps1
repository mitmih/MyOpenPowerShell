[cmdletbinding()]
param(
    [alias('1')][Parameter(position=0)][uint16] $lim_min = 0,  # точность, кол-во знаков после запятой
    [alias('2')][Parameter(position=1)][uint16] $lim_max = 2  # точность, кол-во знаков после запятой
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование

Clear-Host


$pi_string  = '3.1415926535897932384626433832'

$pi_decimal = [decimal] $pi_string

$table = @()

$table += New-Object psobject -Property ([ordered]@{
    'acr'   = 0
    'x'     = 3
    'y'     = 1
    'PI'    = '3.0'
    'min'   = $WatchDogTimer.Elapsed.TotalMinutes
    'sec'   = $WatchDogTimer.Elapsed.TotalSeconds
    'tic'   = $WatchDogTimer.Elapsed.Ticks
})


# поиск числителя и знаменателя
for ($digits = 1; $digits -le $lim_max; $digits++)
{
    $i = $table[($digits - 1)].'y'
    
    do
    {
        $a = [System.Math]::Floor($i * $pi_decimal)      # вниз  до целого
        
        $b = [System.Math]::Ceiling($i * $pi_decimal)    # вверх до целого
        
        for ($j = $a; $j -le $b; $j++)   # числитель в xPI раз больше знаменателя
        {
            $pi0 = $pi_string[0..($digits + 1)] -join ''
            
            $pi1 = ([string]( [decimal]$j / [decimal]$i ))[0..($digits + 1)] -join ''
            
            $err = $pi0 -eq $pi1
            
            if ($err) { break }
        }
        
        if ($err)
        {
            $table += New-Object psobject -Property ([ordered]@{
                'acr'   = $digits
                'x'     = $j
                'y'     = $i
                'PI'    = $pi1
                'min'   = $WatchDogTimer.Elapsed.TotalMinutes
                'sec'   = $WatchDogTimer.Elapsed.TotalSeconds
                'tic'   = $WatchDogTimer.Elapsed.Ticks
            })
            
            break
        }
        
        $i++
        
    } while ($true)
}


# формирование таблицы
$ResultsTable = @()  # таблица с дробями для точностей из диапазона $lim_min..$lim_max
foreach ($r in $table)
{
    $ResultsTable += New-Object psobject -Property ([ordered]@{
        'TO4HOCTb'          = "{0,4}" -f $r.acr
        ' 4uc/\uTE/\b'      = "{0,12}" -f $r.x
        ' '                 = '/'
        '3HAMEHATE/\b'      = "{0,-12}" -f $r.y
        'PI             '   = "{0}" -f $r.'PI'
        ' minutes'          = "{0,4:n0} {1}" -f $r.min, 'min'
        '   seconds' = "{0,6:n0} {1}" -f $r.sec, 'sec'
        '           ticks'  = "{0,16:n0}" -f $r.tic
    })
    
    $ResultsTable += New-Object psobject -Property ([ordered]@{
        'PI             '  = "{0}" -f ( $pi_string[0..($lim_max + 1)] -join '' )
    })
    
    $ResultsTable += New-Object psobject -Property ([ordered]@{})
}


# вывод таблицы на экран
# $ResultsTable | Set-Content -Path ".\pi_$lim_max.txt" -Force
$ResultsTable | Export-Csv -NoTypeInformation -Encoding Unicode -Path ".\pi_$lim_max.csv" -Force
$ResultsTable | Format-Table -Property *


<#
TO4HOCTb  4uc/\uTE/\b   3HAMEHATE/\b PI               minutes    seconds            ticks
-------- ------------ - ------------ --------------- -------- ---------- ----------------
   0                3 / 1            3.0                0 min      0 sec          330 785
                                     3.1415926535897

   1               19 / 6            3.1                0 min      0 sec          340 875
                                     3.1415926535897

   2               22 / 7            3.14               0 min      0 sec          344 742
                                     3.1415926535897

   3              245 / 78           3.141              0 min      0 sec          382 486
                                     3.1415926535897

   4              333 / 106          3.1415             0 min      0 sec          395 170
                                     3.1415926535897

   5              355 / 113          3.14159            0 min      0 sec          399 162
                                     3.1415926535897

   6              355 / 113          3.141592           0 min      0 sec          400 522
                                     3.1415926535897

   7            86953 / 27678        3.1415926          0 min      1 sec       12 463 682
                                     3.1415926535897

   8           102928 / 32763        3.14159265         0 min      1 sec       14 869 175
                                     3.1415926535897

   9           103993 / 33102        3.141592653        0 min      2 sec       15 045 325
                                     3.1415926535897

  10           521030 / 165849       3.1415926535       0 min      9 sec       87 134 294
                                     3.1415926535897

  11           833719 / 265381       3.14159265358      0 min     14 sec      144 238 319
                                     3.1415926535897

  12          4272943 / 1360120      3.141592653589     1 min     82 sec      815 108 829
                                     3.1415926535897

  13         20530996 / 6535219      3.1415926535897    7 min    420 sec    4 198 036 806
                                     3.1415926535897

#
???
  14             63885804 / 20335483         3.14159265358979      27  minutes   1 604  seconds   16 036 043 135
                                             3.14159265358979
20530996 / 6535219      3,1415926535 897_2667939 66659725
                        3,1415926535 897_9323846 2643383279 5028841971
63885804 / 20335483     3,1415926535 897_8687646 6125737

3,1415926535897266793966659725
#>
