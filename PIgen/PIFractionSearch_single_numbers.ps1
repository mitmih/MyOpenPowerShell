[cmdletbinding()]
param(
    [alias('u')][Parameter(position=0)][ValidateRange(1, 28)][uint16] $lim_max  = 28       # верхняя граница точности
)

$piString = '3.1415926535897932384626433832'
$piDecimal = [decimal] $piString
$accuracy = 0

$table = @()

$i = 1
do
{
    $skipA = $false
    
    $Floor = [System.Math]::Floor($i * $piDecimal)      # нижнее значение числителя-кандидата
    
    $mult = [decimal][System.Math]::Pow(10, ($accuracy + 0) )
    $piMult = [System.Math]::Truncate( $piDecimal * $mult )
    $piCalcMult = [System.Math]::Truncate( [decimal]$Floor / [decimal]$i * $mult )
    
    while ($piMult -eq $piCalcMult)
    {
        $skipA = $true
        
        $table += New-Object psobject -Property ([ordered]@{
            'acr'   = $accuracy
            'x'     = $Floor
            'y'     = $i
            'PI'    = ($piString[0..($accuracy + 1)] -join '') + '_<'  # ::Floor
            # 'min'   = $null
            # 'sec'   = $null
            # 'tic'   = $null
        })
        
        $accuracy++
        
        $mult = [decimal][System.Math]::Pow(10, ($accuracy + 0) )
        $piMult = [System.Math]::Truncate( $piDecimal * $mult )
        $piCalcMult = [System.Math]::Truncate( [decimal]$Floor / [decimal]$i * $mult )
    }
    
    if($skipA) { continue }
    
    
    $Ceiling = [System.Math]::Ceiling($i * $piDecimal)    # вверхнее значение числителя-кандидата
    
    $mult = [decimal][System.Math]::Pow(10, ($accuracy + 0) )
    $piMult = [System.Math]::Truncate( $piDecimal * $mult )
    $piCalcMult = [System.Math]::Truncate( [decimal]$Ceiling / [decimal]$i * $mult )
    
    while ($piMult -eq $piCalcMult)
    {
        $table += New-Object psobject -Property ([ordered]@{
            'acr'   = $accuracy
            'x'     = $Ceiling
            'y'     = $i
            'PI'    = ($piString[0..($accuracy + 1)] -join '') + '_>'  # ::Ceiling
            # 'min'   = $null
            # 'sec'   = $null
            # 'tic'   = $null
        })
        
        $accuracy++
        
        $mult = [decimal][System.Math]::Pow(10, ($accuracy + 0) )
        $piMult = [System.Math]::Truncate( $piDecimal * $mult )
        $piCalcMult = [System.Math]::Truncate( [decimal]$Ceiling / [decimal]$i * $mult )
    }
    
    $i++

} while ( ($table[-1]).acr -lt $lim_max )

$table | Export-Csv -Force -NoTypeInformation -Encoding Unicode -Path ("$env:HOMEPATH\Downloads\{0} {1} x{2} {3} all.csv" -f (Get-Item $MyInvocation.MyCommand.Source).BaseName, $lim_max, $x, $delta)  # сохранение результатов в csv-файл