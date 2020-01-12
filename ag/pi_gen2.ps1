[cmdletbinding()]
param(
    [alias('1')][Parameter(position=0)][uint16] $lim_min = 0,  # точность, кол-во знаков после запятой
    
    [alias('2')][Parameter(position=1)][uint16] $lim_max = 2  # точность, кол-во знаков после запятой
)


$WatchDogTimer = [system.diagnostics.stopwatch]::startNew()  # профилирование

Clear-Host


$c = 0  # счётчик найденных дробей

$x = [ordered]@{'0' = 3}  # числители дробей

$y = [ordered]@{'0' = 1}  # знаменатели дробей


$t_sec = [ordered]@{'0' = $WatchDogTimer.Elapsed.TotalSeconds}  # отсечка таймера

$t_min = [ordered]@{'0' = $WatchDogTimer.Elapsed.TotalMinutes}  # отсечка таймера

$ticks = [ordered]@{'0' = $WatchDogTimer.Elapsed.Ticks}  # отсечка таймера

$res = [ordered]@{
    "$c" = @()
}

# 14 63885804 / 20335483

# поиск числителя и знаменателя
for ($digits = 1; $digits -le $lim_max; $digits++)
{
    $a = [System.Math]::Floor($i * [math]::pi)      # вниз  до целого
    
    $b = [System.Math]::Ceiling($i * [math]::pi)    # вверх до целого
    
    for ($i = $y[($digits - 1)]; $i -lt ([System.Math]::Ceiling($y[($digits - 1)] * [math]::pi)); $i++)
    {
        $a = [System.Math]::Floor($i * [math]::pi)      # вниз  до целого
        
        $b = [System.Math]::Ceiling($i * [math]::pi)    # вверх до целого
        
        for ($j = $a; $j -le $b; $j++)   # числитель в xPI раз больше знаменателя
        {
            $pi0 = ([string]( [math]::pi ))[0..($digits + 1)] -join ''
            
            $pi1 = ([string](   $j / $i  ))[0..($digits + 1)] -join ''
            
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
            
            $c++
            # break
        }
    }
}


# формирование таблицы
$ResultsTable = @()  # таблица с дробями для точностей из диапазона $lim_min..$lim_max
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
#>