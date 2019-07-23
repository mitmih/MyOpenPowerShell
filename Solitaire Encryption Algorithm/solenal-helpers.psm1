$LetterByValue = @{
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

$ValueByLetter = @{
    'A' = 1
    'B' = 2
    'C' = 3
    'D' = 4
    'E' = 5
    'F' = 6
    'G' = 7
    'H' = 8
    'I' = 9
    'J' = 10
    'K' = 11
    'L' = 12
    'M' = 13
    'N' = 14
    'O' = 15
    'P' = 16
    'Q' = 17
    'R' = 18
    'S' = 19
    'T' = 20
    'U' = 21
    'V' = 22
    'W' = 23
    'X' = 24
    'Y' = 25
    'Z' = 26
}

function Move-Jocker {
    param (
        $deck,  # array
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
    param ($deck, $InitBy = 0)
    
    if ($InitBy -eq 0)
    {
        # $last # значение последней карты, если это джокер, то её значение = кол-во карт в колоде - 1
        if ($deck[-1] -eq 'A' -or $deck[-1] -eq 'B') {$last = $deck.Length - 1} else {$last = $deck[-1]}
    }
    else
    {
        $last = $InitBy
    }
    
    $p1 = $deck[0..($deck.Length - 2)] | Select-Object -First $last  # отсчитанная часть, поместим её МЕЖДУ нижней картой и остальной колодой
    $p2 = $deck[$last..($deck.Length - 2)]  # остаток колоды, кроме последней карты
    $p3 = $deck[-1] # последняя карта

    $deck = @($p2) + @($p1) + @($p3)

    return $deck
}

function Get-KeyStream {
    param (
        $length,
        $key
    )
    
    $DeckStates = [ordered] @{}
    
    # добавить проверку - если строка, то сделать сплит
    
    $key = $key.Split(' ')  # string to array
    
    $KeyStream = @()  # ключевой поток = кол-во ключей должно совпадать с кол-вом символов в выровненном до кратности 5 исходном сообщении
    for ($i = 0; $i -lt $length; $i++)
    {
        do
        {
            $step = [ordered] @{}
            
            # step 1 - move jocker A
            
            $key = Move-Jocker -deck $key -jocker 'A' -shift 1
            
            $step.add("step 1 move A", ($Key -join ' '))
            
            
            # step 2 - move jocker B
            
            $key = Move-Jocker -deck $key -jocker 'B' -shift 2
            
            $step.add("step 2 move B", ($Key -join ' '))
            
            
            # step 3 - swap the cards above the first joker with the cards below the second joker
            
            $key = Split-TripleCut -deck $key
            
            $step.add("step 3 Triple Cut", ($Key -join ' '))
            
            
            # step 4 - cut after the counted card
            
            $key = Split-CountCut -deck $key
            
            $step.add("step 4 Count Cut", ($Key -join ' '))
            
            # step 5 - find the output card (look at the top card, count down the number, next card after last counted will be the OUTPUT)
            # # $Key = @('B') + 1..52 + @('A')  # for debug until condition
            
            # $top  # значение верхней карты, если карта = джокер, то значение = кол-во карт в колоде - 1
            if ($key[0] -eq 'A' -or $key[0] -eq 'B') {$top = $key.Length - 1} else {$top = $key[0]}
            
            # $out  # значение карты, следующей после последней отсчитанной
            if ($key[$top] -eq 'A' -or $key[$top] -eq 'B')
            {
                $out = $key[$key.Length - 1]  # если джокер - то смотрим последнюю карту
            }
            else
            {
                $out = $key[$top]  # т.к. индексация в массиве с 0, то $key[$top] будет следующей картой
            }
        }
        until ($out -ne 'A' -and $out -ne 'B')
            
        $out = [int] $out
        
        if ($out -gt 26 <# -and $out -le 52 #>) { $out -= 26 }
        # elseif ($out -gt 52)              { $out -= 52 }
            
        $KeyStream += [int] $out

        $step.add("step 5 Find Out Card", $out)
        
        $DeckStates.add("key $($i + 1)", $step)
    }

    $DeckStates.add("KeyStream", $KeyStream)
    return $DeckStates
}

function Clear-OpenText {
    param ([string] $text, [switch] $AddX)
    
    begin
    {
        $text = $text.ToUpper()
        
        $text = $text -replace '[^A-Z]', ''
    }
    
    
    process
    {
        if ($AddX)
        {
            while ($text.Length % 5 -ne 0)
            {
                $text += 'X'
            }
        }
    }
    
    
    end { return $text }
}

function Split-ClassicView {
    param ([string] $text)
    
    $split = ''
    for ($i = 0; $i -lt $text.Length; $i+= 5) {
        $split += ($text[($i)..($i + 4)] -join '') + ' '
    }
    
    return $split
}

function Split-ClassicViewKeyStream {
    param ($KeyStream)
    
    $c1 = '_'
    $c2 = '  '
    $split = ''
    for ($i = 0; $i -lt $KeyStream.Length; $i+= 5) {
        $split += ($KeyStream[($i)..($i + 4)] -join $c1) + $c2
    }
    
    return $split
}

function ConvertTo-Encrypted {
    param (
        [string] $text,
        [int[]]$KeyStream
    )
    
    
    $result = ''
    
    for ($i = 0; $i -lt $text.Length; $i++)
    {
        $val = ($ValueByLetter[ [string] $text[$i] ] + $KeyStream[$i] % 26)
        
        if ($val -gt 26) { $val %= 26 }
        
        $result += $LetterByValue[$val]        
    }
    
    return $result
}

function ConvertTo-Decrypted {
    param (
        [string] $text,
        [int[]]$KeyStream
    )
    
    
    $result = ''
    
    for ($i = 0; $i -lt $text.Length; $i++)
    {
        $val = ($ValueByLetter[ [string] $text[$i] ] - $KeyStream[$i] % 26)
        
        if ($val -le 0) { $val += 26 }
        
        $result += $LetterByValue[$val]
        
    }
    
    return $result
}

function ConvertFrom-NumbersToLetters {  # перевод ключевого потока в буквы
    param ($KeyStream)
    
    $KeyStreamLetters = @()

    foreach ($k in $KeyStream) { $KeyStreamLetters += $LetterByValue[$k] }
    
    return $KeyStreamLetters
}

function Initialize-Deck {  # инициализация колоды фразой
    param ([string] $InitBy)
    
    
    begin
    {
        $key = (1..52 + @('A', 'B')) -join ' '
        
        $InitBy = Clear-OpenText -text $InitBy
        
        $DeckStates = @{}
        
        # $DeckStates['deck before init'] = $Key
        
        $DeckStates['length'] = $InitBy.length
    }
    
    
    process
    {
        # добавить проверку - если строка, то сделать сплит
        $key = $key.Split(' ')  # string to array
        
        for ($i = 0; $i -lt $InitBy.length - 2; $i++)  # последние две буквы используются для перемещения джокеров
        {
            # $step = [ordered] @{}
            
            # step 1 - move jocker A
            
            $key = Move-Jocker -deck $key -jocker 'A' -shift 1
            
            # $step['step 1 move A'] = $Key -join ' '
            
            # step 2 - move jocker B
            
            $key = Move-Jocker -deck $key -jocker 'B' -shift 2
            
            # $step['step 2 move B'] = $Key -join ' '
            
            
            # step 3 - swap the cards above the first joker with the cards below the second joker
            
            $key = Split-TripleCut -deck $key
            
            # $step['step 3 Triple Cut'] = $Key -join ' '
            
            
            # step 4 - cut after the counted card
            
            $key = Split-CountCut -deck $key
            
            # $step['step 4 Count Cut'] = $Key -join ' '
            
            
            # step 5 - repeat Count Cut using the current letter value from init phrase
            
            $key = Split-CountCut -deck $key -init $ValueByLetter[([string] $InitBy[$i])]
            
            # $step['step 5 Init Cut'] = $Key -join ' '
            
            # $DeckStates.add("init $($i + 1)", $step)
        }
        
        $key = Move-Jocker -deck $key -jocker 'A' -shift $key[-2]
        
        $key = Move-Jocker -deck $key -jocker 'B' -shift $key[-1]
        
        $DeckStates.add('key', ($Key -join ' '))
    }
    
    
    end { return $DeckStates }
}

function Show-KeysDistribution {  # для отображения распределения ключей
    param ($KeyStream)
    
    
    begin
    {
        $distrib = [ordered] @{
            0  = 'A '
            1  = 'B '
            2  = 'C '
            3  = 'D '
            4  = 'E '
            5  = 'F '
            6  = 'G '
            7  = 'H '
            8  = 'I '
            9  = 'J '
            10 = 'K '
            11 = 'L '
            12 = 'M '
            13 = 'N '
            14 = 'O '
            15 = 'P '
            16 = 'Q '
            17 = 'R '
            18 = 'S '
            19 = 'T '
            20 = 'U '
            21 = 'V '
            22 = 'W '
            23 = 'X '
            24 = 'Y '
            25 = 'Z '
        }
    }
    
    
    process
    {
        foreach($k in $KeyStream)
        {
            $distrib[($k - 1)] += '*'
        }
    }
    
    
    end
    {
        return $distrib
    }
}
