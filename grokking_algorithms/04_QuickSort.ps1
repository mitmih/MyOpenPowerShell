$Root = ($MyInvocation.MyCommand.Definition | Split-Path -Parent -Resolve)

Import-Module -Force -Verbose ('{0}\grokking.psm1' -f $Root, ($Leaf -replace 'ps1', 'psm1'))

Clear-Host


Get-ListSum @(0..5)

Get-ListCount @($null, 2)

Search-BinaryHardRecurse4 @(0..7) 0  # 3: found after 3 attempts

Search-BinaryHardRecurse4 @(0..7) 77  # -1: not found after the maximum number of attempts



# $lim = 32
# # $lim = 32768
# # 223573,9049
# # 149863,8542
# # 166001,4639
# # 161490,8368
# # cycle
# $ht0 = @{} ; (Measure-Command { ($lim - 1)..0 | ForEach-Object {
#     $ShiftReal = Search-BinarySoftCycle (0..($lim - 1)) $_
#     if ($null -eq $ht0[$ShiftReal]) { $ht0[$ShiftReal] = @($_) } else { $ht0[$ShiftReal] += $_ }
# }}).TotalMilliseconds  # ; $ht0 | Sort-Object -Property Name

# # soft, recurse
# $ht1 = @{} ; (Measure-Command { ($lim - 1)..0 | ForEach-Object {
# $ShiftReal = Search-BinarySoftRecurse (0..($lim - 1)) $_
# if ($null -eq $ht1[$ShiftReal]) { $ht1[$ShiftReal] = @($_) } else { $ht1[$ShiftReal] += $_ }
# }}).TotalMilliseconds  # ; $ht1 | Sort-Object -Property Name

# # hard, recurse
# $ht2 = @{} ; (Measure-Command { ($lim - 1)..0 | ForEach-Object {
#     $ShiftReal = Search-BinaryHardRecurse (0..($lim - 1)) $_
#     if ($null -eq $ht2[$ShiftReal]) { $ht2[$ShiftReal] = @($_) } else { $ht2[$ShiftReal] += $_ }
# }}).TotalMilliseconds  # ; $ht2 | Sort-Object -Property Name

# # hard, recurse4
# $ht3 = @{} ; (Measure-Command { ($lim - 1)..0 | ForEach-Object {
#     $ShiftReal = Search-BinaryHardRecurse4 (0..($lim - 1)) $_
#     if ($null -eq $ht3[$ShiftReal]) { $ht3[$ShiftReal] = @($_) } else { $ht3[$ShiftReal] += $_ }
# }}).TotalMilliseconds  # ; $ht3 | Sort-Object -Property Name
