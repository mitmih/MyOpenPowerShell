function Move-Jockers {
    param ($deck)

    $iA = if ($deck.IndexOf('A') + 1 -eq $deck.Length - 1) {($deck.IndexOf('A') + 1) % ($deck.Length - 0)} else {($deck.IndexOf('A') + 1) % ($deck.Length - 1)}
    $part = $deck -ne 'A'  # колода без джокера A
    $deck = $part[0..($iA - 1)] + @('A') + @($part | ForEach-Object {if ($_ -notin $part[0..($iA - 1)]) {$_}})

    $iB = if ($deck.IndexOf('B') + 2 -eq $deck.Length - 1) {($deck.IndexOf('B') + 1) % ($deck.Length - 0)} else {($deck.IndexOf('B') + 2) % ($deck.Length - 1)}
    $part = $deck -ne 'B'  # колода без джокера B
    $deck = $part[0..($iB - 1)] + @('B') + @($part | ForEach-Object {if ($_ -notin $part[0..($iB - 1)]) {$_}})

    return $deck
}

function Split-TripleCut {
    param ($deck)

    # split deck
    $i1 = [System.Math]::Min($deck.IndexOf('A'), $deck.IndexOf('B'))
    $i2 = [System.Math]::Max($deck.IndexOf('A'), $deck.IndexOf('B'))

    $tc1 = $deck | Select-Object -First ($i1)
    $tc2 = $deck[$i1..$i2]
    $tc3 = $deck | Select-Object -Last ($deck.Length - $i2 - 1)
    # $tc3 = @($deck | Where-Object {$_ -notin $tc1 -and $_ -notin $tc2})
    # $tc3 = $deck[$i2..($deck.Length - 1)] | Where-Object {$_ -notin ($tc1 + $tc2)}

    return @($tc3) + @($tc2) + @($tc1)
}

# function Split-CountCut {
#     param (
#         OptionalParameters
#     )

# }

$a = [ordered] @{}  # for debug shifting

# $deck = 1..9 + @('A', 'B')  # Jocker A (black), JockerB (red)
# $deck = $deck | Sort-Object {Get-Random}
$deck = "B 2 9 1 4 6 8 7 5 3 A".Split(' ')

$a.Add('0:', ($deck -join ' ' ))

$deck = Move-Jockers -deck $deck
$a.Add('2:', ($deck -join ' ' ))

$deck = Split-TripleCut -deck $deck
$a.Add('3:', ($deck -join ' ' ))

# $last   # значение последней карты
# $first  # значение первой    карты
# если джокер, его значение = кол-во карт в колоде - 1
if ($deck[-1] -eq 'A' -or $deck[-1] -eq 'B') {$last = $deck.Length - 1} else {$last = $deck[-1]}

$p1 = $deck | Select-Object -First $last  # первая часть колоды содержит $last кол-во карт
$p2 = $deck | Select-Object -Last ($deck.Length - $last)  # оставшаяся часть колоды

$deck = @($p2) + @($p1)
if ($deck[0] -eq 'A' -or $deck[0] -eq 'B') {$first = $deck.Length - 1} else {$first = $deck[0]}
$a.Add($first, ($deck -join ' ' ))

$a
