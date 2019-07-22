function Find-Networks
{
<#
.SYNOPSIS
    calculate IPv4 sub/super networks


.DESCRIPTION
    take IPv4 address string in CIDR notation ('aaa.bbb.ccc.ddd/N'), calculate input network
    if input looks like 'aaa.bbb.ccc.ddd/X Y' or the argument '-to <int>' is specified it will find sub/super networks


.INPUTS
    IPv4 address string in CIDR notation
    new network CIDR number from 0..31 range


.OUTPUTS
    list of calculated networks (input and subnets/supernet)


.PARAMETER inp
    IPv4 address string in CIDR notation 'aaa.bbb.ccc.ddd/X Y' or just 'aaa.bbb.ccc.ddd/X', where
        X mean source mask number
        Y mean NEW mask number
    for example
        '10.101.40.1/21'
    or
        '10.101.40.1/21 24'


.PARAMETER to
    new network CIDR number from 0..31 range
    more priority than Y in input string

.EXAMPLE
    cls; '   10.101.40.255/21   ' | Find-Networks | ft *
    
    just calculate IP`s of this network
    in '10.101.40.255/21' and '21' must be at least one space

.EXAMPLE
    '10.101.40.255/21' | Find-Networks -to 24 -Verbose | Out-GridView -PassThru | Format-Table -Property * -AutoSize
    
    verbose mode enable
    find subnets
    pass them to the Out-GridView cmdlet
    pass selected in the table subnets to the next cmdlet


.EXAMPLE
    '10.101.40.255/21 19' | Find-Networks -v | ft *
    
    find supernetwork
    verbose mode


.LINK
    Subnetting guide By Stelios Antoniou on November 8, 2007
        https://www.pluralsight.com/blog/it-ops/simplify-routing-how-to-organize-your-network-into-smaller-subnets
    
    This module contain two functions, based on Bill Stewart (Mar 13 2016) code snippets (c)
        https://www.itprotoday.com/powershell/working-ipv4-addresses-powershell


.NOTES
    Author: Dmitry Mikhaylov aka alt-air
    thanks to Bill Stewart for code snippets of converting IPv4 network mask string to CIDR number and back
#>
    
    [CmdletBinding()]  # SupportsShouldProcess)]
    param
    (
        [alias('i')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$inp,

        [alias('t')]
        # [ValidateRange(0, 31)]
        $to = $null
    )
    
    # begin {<# импорт вспомогательного модуля перенесён в манифест  # Import-Module -Name ".\Get-Networks_helper.psm1" -Force #>}
    
    process
    {
        if ($_)
        {
            # $_ = $_.Trim() -replace '\s+', ' '
            $arg = $_ | Read-Input  # $arg['ip'], $arg['maskFrom'], $arg['maskTo']
            
            if ($arg)
            {
                if ($to -ge 0) { $arg['maskTo'] = $to }  # у параметра -to приоритет выше, чем у новой CIDR-маске в строке, т.е. несколько строк с разными новыми масками будут посчитаны с параметром -to
                
                if ($arg['maskFrom'])
                {
                    $Networks = @(($arg['ip'] + '/' + $arg['maskFrom']) | Find-Network -description 'network')  # список подсетей, где 0й элемент - исходная сеть, 1й - 1я подсеть/суперсеть
                }
            }
        }
        
        
        if ($arg -and $arg['maskFrom'] -in 0..31 -and $arg['maskTo'] -in 0..31)
        { # input ok
            
            if ($arg['maskFrom'] -eq $arg['maskTo'])
            { # same net
                Write-Verbose "net $($Networks[0].network)/$($arg['maskFrom']) to same /$($arg['maskTo'])"
            }
            
            elseif ($arg['maskFrom'] -gt $arg['maskTo'])
            { # net to supernet
                Write-Verbose "net $($Networks[0].network)/$($arg['maskFrom']) to supernet /$($arg['maskTo'])"
                $Networks += $Networks[0].network + '/' + $arg['maskTo'] | Find-Network -description 'supernet'  # находим суперсеть
            }
            
            elseif ($arg['maskFrom'] -lt $arg['maskTo'])
            { # net to subnets
                $SubNetCount = [Math]::Pow(2, ($arg['maskTo'] - $arg['maskFrom']))
                Write-Verbose "net $($Networks[0].network)/$($arg['maskFrom']) to $SubNetCount subnets /$($arg['maskTo'])"
                
                # delta = (wildcard главной сети + 1) / количество подсетей
                $bytes = ([ipaddress]$Networks[0].wildcard).GetAddressBytes()
                [Array]::Reverse($bytes)
                $delta = ( [uint32] ([BitConverter]::ToUInt32($bytes, 0) + 1) ) / $SubNetCount
                
                for ($i = 0; $i -lt $SubNetCount; $i++)
                { # следующая подсеть =  + delta * i
                    $bytes = ([ipaddress] $Networks[0].network).GetAddressBytes()
                    [array]::Reverse($bytes)
                    
                    $bytes = [BitConverter]::GetBytes( [uint32] ([BitConverter]::ToUInt32($bytes, 0) + $delta * $i) )
                    [Array]::Reverse($bytes)
                    
                    $NetInCIDRFormat = ((0..($bytes.Count - 1) | ForEach-Object { [String] $bytes[$_] }) -join ".") + '/' + $arg['maskTo']
                    
                    $Networks += $NetInCIDRFormat | Find-Network -description "subnet $($i + 1)"  # рассчитанную подсеть - в список!
                }
            }
        }
        
        else
        { # input not ok
            Write-Verbose "bad input...`n'$_'"
        }
    }
    
    end
    {
        $Networks | Select-Object `
            'sortby',
            'description',
            'input',
            'network',
            'cidr',
            'mask',
            'wildcard',
            'HostMin',
            'HostMax',
            'broadcast',
            'capacity'
    }
}
