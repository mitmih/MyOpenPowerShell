# https://www.schneier.com/academic/solitaire/

Set-Location "$($MyInvocation.MyCommand.Definition | Split-Path -Parent)"

Import-Module '.\solenal-helpers.psm1' -Force

$dbg = [ordered] @{}

function Get-KeyStream {
    param (
        $length, # = 10,
        $key #= "B A 9 1 2 3 4 5 6 7 8".Split(' ')
        # $key = "B 2 9 1 4 6 8 7 5 3 A".Split(' ')
    )
    
    $KeyStream = @()  # ключевой поток = кол-во должно совпадать с исходным сообщением
    for ($i = 0; $i -lt $length; $i++)
    {
        # step 1 - move jocker A
        $key = Move-Jocker -deck $key.Split(' ') -jocker 'A' -shift 1
        $dbg.add("step1, move A $($i+1)", ($Key -join ' '))  # for debug
        
        # step 2 - move jocker B
        $key = Move-Jocker -deck $key.Split(' ') -jocker 'B' -shift 2
        $dbg.add("step2, move B $($i+1)", ($Key -join ' '))  # for debug
        
        # step 3 - swap the cards above the first joker with the cards below the second joker
        $key = Split-TripleCut -deck $key
        $dbg.add("step3, Triple Cut $($i+1)", ($Key -join ' '))  # for debug
        
        # step 4 - cut after the counted card
        $key = Split-CountCut -deck $key
        $dbg.add("step4, Count Cut $($i+1)", ($Key -join ' '))  # for debug
        
        
        # step 5 - find the output card (look at the top card, count down the number, next card after last counted will be the OUTPUT)
        
        # $first  # значение первой карты, если карта = джокер, то значение = кол-во карт в колоде - 1
        if ($key[0] -eq 'A' -or $key[0] -eq 'B') {$first = $key.Length - 1} else {$first = $key[0]}
        
        # $out  # значение карты, следующей после последней отсчитанной
        if ($key[$first] -eq 'A' -or $key[$first] -eq 'B') {$out = $key.Length - 1} else {$out = $key[$first]}
        $KeyStream += $out #% 26
    }

    return $KeyStream
}

function FunctionName {
    param ($OptionalParameters)
    # 
}

# $Key = (1..9 + @('A', 'B') | Sort-Object {Get-Random}) -join ' ' #; $Key
# $Key = 'B 2 9 1 4 6 8 7 5 3 A'.Split(' ')
$Key = 'B A 9 1 2 3 4 5 6 7 8'.Split(' ')
$dbg.add('init:', ($Key -join ' '))  # for debug

# получаем нужное количество чисел ключевого потока из расчёта один символ открытого текста - одно число ключевого потока
$KeyStream = Get-KeyStream -length 5 -key $Key

$dbg
$KeyStream -join ' '

$OpenText = Clear-OpenText -text 'Do Not use PC friend'
Split-ClassicView -text $OpenText






