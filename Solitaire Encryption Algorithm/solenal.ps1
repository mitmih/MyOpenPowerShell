# https://www.schneier.com/academic/solitaire/

<#
$SourceText - text you want to encrypt
$key - a deck, 52 cards valued from 1 to 52 + two jockers (A and B)
$KeyStream - stream of int values, each of them from 1 to 16, length of KeyStream is equal $SourceText
#>

Clear-Host

Set-Location "$($MyInvocation.MyCommand.Definition | Split-Path -Parent)"

Import-Module '.\solenal-helpers.psm1' -Force
Import-Module '.\solenal-tests.psm1' -Force


# $Key = (1..52 + @('A', 'B') | Sort-Object {Get-Random}) -join ' '
# $Key = '19 51 A 12 20 2 B 23 7 45 25 33 42 50 30 10 44 5 41 40 34 14 16 35 31 21 17 18 8 48 52 27 6 39 11 22 29 13 4 38 46 24 3 47 37 15 36 26 32 43 9 1 28 49'  # 22_22_22_3_7
# $Key = '47 22 42 25 10 26 23 17 49 A 40 27 31 6 5 9 2 14 44 33 36 12 4 34 48 50 28 41 52 1 21 24 16 B 51 43 38 37 20 7 46 8 19 11 30 45 39 18 15 35 29 32 13 3'  # real deck

# initialize key (deck) by password phrase
$Init = Initialize -init "The licenses for most software and other practical works are designed to take away your freedom to share and change the works.  By contrast, the GNU General Public License is intended to guarantee your freedom to share and change all versions of a program--to make sure it remains free software for all its users.  We, the Free Software Foundation, use the GNU General Public License for most of our software; it applies also to any other work released this way by its authors.  You can apply it to your programs, too"

$Key = $Init['key']


# готовим открытый текст - преобразуем в ПРОПИСНЫЕ, оставляем только буквы, дополняем X-ами до кратности 5
# $SourceText = Clear-OpenText -text 'Do Not use PC friend'
$SourceText = Clear-OpenText -text 'abcdefghijklmnopqrstuvwxyz' -AddX

# получаем нужное количество чисел ключевого потока из расчёта один символ открытого текста - одно число ключевого потока
$Gamma = Get-KeyStream -length $SourceText.Length -key $Key
$KeyStream = $Gamma['KeyStream']

# зашифрованный текст
$EncryptedText = ConvertTo-Encrypted -KeyStream $KeyStream -text $SourceText

# расшифрованный текст
$DecryptedText = ConvertTo-Decrypted -KeyStream $KeyStream -text $EncryptedText


Test-EncryptDecrypt -text (Clear-OpenText -text 'abcdefghijklmnopqrstuvwxyz' <# -AddX #>)

# Write-Host "initialized by ", $Init['length'], " letters"

Write-Host "Source text`t", (Split-ClassicView -text $SourceText)
Write-Host "Encrypted text`t", (Split-ClassicView -text $EncryptedText)
Write-Host "Decrypted text`t", (Split-ClassicView -text $DecryptedText)
Write-Host "Key Stream`t", (Split-ClassicView -text ((ConvertFrom-NumbersToLetters -KeyStream $KeyStream) -join '')).Tolower()
Write-Host "`t`t", (Split-ClassicViewKeyStream -KeyStream $KeyStream)

# help to console :)
Write-Host "`t"
Write-Host "Use HashTable `$Gamma to view/check iterations step by step, for example:"
Write-Host "`t`$Gamma['key 1'] to view permutations of deck while computating first key of keystream"
Write-Host "`t`$Gamma['key 1']['step 3 Triple Cut'] to view the deck after triple cut completing"

Show-KeysDistribution -KeyStream $KeyStream
