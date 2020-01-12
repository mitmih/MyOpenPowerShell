[cmdletbinding()]
param(
    [alias('1')][Parameter(position=0)][uint16] $lim_min = 0,  # точность, кол-во знаков после запятой
    [alias('2')][Parameter(position=1)][uint16] $lim_max = 3  # точность, кол-во знаков после запятой
)


function qwe {
    param (
        [string]    $str,
        [int]       $t
    )
    
    return ( (([string]( [math]::pi ))[0..($t + 1)] -join '') -eq $str )
}

Clear-Host

# $lim_max = 5  # точность, кол-во знаков после запятой

$x = [ordered]@{'0' = 3}  # числители для заданной точности

$y = [ordered]@{'0' = 1}  # знаменатели для заданной точности

$ResultsTable = @()  # таблица с дробями для точностей из диапазона $lim_min..$lim_max

# поиск числителя и знаменателя
for ($digits = 1; $digits -le $lim_max; $digits++)
{
    # for ($i = $y[($digits - 1)]; $i -lt $b; $i++)
    $i = $y[($digits - 1)]
    do
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
            
            break
        }
        
        # if ($i % 1000 -eq 0 ) { @{$digits = ($j, $i)} }
        
        $i++
    }  while ($true)
}


# формирование таблицы
[int] $w = (([string]$x["$lim_max"] + [string]$y["$lim_max"]).Length + 3) / 2
for ($i = $lim_max; $i -ge $lim_min; $i--)
{
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'  = "{0,$w}" -f $i
        '  DPOBb  ' = "{0,$w} / {1,-$w}" -f $x["$i"], $y["$i"]
        '    PI   ' = "{0}" -f (( [string]( $x["$i"] / $y["$i"]) )[0..($i + 1)] -join '')
    }
    
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'  = "{0,$w} " -f $i
        '  DPOBb  ' = ''
        '    PI   ' = "{0}" -f (([string]( [math]::pi ))[0..($i + 1)] -join '')
    }
    
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'  = "{0,$w}  " -f $i
        '  DPOBb  ' = ''
        '    PI   ' = ''
    }
}


# вывод таблицы на экран

[math]::pi  # 3,14159265358979

$ResultsTable.GetEnumerator() | Sort-Object -Property 'TO4HOCTb' | Select-Object -Property `
    'TO4HOCTb', `
    '  DPOBb  ', `
    '    PI   ' | Format-Table -Property *
