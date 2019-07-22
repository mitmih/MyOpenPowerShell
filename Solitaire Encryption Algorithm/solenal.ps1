# https://www.schneier.com/academic/solitaire/

Set-Location "$($MyInvocation.MyCommand.Definition | Split-Path -Parent)"

Import-Module '.\solenal-helpers.psm1' -Force
Import-Module '.\solenal-tests.psm1' -Force

# $DebugKeyStream = [ordered] @{}
# $DebugText = [ordered] @{}

function Get-KeyStream {
    param (
        $length,
        $key
    )
    
    $key = $key.Split(' ')  # string to array
    
    $KeyStream = @()  # ключевой поток = кол-во должно совпадать с исходным сообщением
    for ($i = 0; $i -lt $length; $i++)
    {
        # step 1 - move jocker A
        
        $key = Move-Jocker -deck $key -jocker 'A' -shift 1
        
        # $DebugKeyStream.add("step1, move A $($i+1)", ($Key -join ' '))  # for debug
        
        
        # step 2 - move jocker B
        
        $key = Move-Jocker -deck $key -jocker 'B' -shift 2
        
        # $DebugKeyStream.add("step2, move B $($i+1)", ($Key -join ' '))  # for debug
        
        
        # step 3 - swap the cards above the first joker with the cards below the second joker
        
        $key = Split-TripleCut -deck $key
        
        # $DebugKeyStream.add("step3, Triple Cut $($i+1)", ($Key -join ' '))  # for debug
        
        
        # step 4 - cut after the counted card
        
        $key = Split-CountCut -deck $key
        
        # $DebugKeyStream.add("step4, Count Cut $($i+1)", ($Key -join ' '))  # for debug
        
        
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


$Key = (1..52 + @('A', 'B') | Sort-Object {Get-Random}) -join ' '
# $Key = '19 51 A 12 20 2 B 23 7 45 25 33 42 50 30 10 44 5 41 40 34 14 16 35 31 21 17 18 8 48 52 27 6 39 11 22 29 13 4 38 46 24 3 47 37 15 36 26 32 43 9 1 28 49'  # 22_22_22_3_7
# $DebugKeyStream.add('init:', ($Key -join ' '))  # for debug

# готовим открытый текст - преобразуем в ПРОПИСНЫЕ, оставляем только буквы, дополняем X-ами до кратности 5
# $SourceText = Clear-OpenText -text 'Do Not use PC friend'
$SourceText = Clear-OpenText -text 'abcdefghijklmnopqrstuvwxyz'

# получаем нужное количество чисел ключевого потока из расчёта один символ открытого текста - одно число ключевого потока
$KeyStream = Get-KeyStream -length $SourceText.Length -key $Key

# зашифрованный текст
$EncryptedText = ConvertTo-Encrypted -KeyStream $KeyStream -text $SourceText

# расшифрованный текст
$DecryptedText = ConvertTo-Decrypted -KeyStream $KeyStream -text $EncryptedText


Test-EncryptDecrypt -text (Clear-OpenText -text 'abcdefghijklmnopqrstuvwxyz')

Write-Host "Source text`t", (Split-ClassicView -text $SourceText)
Write-Host "Encrypted text`t", (Split-ClassicView -text $EncryptedText)
Write-Host "Decrypted text`t", (Split-ClassicView -text $DecryptedText)
Write-Host "Key Stream`t", (Split-ClassicView -text ((ConvertFrom-NumbersToLetters -KeyStream $KeyStream) -join '')).Tolower()
Write-Host "`t`t", (Split-ClassicViewKeyStream -KeyStream $KeyStream)