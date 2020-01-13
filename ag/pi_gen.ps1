[cmdletbinding()]
param(
    [alias('1')][Parameter(position=0)][uint16] $lim_min = 0,  # точность, кол-во знаков после запятой
    [alias('2')][Parameter(position=1)][uint16] $lim_max = 2  # точность, кол-во знаков после запятой
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование

# Clear-Host


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
$table | Export-Csv -NoTypeInformation -Encoding Unicode -Path ".\pi_$lim_max.csv" -Force
$ResultsTable | Format-Table -Property *


<#
TO4HOCTb  4uc/\uTE/\b   3HAMEHATE/\b PI                 minutes    seconds            ticks
-------- ------------ - ------------ ---------------   -------- ---------- ----------------
   0                3 / 1            3.0                  0 min      0 sec              240
                                     3.141592653589793

   1               19 / 6            3.1                  0 min      0 sec           10 031
                                     3.141592653589793

   2               22 / 7            3.14                 0 min      0 sec           16 506
                                     3.141592653589793

   3              245 / 78           3.141                0 min      0 sec           70 453
                                     3.141592653589793

   4              333 / 106          3.1415               0 min      0 sec           87 234
                                     3.141592653589793

   5              355 / 113          3.14159              0 min      0 sec           93 013
                                     3.141592653589793

   6              355 / 113          3.141592             0 min      0 sec           94 820
                                     3.141592653589793

   7            86953 / 27678        3.1415926            0 min      1 sec       12 836 826
                                     3.141592653589793

   8           102928 / 32763        3.14159265           0 min      2 sec       15 326 071
                                     3.141592653589793

   9           103993 / 33102        3.141592653          0 min      2 sec       15 502 694
                                     3.141592653589793

  10           521030 / 165849       3.1415926535         0 min      9 sec       90 929 572
                                     3.141592653589793

  11           833719 / 265381       3.14159265358        0 min     15 sec      151 671 668
                                     3.141592653589793

  12          4272943 / 1360120      3.141592653589       1 min     86 sec      856 361 711
                                     3.141592653589793

  13         20530996 / 6535219      3.1415926535897      7 min    439 sec    4 389 148 333
                                     3.141592653589793

  14         74724506 / 23785549     3.14159265358979    27 min  1 648 sec   16 483 989 572
                                     3.141592653589793

  15        165707065 / 52746197     3.141592653589793   64 min  3 818 sec   38 177 668 229
                                     3.141592653589793
#

3,1415926535897932384626433832

#>
