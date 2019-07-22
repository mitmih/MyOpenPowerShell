function Read-Input
{
    param (
        # [alias('i')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $input #= $null # = "10.101.40.3/21 22"
    )
    
    begin
    {
        $arg = [ordered] @{}
    }
    
    process
    {
        $_ = $_.Trim() -replace '\s+', ' '
        try
        {
            $ip = [string] $_.Split('/')[0]
            
            $ok = [regex] "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"
            
            if ([regex]::IsMatch($ip, $ok))
            {
                $octets = [int[]] $ip.Split('.')
                if ($octets[0] -in 0..255 -and $octets[1] -in 0..255 -and $octets[2] -in 0..255 -and $octets[3] -in 0..255)
                {
                    $arg['ip'] = $ip
                }
            }
            else
            {
                $arg['ip'] = $null
            }
        }
        catch
        {
            Write-Error ('Read-Input: catch 0 - $arg["ip"]' + " $ip")
            $arg['ip'] = $null
        }
        
        try
        {
            $maskFrom = ($_.Split('/')[1])
            if ($null -eq $maskFrom -or '' -eq $maskFrom)
            {
                $arg['maskFrom'] = $null
            }
            else
            {
                $arg['maskFrom'] = [int32] ($_.Split('/')[1]).Split(' ')[0]
            }
        }
        catch
        {
            Write-Error 'Read-Input: catch 1 - $arg["maskFrom"]'
            $arg['maskFrom'] = $null
        }
        
        try
        {
            $maskTo = $_.Split(' ')[1]
            if ($null -eq $maskTo)
            {
                $arg['maskTo'] = $arg['maskFrom']
            }
            else
            {
                $arg['maskTo'] = [int32] $maskTo
            }
        }
        catch
        {
            Write-Error 'Read-Input: catch 2 - $arg["maskFrom"]'
            $arg['maskTo'] = $arg['maskFrom']
        }
    }
    
    end
    {
        if ($null -ne $arg['ip'] -and $arg['maskFrom'] -in 0..31 -and $arg['maskTo'] -in 0..31)
        {
            return $arg
        }
        else
        {
            return $null
        }
    }
}


function Find-Network
{
    param
    (
        [alias('i')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $inp, # = $null, # = "10.101.40.3/21",
        
        [alias('d')]
        $description = ''
    )
    
    process
    {
        try
        {
            $arg = $_ | Read-Input  # $arg['ip'], $arg['maskFrom'], $arg['maskTo']
            
            $ip = [IPAddress] $arg['ip']
            $CIDRnum = [int] $arg['maskFrom']
            
            $mask = [IPAddress] ($CIDRnum | Convert-Mask_NumToDot)
            $network = [IPAddress] ([UInt32]$ip.Address -band [UInt32]$mask.Address)
            $wildcard = [IPAddress] ( -bnot [UInt32]$mask.Address)
            $broadcast = [IPAddress] ([UInt32]$network.Address -bor -bnot [UInt32]$mask.Address)
            
            $HostMin = [IPAddress] ([UInt32]$network.Address -bor [uint32]([ipaddress]"0.0.0.1").Address)  # HostMin = network + 1
            $HostMax = [IPAddress] ([UInt32]$broadcast.Address -band [uint32]([ipaddress]"255.255.255.254").Address)  # HostMin = broadcast - 1
            
            $bytes = $wildcard.GetAddressBytes()
            [Array]::Reverse($bytes)
            $capacity = [uint32] ([BitConverter]::ToUInt32($bytes, 0) - 1)  # capacity = wildcard - 1
            
            $objNetwork = New-Object PSObject -Property @{
                sortby      = [UInt32]($description.Split(' '))[1]
                description = $description
                input       = ($inp | ForEach-Object {$_}) -join '/'
                
                network     = $network.IPAddressToString
                cidr        = $CIDRnum
                mask        = $mask.IPAddressToString
                wildcard    = $wildcard.IPAddressToString
                
                HostMin     = $HostMin.IPAddressToString
                HostMax     = $HostMax.IPAddressToString
                
                broadcast   = $broadcast.IPAddressToString
                
                capacity = $capacity
            }
        }
        
        catch
        {
            Write-Error "Find-Network: invalid IP :`n$inp`n$description"
            return $null
        }
    }
    
    end
    {
        return $objNetwork
    }
}


function Convert-Mask_NumToDot
{
<#
    .SYNOPSIS
        Converts a number of bits (0-32) to an IPv4 network mask string (e.g., "255.255.255.0")

    .DESCRIPTION
        Converts a number of bits (0-32) to an IPv4 network mask string (e.g., "255.255.255.0")
        (2^n - 1) * (2^(32-n))

    .PARAMETER Mask
        Specifies the number of bits in the mask.

    .NOTES
        based on (C) Bill Stewart (Mar 13 2016) examples

    .LINK
        https://www.itprotoday.com/powershell/working-ipv4-addresses-powershell
#>

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        # [ValidateRange(0, 31)]
        [Int] $Mask
    )

    # begin {}

    process {
        # if($_ -gt 32) {$_ = 32}
        # if($_ -lt 0)  {$_ = 0}

        $IntMask = ([Math]::Pow(2, $_) - 1) * [Math]::Pow(2, (32 - $_))
        $bytes = [BitConverter]::GetBytes([UInt32] $IntMask)
    }
    
    end {
        if ($null -eq $bytes) {
            return 0
        }
        else {
            return (($bytes.Count - 1)..0 | ForEach-Object { [String] $bytes[$_] }) -join "."
        }
    }
}


