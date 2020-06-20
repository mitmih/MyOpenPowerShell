Clear-Host

Import-Module -Force ('{0}\{1}' -f ($MyInvocation.MyCommand.Definition | Split-Path -Parent), '01_BinarySearch.psm1')

$lim = 7

$ShiftPredict = 0 ; do { $ShiftPredict++ } until ((1 -shl $ShiftPredict) -gt $lim)

"Search-Binary    {2}{3}`treal '{1}' vs '{0}' max" -f $ShiftPredict, (Search-Binary (0..$lim) ($lim + 1)), ($lim + 1), " in (0..$lim)"
$ht3 = @{} ; <# (Measure-Command { #>
    $lim..0 | ForEach-Object {
        $ShiftReal = Search-Binary (0..$lim) $_
        
        if ($null -eq $ht3[$ShiftReal])
        {
            $ht3[$ShiftReal] = @($_)
        }
        else
        {
            $ht3[$ShiftReal] += $_
        }
    }
<# }).TotalMilliseconds #>
$ht3 | Sort-Object -Property Name

"`nSearch-GRKBinary {2}`treal '{1}' vs '{0}' max" -f $ShiftPredict, (Search-GRKBinary (0..$lim) (1)), "1 in (0..$lim)"
$ht3 = @{} ; <# (Measure-Command { #>
    $lim..0 | ForEach-Object {
        $ShiftReal = Search-GRKBinary (0..$lim) $_
        
        if ($null -eq $ht3[$ShiftReal])
        {
            $ht3[$ShiftReal] = @($_)
        }
        else
        {
            $ht3[$ShiftReal] += $_
        }
    }
<# }).TotalMilliseconds #>
$ht3 | Sort-Object -Property Name