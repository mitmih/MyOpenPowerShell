[cmdletbinding()]
param(
    [alias('u')][Parameter(position=0)][ValidateRange(1, 28)][uint16] $lim_max  = 11       # верхняя граница точности
)

$piString = '3.1415926535897932384626433832'
$piDecimal = [decimal] $piString
$accuracy = 0

$table = @()

# for ($i = 1; $i -lt 50000; $i++)
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

$table | Export-Csv -NoTypeInformation -Encoding Unicode -Force <# -Delimiter "`t" #> -Path "$env:HOMEPATH\Downloads\table.csv"