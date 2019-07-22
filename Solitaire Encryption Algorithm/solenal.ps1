# https://www.schneier.com/academic/solitaire/

Set-Location "$($MyInvocation.MyCommand.Definition | Split-Path -Parent)"

Import-Module '.\solenal-helpers.psm1' -Force
Import-Module '.\solenal-tests.psm1' -Force

$DebugKeyStream = [ordered] @{}
$DebugText = [ordered] @{}

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
        
        $DebugKeyStream.add("step1, move A $($i+1)", ($Key -join ' '))  # for debug
        
        
        # step 2 - move jocker B
        
        $key = Move-Jocker -deck $key.Split(' ') -jocker 'B' -shift 2
        
        $DebugKeyStream.add("step2, move B $($i+1)", ($Key -join ' '))  # for debug
        
        
        # step 3 - swap the cards above the first joker with the cards below the second joker
        
        $key = Split-TripleCut -deck $key
        
        $DebugKeyStream.add("step3, Triple Cut $($i+1)", ($Key -join ' '))  # for debug
        
        
        # step 4 - cut after the counted card
        
        $key = Split-CountCut -deck $key
        
        $DebugKeyStream.add("step4, Count Cut $($i+1)", ($Key -join ' '))  # for debug
        
        
        # step 5 - find the output card (look at the top card, count down the number, next card after last counted will be the OUTPUT)
        
        # $top  # значение первой карты, если карта = джокер, то значение = кол-во карт в колоде - 1
        if ($key[0] -eq 'A' -or $key[0] -eq 'B') {$top = $key.Length - 1} else {$top = $key[0]}
        
        # $out  # значение карты, следующей после последней отсчитанной
        if ($key[$top] -eq 'A' -or $key[$top] -eq 'B') {$out = [int] $key.Length - 1} else {$out = [int] $key[$top]}
        
        if ($out -gt 26 -and $out -le 52) { $out -= 26 }
        elseif ($out -gt 52)              { $out -= 52 }
        
        $KeyStream += [int] $out #% 26
    }

    return $KeyStream
}


$Key = (1..52 + @('A', 'B') | Sort-Object {Get-Random}) -join ' ' #; $Key
# $Key = '3 31 17 28 5 51 37 30 52 A B 29 49 46 43 40 8 10 14 32 15 24 22 26 23 19 35 48 27 47 45 4 33 44 42 21 20 38 41 11 7 18 36 34 39 13 9 25 50 1 12 2 6 16'.Split(' ')
# $Key = '52 2 28 24 26 20 3 21 10 32 7 37 31 42 17 4 11 30 A 12 16 49 34 25 15 45 5 51 47 48 8 22 6 50 39 43 B 18 1 46 27 33 35 40 13 19 36 14 41 9 29 44 38 23'.Split(' ')
# $Key = 'B 2 9 1 4 6 8 7 5 3 A'.Split(' ')
# $Key = 'B A 9 1 2 3 4 5 6 7 8'.Split(' ')
$DebugKeyStream.add('init:', ($Key -join ' '))  # for debug

# готовим открытый текст - преобразуем в ПРОПИСНЫЕ, оставляем только буквы, дополняем X-ами до кратности 5
# $SourceText = Clear-OpenText -text 'Do Not use PC friend'
$SourceText = Clear-OpenText -text 'abcdefghijklmnopqrstuvwxyz'

# получаем нужное количество чисел ключевого потока из расчёта один символ открытого текста - одно число ключевого потока
$KeyStream = Get-KeyStream -length $SourceText.Length -key $Key

# зашифрованный текст
$EncryptedText = ConvertTo-Encrypted -KeyStream $KeyStream -text $SourceText

# расшифрованный текст
$DecryptedText = ConvertTo-Decrypted -KeyStream $KeyStream -text $EncryptedText



$DebugText.Add('Key Stream, numbers', $KeyStream -join ' ')
$DebugText.Add('Source text', (Split-ClassicView -text $SourceText))
$DebugText.Add(' ', "+")
$DebugText.Add('Key Stream ', (Split-ClassicView -text ((ConvertFrom-NumbersToLetters -KeyStream $KeyStream) -join '')))
$DebugText.Add('= Encrypted text', (Split-ClassicView -text $EncryptedText))
$DebugText.Add('  ', "-")
$DebugText.Add('Key Stream  ', (Split-ClassicView -text ((ConvertFrom-NumbersToLetters -KeyStream $KeyStream) -join '')))
$DebugText.Add('= Decrypted text', (Split-ClassicView -text $DecryptedText))

# $DebugKeyStream
Test-EncryptDecrypt -text (Clear-OpenText -text 'abcdefghijklmnopqrstuvwxyz')
$DebugText
