function Move-Jockers {
    param (
        $deck,
        $A = 'A',
        $B = 'B'
    )
    
    $iA = if ($deck.IndexOf($A) + 1 -eq $deck.Length - 1) {($deck.IndexOf($A) + 1) % ($deck.Length - 0)} else {($deck.IndexOf($A) + 1) % ($deck.Length - 1)}
    $part = $deck -ne $A  # колода без джокера A
    $deck = $part[0..($iA - 1)] + @($A) + @($part | ForEach-Object {if ($_ -notin $part[0..($iA - 1)]) {$_}})
    
    $iB = if ($deck.IndexOf($B) + 2 -eq $deck.Length - 1) {($deck.IndexOf($B) + 1) % ($deck.Length - 0)} else {($deck.IndexOf($B) + 2) % ($deck.Length - 1)}
    $part = $deck -ne $B  # колода без джокера B
    $deck = $part[0..($iB - 1)] + @($B) + @($part | ForEach-Object {if ($_ -notin $part[0..($iB - 1)]) {$_}})

    return $deck
}

$a = [ordered] @{}  # for debug shifting

$deck = 1..13 + @('A', 'B')  # Jocker A (black), JockerB (red)
$deck = $deck | Sort-Object {Get-Random}
$a.Add('-', ($deck -join ' ' ))

# do 
# {
#     $deck = Move-Jockers -deck $deck
# } while ([System.Math]::abs($deck.IndexOf('A') - $deck.IndexOf('B')) -lt 2 ) 

$deck = Move-Jockers -deck $deck
# $a.Add(2, ($deck -join ' ' ))

if ($deck.IndexOf('A') -lt $deck.IndexOf('B')) {$i1 = $deck.IndexOf('A'); $i2 = $deck.IndexOf('B')} else {$i1 = $deck.IndexOf('B'); $i2 = $deck.IndexOf('A')}
$p1 = $deck[0..($i1 - 1)]
$p2 = $deck[$i1..$i2]
$p3 = @($deck | % {if ($_ -notin $p1 -and $_ -notin $p2) {$_}})

$deck = $p3 + $p2 + $p1
# $a.Add(3, ($deck -join ' ' ))

if ($deck[-1] -ne 'A' -and $deck[-1] -ne 'B') {$last = $deck[-1]} else {$last = $null}
if ($deck[$last] -ne 'A' -and $deck[$last] -ne 'B') {$first = $deck[$last]} else {$first = $null}

if ($null -ne $last -and $null -ne $first)
{
    $p1 = $deck[0..($last - 1)]
    $p2 = $deck | % {if ($_ -notin $p1) {$_}}
    
    $deck = $p2 + $p1
    $a.Add($deck[0], ($deck -join ' ' ))
}

$a