function Convert-Mask_DotToNum
{
<#
    .SYNOPSIS
        Converts an IPv4 network mask string (e.g., "255.255.255.0") to a number of bits (0-32)

    .DESCRIPTION
        Converts an IPv4 network mask string (e.g., "255.255.255.0") to a number of bits (0-32)

    .PARAMETER Mask
        Specifies the number of bits in the mask.

    .NOTES
        based on (C) Bill Stewart (Mar 13 2016) examples

    .LINK
        https://www.itprotoday.com/powershell/working-ipv4-addresses-powershell
#>

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Mask
    )

    # begin {}
    
    process {
        try {
            $Mask = ([ipaddress] $_).Address
        }
        catch {  #[FormatException] {
            Write-Error "FormatException"
            return 0
        }

        for ( $bitCount = 0; $Mask -ne 0; $bitCount++ ) {
            $Mask = $Mask -band ($Mask - 1)
        }
    }

    end {
        return $bitCount
    }
}



<#  тест Convert-Mask_NumToDot | Convert-Mask_DotToNum
    33 | Convert-Mask_NumToDot | Convert-Mask_DotToNum
    $dct = [ordered]@{}
    0..33 | ForEach-Object {
        try {
            $dct.Add(
                $_,
                ($_, ($_ | Convert-Mask_NumToDot),
                ($_ | Convert-Mask_NumToDot | Convert-Mask_DotToNum)) 
            )
        }
        catch {
            Write-Host "ParameterArgumentValidationError,Convert-Mask_NumToDot" -BackgroundColor Red
        }
    }
    $dct | Out-GridView
#>


<#  конвертация IP в двоичное/шестнадцатиричное представления
    [System.Convert]::ToString([uint32]([ipaddress]'0.0.7.255').Address, 16)  # ff 07 00 00
    [System.Convert]::ToString([uint32]([ipaddress]'0.0.7.255').Address, 2)  # 11111111 00000111 00000000 00000000
    [BitConverter]::ToUInt32(([ipaddress]'0.0.7.255').GetAddressBytes(),0)  # в десятичное число, но изза обратного порядка байтов вместо 2047 получаем 4278648832
        # поэтому при расчёте подсетей нельзя просто прибавить шаг к предыдущей подсети, нужно сначала обратить порядок байтов
    ([ipaddress]'0.0.7.255').Address
#>