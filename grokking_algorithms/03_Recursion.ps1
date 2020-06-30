$Root = ($MyInvocation.MyCommand.Definition | Split-Path -Parent -Resolve)

Import-Module -Force -Verbose ('{0}\grokking.psm1' -f $Root, ($Leaf -replace 'ps1', 'psm1'))

Clear-Host

Get-Factorial 7

Show-Countdown 3