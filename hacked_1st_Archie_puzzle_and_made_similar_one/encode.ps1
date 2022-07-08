Clear-Host

#   1   придумываем текст и конвертируем его в картинку на https://text2image.com/en/
#       сохраняем картинку в png файл локально
#       под именем 'razgadka.png'
$pngName = '1_razgadka.png'


#   2   преобразуем оригинальный png файл в набор байтов
#       конвертируем в base64 и сохраняем в промежуточный файл, его содержимое уже можно посмотреть в браузере
#       если в браузере картинка ОК, то конвертируем байты в биты
$pngFile = Join-Path -Path ($PSScriptRoot) -ChildPath $pngName -Resolve
$pngBytes = (Get-Content -Path $pngFile -AsByteStream)
$pngBase64 = 'data:image/png;base64, {0}' -f [convert]::ToBase64String( $pngBytes )
$pngBase64 | Out-File -FilePath (Join-Path -Path ($PSScriptRoot) -ChildPath '2_base64.txt') -NoNewline
$pngbits = $pngBytes | ForEach-Object { [System.Convert]::ToString($_, 2).PadLeft(8, '0') }
$pngbits -join "`n" | Out-File -FilePath (Join-Path -Path ($PSScriptRoot) -ChildPath '2_binary.txt') -NoNewline


#   3   кодируем биты в морзянку
$MorseCodes = @{
    '0' = '-----'
    '1' = '.----'
}
$pngMorse = $pngbits | ForEach-Object {
    (
        $_[0..7] | ForEach-Object {
            $MorseCodes[$_.ToString()]
        }
    ) -join ' '
}
$pngMorse -join "`n" | Out-File -FilePath (Join-Path -Path ($PSScriptRoot) -ChildPath '3_morse.txt') -NoNewline


#   4   морзянки получается слишком много (50+ КБ) для QR-кода,
#       поэтому используем сервис PasteBin для хранения её текста,
#       а полученный URL уже можно будет закодировать в QR-код на следующем шаге,
#       для этого сохраним pastebin-URL в переменную $url
$url = 'https://pastebin.com/raw/zeFkDskS'

#       (необязательно) можно сделать ярлык для просмотра pastebin-морзянки в браузере
$WScriptShell        = New-Object -ComObject WScript.Shell
$Shortcut            = $WScriptShell.CreateShortcut( (Join-Path -Path ($PSScriptRoot) -ChildPath '4_pastebin.url') )
$Shortcut.TargetPath = $url -replace 'raw\/',''
$Shortcut.Save()

#       (необязательно) можно сверить исходную и pastebin-морзянки между собой
$check = [ordered] @{
    $true   = 0
    $false  = 0
}
$ReqGet = Invoke-WebRequest -UseBasicParsing -Method 'Get' -Uri $url
$pbm = $ReqGet.Content -split "`n"
0..($pngMorse.Count - 1) | ForEach-Object { $c = $pngMorse[$_].Trim() -eq $pbm[$_].Trim() ; $check[$c] += 1 }
"check is {0}:`n{1, 8} matches`n{2, 8} differents" -f $(if($check[$true] -eq $pngMorse.Count) {'OK'} else {'FAILED'}), $check[$true], $check[$false]


#   5   кодируем pastebin-URL и сохраняем QR-код в файл png
(New-Object System.Net.WebClient).DownloadFileAsync(
    ('http://api.qrserver.com/v1/create-qr-code/?format=png&ecc=H&data={0}' -f $url),
    (Join-Path -Path ($PSScriptRoot) -ChildPath ('5_zagadka.png' -f 111))
)
