$Timer = [system.diagnostics.stopwatch]::startNew()

Add-Type -AssemblyName system.windows.forms

$wshell = New-Object -ComObject WScript.Shell

while ($true)
{
    Start-Process -FilePath "$env:windir\System32\notepad.exe"
    
    Start-Sleep -Milliseconds 999
    
    $id = (Get-Process -Name 'notepad').id
    
    $null = $wshell.AppActivate($id)
    
    # [system.windows.forms.sendkeys]::sendwait('{CAPSLOCK}')
    
    $msg = "{0:n0}h : {1:n0}m : {2:n0}s" -f ($Timer.Elapsed.Hours, $Timer.Elapsed.Minutes, $Timer.Elapsed.Seconds)
    
    [system.windows.forms.sendkeys]::sendwait($msg)
    
    Start-Sleep -Milliseconds 999
    
    # [system.windows.forms.sendkeys]::sendwait('{CAPSLOCK}')
    
    Get-Process -Name 'notepad' | Stop-Process -Force
    
    Start-Sleep -Milliseconds 999
}
