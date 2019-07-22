# $ht.GetEnumerator() | Sort-Object {Get-Random}

$keys = @()
foreach ($suit in @('+', '#', '*', '^'))
{
    $keys += @('A') + 2..10 + @('J', 'Q', 'K') | ForEach-Object {
        if ($_.ToString().Length -lt 2) {$_.ToString() + ' ' + $suit} else {$_.ToString() + '' + $suit}
    }
}

$deck = [ordered] @{
    'Jocker_A_Black' = 53
    'Jocker_B_Red'   = 54
}

foreach ($key in $keys) { $deck[$key] = $keys.IndexOf($key) + 1 }

$deck.GetEnumerator() | Sort-Object {Get-Random}