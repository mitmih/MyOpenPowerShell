$Timer = [system.diagnostics.stopwatch]::startNew()

$wshell = New-Object -ComObject WScript.Shell

while ($true)
{
    $msg = "{0:n0}h : {1:n0}m : {2:n0}s" -f ($Timer.Elapsed.Hours, $Timer.Elapsed.Minutes, $Timer.Elapsed.Seconds)
    
    Start-Process -FilePath "$env:windir\System32\notepad.exe"
    
    Start-Sleep -Milliseconds 999
    
    
    $id = (Get-Process -Name 'notepad').id
    
    $null = $wshell.AppActivate($id)
    
    $wshell.SendKeys($msg)
    
    $wshell.SendKeys('{CAPSLOCK}')
    
    
    Start-Sleep -Milliseconds 999
    
    Get-Process -Name 'notepad' | Stop-Process -Force
    
    $wshell.SendKeys('{CAPSLOCK}')
    
    
    Start-Sleep -Milliseconds 2999
}
