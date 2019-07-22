$abc = [ordered] @{
    1  = 'A'
    2  = 'B'
    3  = 'C'
    4  = 'D'
    5  = 'E'
    6  = 'F'
    7  = 'G'
    8  = 'H'
    9  = 'I'
    10 = 'J'
    11 = 'K'
    12 = 'L'
    13 = 'M'
    14 = 'N'
    15 = 'O'
    16 = 'P'
    17 = 'Q'
    18 = 'R'
    19 = 'S'
    20 = 'T'
    21 = 'U'
    22 = 'V'
    23 = 'W'
    24 = 'X'
    25 = 'Y'
    26 = 'Z'
}



function Move-JockersDirty {
    param ($deck)

    $iA = if ($deck.IndexOf('A') + 1 -eq $deck.Length - 1) {($deck.IndexOf('A') + 1) % ($deck.Length - 0)} else {($deck.IndexOf('A') + 1) % ($deck.Length - 1)}
    $part = $deck -ne 'A'  # колода без джокера A
    $deck = $part[0..($iA - 1)] + @('A') + @($part | ForEach-Object {if ($_ -notin $part[0..($iA - 1)]) {$_}})

    $iB = if ($deck.IndexOf('B') + 2 -eq $deck.Length - 1) {($deck.IndexOf('B') + 1) % ($deck.Length - 0)} else {($deck.IndexOf('B') + 2) % ($deck.Length - 1)}
    $part = $deck -ne 'B'  # колода без джокера B
    $deck = $part[0..($iB - 1)] + @('B') + @($part | ForEach-Object {if ($_ -notin $part[0..($iB - 1)]) {$_}})

    return $deck
}

function Move-Jocker {
    param (
        $deck,
        $jocker,  # 'A' or 'B'
        $shift  # 1 or 2 
    )
    
    $pos =  if ($deck.IndexOf($jocker) + $shift -gt $deck.Length - 1)
                {($deck.IndexOf($jocker) + $shift) % ($deck.Length - 1)}
            else
                {$deck.IndexOf($jocker) + $shift}
    
    $deck = $deck -ne $jocker
    
    $p1 = $deck | Select-Object -First $pos
    $p2 = $deck | Select-Object -Last ($deck.Length - $pos)
    
    $deck = @($p1) + @($jocker) + @($p2)
    
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
    
    # $last # значение последней карты, если это джокер, то её значение = кол-во карт в колоде - 1
    if ($deck[-1] -eq 'A' -or $deck[-1] -eq 'B') {$last = $deck.Length - 1} else {$last = $deck[-1]}
    
    $p1 = $deck[0..($deck.Length - 2)] | Select-Object -First $last  # отсчитанная часть, поместим её МЕЖДУ нижней картой и остальной колодой
    $p2 = $deck[$last..($deck.Length - 2)] # | Select-Object -Last ($deck.Length - 1 - $last)  # остаток колоды, кроме последней карты
    # $p3 = $last # последняя карта

    $deck = @($p2) + @($p1) + @($last)

    return $deck
    
    # # $last # значение последней карты, если это джокер, то её значение = кол-во карт в колоде - 1
    # if ($deck[-1] -eq 'A' -or $deck[-1] -eq 'B') {$last = $deck.Length - 1} else {$last = $deck[-1]}

    # $p1 = $deck | Select-Object -First $last  # первая часть колоды содержит $last кол-во карт
    # $p2 = $deck | Select-Object -Last ($deck.Length - $last)  # оставшаяся часть колоды

    # return @($p2) + @($p1)
}

# function Convert-JockerToValue {
#     param ($card)
    
#     if ($card -eq 'A' -or $card -eq 'B') {$first = $key.Length - 1} else {$first = $card}
#     # 
# }

function Clear-OpenText {
    param ([string] $text)
    
    $text = $text.ToUpper()
    $text = $text -replace '[^A-Z]', ''
    
    return $text
}

function Split-ClassicView {
    param ([string] $text)
    
    while ($text.Length % 5 -ne 0) {
        $text += 'X'
    }
    
    $split = ''
    for ($i = 0; $i -lt $text.Length; $i+= 5) {
        $split += ($text[($i)..($i + 4)] -join '') + ' '
    }
    
    return $split
}

function ConvertTo-Encrypted {
    param ([string] $text)
    
    
    
    return $null
}