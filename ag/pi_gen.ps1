[cmdletbinding()]
param(
    [alias('1')][Parameter(position=0)][uint16] $lim_min = 0,  # точность, кол-во знаков после запятой
    [alias('2')][Parameter(position=1)][uint16] $lim_max = 2  # точность, кол-во знаков после запятой
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование

Clear-Host


$x = [ordered]@{'0' = 3}  # числители для заданной точности

$y = [ordered]@{'0' = 1}  # знаменатели для заданной точности

$t = [ordered]@{'0' = $WatchDogTimer.Elapsed.TotalSeconds}  # отсечка таймера

$ResultsTable = @()  # таблица с дробями для точностей из диапазона $lim_min..$lim_max


# поиск числителя и знаменателя
for ($digits = 1; $digits -le $lim_max; $digits++)
{
    $i = $y[($digits - 1)]
    do
    # for ($i = $y[($digits - 1)]; $i -lt $b; $i++)
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
            
            $t[[string]$digits] = $WatchDogTimer.Elapsed.TotalSeconds
            
            break
        }
        
        # if ($i % 1000 -eq 0 ) { @{$digits = ($j, $i)} }
        
        $i++
    } while ($true)
}


# формирование таблицы
[int] $w = (([string]$x["$lim_max"] + [string]$y["$lim_max"]).Length + 3) / 2
for ($i = $lim_max; $i -ge $lim_min; $i--)
{
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'          = "{0,$w}" -f $i
        '   4uc/\uTE/\b  '  = "{0,16}" -f $x["$i"]
        '/'                 = '/'
        '  3HAMEHATE/\b  '  = "{0,-16}" -f $y["$i"]
        '    PI   ' = "{0}" -f (( [string]( $x["$i"] / $y["$i"]) )[0..($i + 1)] -join '')
        '      time      ' = "{0,7:n1}  {1,7}" -f $t["$i"], 'seconds'
        # Write-Host ("{0,5:N1} minutes {1}" -f $WatchDogTimer.Elapsed.TotalMinutes, 'installation process launched') #_#
    }
    
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'  = "{0,$w} " -f $i
        '    PI   ' = "{0}" -f (([string]( [math]::pi ))[0..($i + 1)] -join '')
    }
    
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'  = "{0,$w}  " -f $i
        '    PI   ' = ''
    }
}


# вывод таблицы на экран

[math]::pi  # 3,14159265358979

$ResultsTable.GetEnumerator() | Sort-Object -Property 'TO4HOCTb' | Select-Object -Property `
    'TO4HOCTb'          , `
    '   4uc/\uTE/\b  '  , `
    '/'                 , `
    '  3HAMEHATE/\b  '  , `
    '    PI   '         , `
    '      time      '  | Format-Table -Property *
<#
3,14159265358979

TO4HOCTb        4uc/\uTE/\b   /   3HAMEHATE/\b       PI
--------     ---------------- - ---------------- ---------
         0                  3 / 1                3
         0                                       3.
         0
         1                 19 / 6                3.1
         1                                       3.1
         1
         2                 22 / 7                3.14
         2                                       3.14
         2
         3                245 / 78               3.141
         3                                       3.141
         3
         4                333 / 106              3.1415
         4                                       3.1415
         4
         5                355 / 113              3.14159
         5                                       3.14159
         5
         6                355 / 113              3.141592
         6                                       3.141592
         6
         7              86953 / 27678            3.1415926
         7                                       3.1415926
         7
         8             102928 / 32763            3.14159265
         8                                       3.14159265
         8
         9             103993 / 33102            3.141592653
         9                                       3.141592653
         9
        10             521030 / 165849           3.1415926535
        10                                       3.1415926535
        10
        11             833719 / 265381           3.14159265358
        11                                       3.14159265358
        11
        12            4272943 / 1360120          3.141592653589
        12                                       3.141592653589
        12
        13           20530996 / 6535219          3.1415926535897
        13                                       3.1415926535897
        13
        14           63885804 / 20335483         3.14159265358979
        14                                       3.14159265358979
#>