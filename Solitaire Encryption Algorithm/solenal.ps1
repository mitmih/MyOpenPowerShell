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

    # find edges of range
    $min = [System.Math]::Min($deck.IndexOf('A'), $deck.IndexOf('B'))
    $max = [System.Math]::Max($deck.IndexOf('A'), $deck.IndexOf('B'))
    
    # split deck
    $tc1 = $deck | Select-Object -First ($min)
    $tc2 = $deck[$min..$max]
    $tc3 = $deck | Select-Object -Last ($deck.Length - $max - 1)

    return @($tc3) + @($tc2) + @($tc1)
}

function Split-CountCut {
    param ($deck)

    # $last # значение последней карты
    # если карта = джокер, то её значение = кол-во карт в колоде - 1
    if ($deck[-1] -eq 'A' -or $deck[-1] -eq 'B') {$last = $deck.Length - 1} else {$last = $deck[-1]}

    $p1 = $deck | Select-Object -First $last  # первая часть колоды содержит $last кол-во карт
    $p2 = $deck | Select-Object -Last ($deck.Length - $last)  # оставшаяся часть колоды

    return @($p2) + @($p1)
}

function Get-KeyStream {
    param (
        $length = 10,
        $key = "B 2 9 1 4 6 8 7 5 3 A".Split(' ')
    )
    
    $KeyStream = @()  # ключевой поток = кол-во должно совпадать с исходным сообщением
    for ($i = 0; $i -lt $length; $i++)
    {
        $key = Move-Jockers -deck $key.Split(' ')

        $key = Split-TripleCut -deck $key
        
        # $first  # значение первой карты, если карта = джокер, то значение = кол-во карт в колоде - 1
        $key = Split-CountCut -deck $key
        if ($key[0] -eq 'A' -or $key[0] -eq 'B') {$first = $key.Length - 1} else {$first = $key[0]}
        
        $KeyStream += $first #% 26
    }

    return $KeyStream
}


$qwe = (1..9 + @('A', 'B') | Sort-Object {Get-Random}) -join ' '
$qwe

$KeyStream = Get-KeyStream -length 5 -key $qwe
$KeyStream -join ' '
