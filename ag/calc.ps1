[cmdletbinding()]
param(
    [Parameter(Mandatory=$true,position=0)]
    [string] $a = $null,

    [Parameter(Mandatory=$true,position=1)]
    [string] $op = $null,

    [Parameter(Mandatory=$true,position=2)]
    [string] $b = $null

)


if ($null -eq $a)  { $a  = Read-Host }  # get 1st number

if ($null -eq $op) { $op = Read-Host }  # get operation

if ($null -eq $b)  { $b  = Read-Host }  # get 2nd number

# [decimal]::MinValue
# [decimal]::MaxValue

try { [decimal]$a = $a }
catch { Write-Host '$a is not a number' ; break }

try { [decimal]$b = $b }
catch { Write-Host '$b is not a number' ; break }

if ( $op -notin @('+', '-', '*', '/') )
{
    Write-Host "$op is not an operator"
    break
}

switch ($op)
{
    {$_ -eq '+'} { $c = $a + $b ; break }
    
    {$_ -eq '-'} { $c = $a - $b ; break }
    
    {$_ -eq '*'} { $c = $a * $b ; break }
    
    {$_ -eq '/'} { $c = $a / $b ; break }
    
    # Default {Write-Host 'ooopps...' ; break}
}

$l = ([string]$c).Length

Write-Host ( "{0,$l}`n{1,-$l}`n{2,$l}`n{3}`n{4,$l}" -f $a, $op, $b,('_' * $l), $c )
