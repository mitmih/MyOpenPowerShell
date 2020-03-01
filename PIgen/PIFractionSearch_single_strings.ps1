[cmdletbinding()]
param(
    [alias('l')][Parameter(position=0)][ValidateRange(0, 27)][uint16] $lim_min = 4,  # нижняя граница точности, для которой нужно начать поиск дроби
    [alias('u')][Parameter(position=1)][ValidateRange(1, 28)][uint16] $lim_max = 6   # верхняя граница точности
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование

# Clear-Host  # для 18 знаков диапазон $i = 1068966896..1436411651 пуст  # 1436411651 * $pi_decimal  # 4512620290,3123859824087622839

function Update-Table {
    param ()
    
    
    
    # 
    return $null
}


$pi_string  = '3.1415926535897932384626433832'

$pi_decimal = [decimal] $pi_string

$table = @(
    <# 3, 1415926535893891715436873217 #> New-Object psobject -Property ([ordered] @{'acr' = 0;  'x' = 3; 'y' = 1})
    <# 3,1 666666666666666666666666667 #> New-Object psobject -Property ([ordered] @{'acr' = 1;  'x' = 19; 'y' = 6})
    <# 3,14 28571428571428571428571429 #> New-Object psobject -Property ([ordered] @{'acr' = 2;  'x' = 22; 'y' = 7})
    <# 3,141 0256410256410256410256410 #> New-Object psobject -Property ([ordered] @{'acr' = 3;  'x' = 245; 'y' = 78})
    <# 3,1415 094339622641509433962264 #> New-Object psobject -Property ([ordered] @{'acr' = 4;  'x' = 333; 'y' = 106})
    <# 3,14159 29203539823008849557522 #> New-Object psobject -Property ([ordered] @{'acr' = 5;  'x' = 355; 'y' = 113})
    <# 3,141592 9203539823008849557522 #> New-Object psobject -Property ([ordered] @{'acr' = 6;  'x' = 355; 'y' = 113})
    <# 3,1415926 006214321844063877448 #> New-Object psobject -Property ([ordered] @{'acr' = 7;  'x' = 86953; 'y' = 27678})
    <# 3,14159265 02457039953606202118 #> New-Object psobject -Property ([ordered] @{'acr' = 8;  'x' = 102928; 'y' = 32763})
    <# 3,141592653 0119026040722614948 #> New-Object psobject -Property ([ordered] @{'acr' = 9;  'x' = 103993; 'y' = 33102})
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


$table | Add-Member -MemberType NoteProperty -Name 'PI' -Value $null
$table | Add-Member -MemberType NoteProperty -Name 'min' -Value $null
$table | Add-Member -MemberType NoteProperty -Name 'sec' -Value $null
$table | Add-Member -MemberType NoteProperty -Name 'tic' -Value $null

$table[0].PI = '3.'

$lim_min = [System.Math]::Max(1, $lim_min)

$table = $table | Where-Object {$_.acr -le $lim_min}

# поиск дроби: проверка числителя-кандидата, знаменатель++
for ($accuracy = $lim_min; $accuracy -le $lim_max; $accuracy++)
{
    $i = $table[($table.Length - 1)].y
    
    $pi0 = $pi_string[0..($accuracy + 1)] -join ''
    
    $pi2 = $pi_string[0..($accuracy + 2)] -join ''  # +1 точность, при котором прерывается поиск дроби текущей точности
    
    do
    {
        $a = [System.Math]::Floor($i * $pi_decimal)      # нижнее значение числителя-кандидата
        
        $piA = ([string]( [decimal]$a / [decimal]$i ))[0..($accuracy + 1)] -join ''
        
        $piAA = ([string]( [decimal]$a / [decimal]$i ))[0..($accuracy + 2)] -join ''
        
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
            
            $table | Export-Csv -Force -NoTypeInformation -Encoding Unicode -Path ("$env:HOMEPATH\Downloads\{0} {1} all.csv" -f (Get-Item $MyInvocation.MyCommand.Source).BaseName, $lim_max)
            
            $table[-1] | Format-Table -Property *
            
            if ($pi2 -eq $piAA) { break } else { $i++ ; continue }
        }
        
        
        $b = [System.Math]::Ceiling($i * $pi_decimal)    # вверхнее значение числителя-кандидата
        
        $piB = ([string]( [decimal]$b / [decimal]$i ))[0..($accuracy + 1)] -join ''
        
        $piBB = ([string]( [decimal]$b / [decimal]$i ))[0..($accuracy + 2)] -join ''
        
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
            
            $table | Export-Csv -NoTypeInformation -Encoding Unicode -Path ".\pi_all_$lim_max.csv" -Force
            
            $table[-1] | Format-Table -Property *
            
            if ($pi2 -eq $piBB) { break } else { $i++ ; continue }
        }
        
        if ($i % 100001 -eq 0) { Write-Progress -Activity ("accuracy {1} / {0} digits" -f $lim_max, $accuracy) -PercentComplete ($i % 100) -Status ('{0:n0} minutes, last fraction {1:n0} / {2:n0} = {3}' -f $WatchDogTimer.Elapsed.TotalMinutes, $table[-1].x, $table[-1].y, $table[-1].PI) -CurrentOperation ('{0:n0}' -f $i)}
        
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


# вывод результатов на экран
$ResultsTable[-3..-1] | Format-Table -Property *



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
