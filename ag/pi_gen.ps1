[cmdletbinding()]
param(
    [alias('l')][Parameter(position=0)][ValidateRange(0, 27)][uint16] $lim_min = 2,  # нижняя граница точности, для которой нужно начать поиск дроби
    [alias('u')][Parameter(position=1)][ValidateRange(1, 28)][uint16] $lim_max = 6   # верхняя граница точности
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование

# Clear-Host  # $i = 1265266261


$pi_string  = '3.1415926535897932384626433832'

$pi_decimal = [decimal] $pi_string

$table = @(
    New-Object psobject -Property ([ordered] @{'acr' = 0; 'x' = 3; 'y' = 1})
    New-Object psobject -Property ([ordered] @{'acr' = 1; 'x' = 19; 'y' = 6})
    New-Object psobject -Property ([ordered] @{'acr' = 2; 'x' = 22; 'y' = 7})
    New-Object psobject -Property ([ordered] @{'acr' = 3; 'x' = 245; 'y' = 78})
    New-Object psobject -Property ([ordered] @{'acr' = 4; 'x' = 333; 'y' = 106})
    New-Object psobject -Property ([ordered] @{'acr' = 5; 'x' = 355; 'y' = 113})
    New-Object psobject -Property ([ordered] @{'acr' = 6; 'x' = 355; 'y' = 113})
    New-Object psobject -Property ([ordered] @{'acr' = 7; 'x' = 86953; 'y' = 27678})
    New-Object psobject -Property ([ordered] @{'acr' = 8; 'x' = 102928; 'y' = 32763})
    New-Object psobject -Property ([ordered] @{'acr' = 9; 'x' = 103993; 'y' = 33102})
    New-Object psobject -Property ([ordered] @{'acr' = 10; 'x' = 521030; 'y' = 165849})
    New-Object psobject -Property ([ordered] @{'acr' = 11; 'x' = 833719; 'y' = 265381})
    New-Object psobject -Property ([ordered] @{'acr' = 12; 'x' = 4272943; 'y' = 1360120})
    New-Object psobject -Property ([ordered] @{'acr' = 13; 'x' = 20530996; 'y' = 6535219})
    New-Object psobject -Property ([ordered] @{'acr' = 14; 'x' = 74724506; 'y' = 23785549})
    New-Object psobject -Property ([ordered] @{'acr' = 15; 'x' = 165707065; 'y' = 52746197})
    New-Object psobject -Property ([ordered] @{'acr' = 16; 'x' = 411557987; 'y' = 131002976})
    New-Object psobject -Property ([ordered] @{'acr' = 17; 'x' = 1068966896; 'y' = 340262731})
)

$table | Add-Member -MemberType NoteProperty -Name 'PI' -Value $null
$table | Add-Member -MemberType NoteProperty -Name 'min' -Value $null
$table | Add-Member -MemberType NoteProperty -Name 'sec' -Value $null
$table | Add-Member -MemberType NoteProperty -Name 'tic' -Value $null

$table[0].PI = '3.'

$lim_min = [System.Math]::Max(1, $lim_min)

$table = $table[0..($lim_min - 1)]

# поиск дроби: проверка числителя-кандидата, знаменатель++
for ($accuracy = $lim_min; $accuracy -le $lim_max; $accuracy++)
{
    $i = $table[($accuracy - 1)].'y'
    
    $acr = $accuracy + 1
    
    $pi0 = $pi_string[0..$acr] -join ''
    
    do
    {
        $a = [System.Math]::Floor($i * $pi_decimal)      # нижнее значение числителя-кандидата
        
        $piA = ([string]( [decimal]$a / [decimal]$i ))[0..$acr] -join ''
        
        if ($pi0 -eq $piA)  # -or $pi0 -ne $piB)
        # Floor подходит, достигнут текущий уровень точности, запоминание результатов
        {
            $table += New-Object psobject -Property ([ordered]@{
                'acr'   = $accuracy
                'x'     = $a
                'y'     = $i
                'PI'    = $piA + '_<'  # ::Floor
                'min'   = $WatchDogTimer.Elapsed.TotalMinutes
                'sec'   = $WatchDogTimer.Elapsed.TotalSeconds
                'tic'   = $WatchDogTimer.Elapsed.Ticks
            })
            
            break
        }
        
        
        $b = [System.Math]::Ceiling($i * $pi_decimal)    # вверхнее значение числителя-кандидата
        
        $piB = ([string]( [decimal]$b / [decimal]$i ))[0..$acr] -join ''
        
        if ($pi0 -eq $piB)  # -or $pi0 -ne $piB)
        # Ceiling подходит, достигнут текущий уровень точности, запоминание результатов
        {
            $table += New-Object psobject -Property ([ordered]@{
                'acr'   = $accuracy
                'x'     = $b
                'y'     = $i
                'PI'    = $piB + '_>'  # ::Ceiling
                'min'   = $WatchDogTimer.Elapsed.TotalMinutes
                'sec'   = $WatchDogTimer.Elapsed.TotalSeconds
                'tic'   = $WatchDogTimer.Elapsed.Ticks
            })
            
            break
        }
        
        if ($i % 100001 -eq 0) { Write-Progress -Activity $i -PercentComplete ($i % 100) -Status $WatchDogTimer.Elapsed.TotalMinutes }
        
        $i++
        
        continue
    }
    while ($true)
}


# формирование таблицы
$ResultsTable = @()  # таблица с дробями для точностей из диапазона $lim_min..$lim_max
foreach ($r in $table)
{
    $ResultsTable += New-Object psobject -Property ([ordered]@{
        'TO4HOCTb'                  = "{0,4}" -f $r.acr
        ' 4uc/\uTE/\b'              = "{0,12}" -f $r.x
        ' '                         = '/'
        '3HAMEHATE/\b'              = "{0,-12}" -f $r.y
        'PI                     '   = "{0}" -f $r.'PI'
        '         minutes'          = "{0,12:n0} {1}" -f $r.min, 'min'
        '         seconds'          = "{0,12:n0} {1}" -f $r.sec, 'sec'
        '                  ticks'   = "{0,23:n0}" -f $r.tic
    })
    
    $ResultsTable += New-Object psobject -Property ([ordered]@{
        'PI                     '  = "{0}" -f ( $pi_string[0..($lim_max + 1)] -join '' )
    })
    
    $ResultsTable += New-Object psobject -Property ([ordered]@{})
}


# сохранение результатов в csv-файл
$table | Export-Csv -NoTypeInformation -Encoding Unicode -Path ".\pi_$lim_max.csv" -Force

# вывод результатов на экран
$ResultsTable | Format-Table -Property *



<#
TO4HOCTb  4uc/\uTE/\b   3HAMEHATE/\b PI                   minutes    seconds            ticks
-------- ------------ - ------------ ---------------     -------- ---------- ----------------
   0                3 / 1            3.0                    0 min      0 sec              274
                                     3.14159265358979323

   1               19 / 6            3.1                    0 min      0 sec            9 972
                                     3.14159265358979323

   2               22 / 7            3.14                   0 min      0 sec           14 292
                                     3.14159265358979323

   3              245 / 78           3.141                  0 min      0 sec           50 102
                                     3.14159265358979323

   4              333 / 106          3.1415                 0 min      0 sec           66 213
                                     3.14159265358979323

   5              355 / 113          3.14159                0 min      0 sec           71 870
                                     3.14159265358979323

   6              355 / 113          3.141592               0 min      0 sec           82 837
                                     3.14159265358979323

   7            86953 / 27678        3.1415926              0 min      1 sec       12 751 722
                                     3.14159265358979323

   8           102928 / 32763        3.14159265             0 min      2 sec       15 244 395
                                     3.14159265358979323

   9           103993 / 33102        3.141592653            0 min      2 sec       15 423 598
                                     3.14159265358979323

  10           521030 / 165849       3.1415926535           0 min      9 sec       91 215 774
                                     3.14159265358979323

  11           833719 / 265381       3.14159265358          0 min     15 sec      152 322 050
                                     3.14159265358979323

  12          4272943 / 1360120      3.141592653589         1 min     86 sec      861 445 660
                                     3.14159265358979323

  13         20530996 / 6535219      3.1415926535897        7 min    441 sec    4 414 140 536
                                     3.14159265358979323

  14         74724506 / 23785549     3.14159265358979      28 min  1 696 sec   16 959 433 993
                                     3.14159265358979323

  15        165707065 / 52746197     3.141592653589793     65 min  3 927 sec   39 273 301 294
                                     3.14159265358979323

  16        411557987 / 131002976    3.1415926535897932   171 min 10 282 sec  102 818 445 340
                                     3.14159265358979323

  17       1068966896 / 340262731    3.14159265358979323  444 min 26 628 sec  266 279 631 730
                                     3.14159265358979323
#
                                     3,1415926535897932384626433832
#>
