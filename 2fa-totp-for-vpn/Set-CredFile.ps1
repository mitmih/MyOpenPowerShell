param(
    [Alias('f')]                $file   ,   <# ovpn and auth file name #>
    [Alias('u')]                $user   ,   <# username (login) #>
    [Alias('p')]                $pre    ,   <# otp preffix #>
    [Alias('i')]                $init   ,   <# otp init secret #>
    [Alias('s')]                $suf        <# otp suffix #>
    # [Alias('c')]    [switch]    $copy        <# refresh *.ovpn files in user config dir #>
)

"{0}`n    file {1}`n    user {2}`n    pre  {3}`n    init {4}`n    suf  {5}" -f 'check your parameters:', $file, $user, $pre, $init, $suf | Write-Warning

$ScriptName = Get-Item -Path ($MyInvocation.MyCommand.Definition)

# поиск/импорт модуля https://gist.github.com/jonfriesen/234c7471c3e3199f97d5#file-totp-ps1
try
{
    $mTOTP = Get-Item -Path (Join-Path -Path $ScriptName.Directory -ChildPath 'totp.psm1' -Resolve)
    
    Import-Module -Force $mTOTP.FullName
}

catch   { $PSItem.ToString() | Write-Error -ErrorAction Continue }

finally {}

# get user OpenVPN config dir
$OpenVPNDir = Join-Path -Path $env:USERPROFILE -ChildPath (Join-Path -Path 'OpenVPN' -ChildPath 'config')

try
{
    $OpenVPNDir = Get-Item -Path $OpenVPNDir -ErrorAction 'Stop'
}
catch
{
    $OpenVPNDir = New-Item -Force -ItemType 'Directory' -Path $OpenVPNDir
}
finally
{
    Get-ChildItem -Path (Join-Path -Path $ScriptName.Directory -ChildPath 'config') -Exclude '*.lnk' | 
        Where-Object { $_.Extension <# -match 'key|crt' #> } |
        Copy-Item -Force -Destination $OpenVPNDir
}

# get one time password
$otp = '{0}{1}{2}' -f $pre, (Get-Otp -SECRET $init), $suf
$otp | Write-Warning

# make ovpn and auth files in user config dir
$ovpn = (Get-ChildItem -Path (Join-Path -Path $ScriptName.Directory -ChildPath 'config') -Filter ('{0}.ovpn' -f $file)) | Get-Content
$ovpn += 'auth-user-pass {0}.txt' -f $file
$ovpn | Set-Content -Force -Path (Join-Path -Path $OpenVPNDir -ChildPath ('{0}.ovpn' -f $file))

# make ovpn and auth files in user config dir
$auth = @($user, $otp)
$auth | Set-Content -Force -Path (Join-Path -Path $OpenVPNDir -ChildPath ('{0}.txt' -f $file))
