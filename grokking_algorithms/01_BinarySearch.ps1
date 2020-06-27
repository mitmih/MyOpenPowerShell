$Root = ($MyInvocation.MyCommand.Definition | Split-Path -Parent -Resolve)

$Leaf = ($MyInvocation.MyCommand.Definition | Split-Path -Leaf -Resolve)

Import-Module -Force ('{0}\{1}' -f $Root, ($Leaf -replace 'ps1', 'psm1'))


Clear-Host

$lim = 16384  # кол-во чисел в сгенерированном списке, 0..($lim -1)

# вычисляем достаточное (но не всегда необходимое) количество вопросов
$ShiftPredict = 0 ; do { $ShiftPredict++ } until ((1 -shl $ShiftPredict) -gt ($lim - 1))

Search-BinarySoftCycle      (0..7) 7
Search-BinarySoftRecurse    (0..7) 7
Search-BinaryHardRecurse    (0..7) 7

# "Search-BinarySoftCycle    {2}{3}`treal '{1}' vs '{0}' max" -f $ShiftPredict, (Search-BinarySoftCycle (0..($lim - 1)) $lim), $lim, " in (0..$($lim - 1))"  # число не из списка
# "`nSearch-BinarySoftCycle    {2}{3}`treal '{1}' vs '{0}' max" -f $ShiftPredict, (Search-BinarySoftCycle (0..($lim - 1)) ($lim - 1)), ($lim - 1), " in (0..$($lim - 1))"


# странно, но при проверке на больших (32768) числах рекурсия обгоняет цикл
# 32768
# 224712,7304 мс   цикл
# 142719,8852 мс   рекурсия софт
# 164528,1803 мс   рекурсия хард

$ht0 = @{} ; (Measure-Command { ($lim - 1)..0 | ForEach-Object {
        $ShiftReal = Search-BinarySoftCycle (0..($lim - 1)) $_
        if ($null -eq $ht0[$ShiftReal]) { $ht0[$ShiftReal] = @($_) } else { $ht0[$ShiftReal] += $_ }
    }}).TotalMilliseconds  # ; $ht0 | Sort-Object -Property Name

$ht1 = @{} ; (Measure-Command { ($lim - 1)..0 | ForEach-Object {
        $ShiftReal = Search-BinarySoftRecurse (0..($lim - 1)) $_
        if ($null -eq $ht1[$ShiftReal]) { $ht1[$ShiftReal] = @($_) } else { $ht1[$ShiftReal] += $_ }
    }}).TotalMilliseconds  # ; $ht1 | Sort-Object -Property Name

$ht2 = @{} ; (Measure-Command { ($lim - 1)..0 | ForEach-Object {
        $ShiftReal = SeSearch-BinaryHardRecurse (0..($lim - 1)) $_
        if ($null -eq $ht2[$ShiftReal]) { $ht2[$ShiftReal] = @($_) } else { $ht2[$ShiftReal] += $_ }
    }}).TotalMilliseconds  # ; $ht2 | Sort-Object -Property Name
