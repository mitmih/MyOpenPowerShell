[cmdletbinding()]
param(
    [alias('1')][Parameter(position=0)][uint16] $lim_min = 0,  # точность, кол-во знаков после запятой
    [alias('2')][Parameter(position=1)][uint16] $lim_max = 4  # точность, кол-во знаков после запятой
)


Clear-Host

# $lim_max = 5  # точность, кол-во знаков после запятой

$x = [ordered]@{}  # числители для заданной точности

$y = [ordered]@{}  # знаменатели для заданной точности

$ResultsTable = @()  # таблица с дробями для точностей из диапазона $lim_min..$lim_max

# поиск числителя и знаменателя
for ($digits = 0; $digits -le $lim_max; $digits++)
{
    # for ($i = $y[($digits - 1)]; $i -lt $b; $i++)
    $i = $y[($digits - 1)]
    do
    {
        $a = [System.Math]::Round($i * [math]::pi, 0, 1) - 1
        
        $b = [System.Math]::Round($i * [math]::pi, 0, 1) + 1
        
        for ($j = $a; $j -le $b; $j++)   # между xPI - 1 и xPI + 1
        {
                $err = [System.Math]::Round( ($j/$i - [math]::pi), $digits, 1)
            
            if ($err -eq 0)
            {
                $x[[string]$digits] = $j
                
                break
            }
        }
        
        if ($err -eq 0)
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
        '    PI   ' = "{0,-$($lim_max + 3):n$($i + 1)}" -f ([System.Math]::Round($x["$i"] / $y["$i"], $i + 1, 1))
    }
    
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'  = "{0,$w} " -f $i
        '  DPOBb  ' = ''
        '    PI   ' = "{0,-$($lim_max + 3):n$($i + 1)}" -f ([System.Math]::Round([math]::pi, $i + 1, 1))
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
