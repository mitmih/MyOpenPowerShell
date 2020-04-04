$Timer = [system.diagnostics.stopwatch]::startNew()

# Add-Type -AssemblyName System.Windows.Forms # [System.Windows.Forms.sendkeys]::sendwait('{NUMLOCK}')

$wshell = New-Object -ComObject WScript.Shell

# $stop = $false

# for ($i = 0; $i -lt 100; $i++)
do
{
    Start-Sleep -Milliseconds (100 - 19)
    
    $msg = "{0:n0}h : {1:n0}m : {2:n0}s" -f ($Timer.Elapsed.Hours, $Timer.Elapsed.Minutes, $Timer.Elapsed.Seconds)
    
    $null = $wshell.AppActivate($PID)
    
    $wshell.SendKeys('{CAPSLOCK}')
    
    Write-Host $msg
    
    Start-Sleep -Milliseconds 500
    
    $wshell.SendKeys('{CAPSLOCK}')
    
    Start-Sleep -Milliseconds 400
    
    # if ($Timer.Elapsed.Seconds -gt 10) { $stop = $true }
}
until ($stop)