$a = [ordered] @{}  # for debug shifting

# $edge = 9  # 52
$deck = 1..9 + @('A', 'B')  # JockerA (black)= $edge scores, JockerB (red)= 0 scores
$deck = $deck | Sort-Object {Get-Random}
$a.Add(1, ($deck -join ' ' ))

$jA = if ($deck.IndexOf('A') + 1 -eq $deck.Length - 1) {($deck.IndexOf('A') + 1) % ($deck.Length - 0)} else {($deck.IndexOf('A') + 1) % ($deck.Length - 1)}
$part = $deck -ne 'A'  # колода без джокера A
$deck = $part[0..($jA - 1)] + @('A') + @($part | ForEach-Object {if ($_ -notin $part[0..($jA - 1)]) {$_}})
$a.Add(2, ($deck -join ' ' ))

$jB = if ($deck.IndexOf('B') + 2 -eq $deck.Length - 1) {($deck.IndexOf('B') + 1) % ($deck.Length - 0)} else {($deck.IndexOf('B') + 2) % ($deck.Length - 1)}
$part = $deck -ne 'B'  # колода без джокера B
$deck = $part[0..($jB - 1)] + @('B') + @($part | ForEach-Object {if ($_ -notin $part[0..($jB - 1)]) {$_}})
$a.Add(3, ($deck -join ' ' ))

$a
