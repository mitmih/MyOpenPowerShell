Clear-Host
$tests = [ordered] @{  # inp=to
    '10.101.40.256/ 22'  = -1
    '10.101.40.256/21 22' = -1
    '10.101.40.256/21 -22' = -1
    '10.101.400.25/21 22' = 22
    
    '10.101.40.255/21 23'= 22
    '10.101.40.255/21 19' = 20
}

foreach($t in $tests.GetEnumerator())
{
    if ($t.Value)
    {
        $t.key | Get-Networks -v -to $t.Value | Format-Table *
    }
    else
    {
        $t.key | Get-Networks -v | Format-Table *
    }
}