Clear-Host

$limit = 6  # точность, кол-во знаков после запятой

$x = @{}  # числители для заданной точности

$y = @{}  # знаменатели для заданной точности

$ResultsTable = @()  # таблица с дробями для точностей из диапазона 0..$limit

# поиск числителя и знаменателя
for ($digits = 0; $digits -le $limit; $digits++)
{
    for ($i = 1; $i -lt 1000; $i++)
    {
        for ($j = $i * 3; $j -lt $i * 4; $j++)  # между 3 и 4
        {
            $err = [System.Math]::Round( ($j/$i - [math]::pi), $digits, 1)
            if ($err -eq 0) { break }
        }
        
        if ($err -eq 0)
        {
            $x[$digits] = $j
            
            $y[$digits] = $i
            
            break
        }
    }
}

# формирование таблицы
for ($i = $limit; $i -ge 0; $i--)
{
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'  = '{0,4}' -f $i
        'DPOBb    ' = "{0,3} / {1,-3}" -f $x[$i], $y[$i]
        '         ' = '{0, 4}' -f '='
        '    ~    ' = "{0,-$($limit + 3):n$($i + 1)}" -f ([System.Math]::Round($x[$i] / $y[$i], $i + 1, 1))
        '    PI   ' = "{0,-$($limit + 3)}" -f ([System.Math]::Round([math]::pi, $i + 1, 1))
    }
}

# вывод таблицы на экран
$ResultsTable.GetEnumerator() | Sort-Object -Property 'TO4HOCTb' | Select-Object -Property `
    'TO4HOCTb', `
    'DPOBb    ', `
    '         ', `
    '    ~    ', `
    '    PI   ' | Format-Table -AutoSize

[math]::pi  # 3,14159265358979
