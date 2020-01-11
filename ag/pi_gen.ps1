Clear-Host

$limit = 6  # кол-во знаков после запятой

$x = @{}  # числители для заданной точности

$y = @{}  # знаменатели для заданной точности

$ResultsTable = @()  # дроби для всех точностей в диапазоне 0..$limit

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

for ($i = $limit; $i -ge 0; $i--)
{
    $ResultsTable += New-Object psobject -Property @{
        'TO4HOCTb'  = '{0,4}' -f $i
        'DPOBb    ' = "{0,3} / {1,-3}" -f $x[$i], $y[$i]
        '         ' = '{0, 4}' -f '='
        '    ~    ' = "{0,-$($limit + 3):n$($i + 1)}" -f ([System.Math]::Round($x[$i] / $y[$i], $i + 1, 1))
        '    PI   ' = "{0,-$($limit + 3)}" -f ([System.Math]::Round([math]::pi, $i + 1, 1))
    }
    # $ResultsTable[$i] = "{0,$($limit / 2)} / {1,-$($limit / 2)} = {2,-$($limit + 3):n$($i+1)} vs {3:n$($i + 1)}" -f $x[$i], $y[$i], ([System.Math]::Round($x[$i] / $y[$i], $i + 1, 1)), ([System.Math]::Round([math]::pi, $i + 1, 1))
}

$ResultsTable.GetEnumerator() | Sort-Object -Property 'TO4HOCTb' | Select-Object -Property `
    'TO4HOCTb', `
    'DPOBb    ', `
    '         ', `
    '    ~    ', `
    '    PI   ' | Format-Table -AutoSize
