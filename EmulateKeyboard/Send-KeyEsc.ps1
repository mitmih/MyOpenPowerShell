$host.UI.RawUI.WindowTitle += ' press ctrl-c' <# 'escaping' #> <# $MyInvocation.MyCommand.Name #> <# $MyInvocation.MyCommand.Definition #>

$proc = Get-Process | Where-Object { $_.MainWindowTitle -match 'press ctrl-c' -and [int]$_.MainWindowHandle -gt 0}

$proc

$wshell = New-Object -ComObject WScript.Shell

while ($null -ne $proc)
{
    $null = $wshell.AppActivate($proc.id)

    $wshell.SendKeys('{ESC}')

    Start-Process -FilePath "$env:windir\System32\scrnsave.scr"

    Start-Sleep -Seconds 273

    $proc = Get-Process | Where-Object { $_.MainWindowTitle -match 'press ctrl-c' -and [int]$_.MainWindowHandle -gt 0}
}
