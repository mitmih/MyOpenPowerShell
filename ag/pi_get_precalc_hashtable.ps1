# $MyInvocation.MyCommand.Name

$csv = Import-Csv -Path "$env:USERPROFILE\downloads\pi_17.csv"

foreach ($r in $csv)
{
    # $a = "'acr' = {0}; 'x' = {1}; 'y' = {2}; 'PI' = {3}; 'min' = {4}; 'sec' = {5}; 'tic' = {6}" -f $r.acr, $r.x, $r.y, $r.PI, $r.min, $r.sec, $r.tic
    $a = "'acr' = {0}; 'x' = {1}; 'y' = {2}" -f $r.acr, $r.x, $r.y
    $b = 'New-Object psobject -Property ([ordered] @{' + $a +'})'
    $b | Out-File -FilePath "$env:USERPROFILE\downloads\pi_17.txt" -Append
}
