$Root = ($MyInvocation.MyCommand.Definition | Split-Path -Parent -Resolve)

Import-Module -Force -Verbose ('{0}\grokking.psm1' -f $Root, ($Leaf -replace 'ps1', 'psm1'))

Clear-Host


SelectionSort ((0..9) + (0..-9))
