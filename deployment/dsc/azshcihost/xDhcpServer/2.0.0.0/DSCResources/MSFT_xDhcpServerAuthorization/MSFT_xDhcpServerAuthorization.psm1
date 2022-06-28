Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
ResolvingIPv4Address      = Resolving first local IPv4 IP address ...
ResolvingHostname         = Resolving local hostname ...
AuthorizingServer         = Authorizing DHCP Server '{0}' with IP address '{1}'
UnauthorizingServer       = Unauthorizing DHCP Server '{0}' with IP address '{1}'
ServerIsAuthorized        = DHCP Server '{0}' with IP address '{1}' IS authorized
ServerNotAuthorized       = DHCP Server '{0}' with IP address '{1}' is NOT authorized
IncorrectPropertyValue    = Property '{0}' is incorrect. Expected '{1}', actual '{2}'
ResourceInDesiredState    = DHCP Server '{0}' is in the desired state
ResourceNotInDesiredState = DHCP Server '{0}' is NOT in the desired state
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure,

        [ValidateNotNullOrEmpty()]
        [System.String] $DnsName = ( Get-Hostname ),

        [ValidateNotNullOrEmpty()]
        [System.String] $IPAddress = ( Get-IPv4Address | Select-Object -First 1 )
    )
    Assert-Module -ModuleName 'DHCPServer';
    $IPAddress = Get-ValidIPAddress -IPString $IPAddress -AddressFamily 'IPv4' -ParameterName 'IPAddress'
    $dhcpServer = Get-DhcpServerInDC | Where-Object { ($_.DnsName -eq $DnsName) -and ($_.IPAddress -eq $IPAddress) }
    $targetResource = @{
        DnsName = $dhcpServer.DnsName
        IPAddress = $dhcpServer.IPAddress
    }
    if ($dhcpServer)
    {
        Write-Verbose ($LocalizedData.ServerIsAuthorized -f $DnsName, $IPAddress)
        $targetResource['Ensure'] = 'Present'
    }
    else
    {
        Write-Verbose ($LocalizedData.ServerNotAuthorized -f $DnsName, $IPAddress)
        $targetResource['Ensure'] = 'Absent'
    }
    return $targetResource
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure,

        [ValidateNotNullOrEmpty()]
        [System.String] $DnsName = ( Get-Hostname ),

        [ValidateNotNullOrEmpty()]
        [System.String] $IPAddress = ( Get-IPv4Address | Select-Object -First 1 )
    )
    Assert-Module -ModuleName 'DHCPServer'
    $IPAddress = Get-ValidIPAddress -IPString $IPAddress -AddressFamily 'IPv4' -ParameterName 'IPAddress'
    if ($Ensure -eq 'Present')
    {
        Write-Verbose ($LocalizedData.AuthorizingServer -f $DnsName, $IPAddress)
        Add-DhcpServerInDc -DnsName $DnsName -IPAddress $IPAddress
    }
    elseif ($Ensure -eq 'Absent')
    {
        Write-Verbose ($LocalizedData.UnauthorizingServer -f $DnsName, $IPAddress)
        Get-DhcpServerInDC | Where-Object { ($_.DnsName -eq $DnsName) -and ($_.IPAddress -eq $IPAddress) } | Remove-DhcpServerInDc
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure,

        [ValidateNotNullOrEmpty()]
        [System.String] $DnsName = ( Get-Hostname ),

        [ValidateNotNullOrEmpty()]
        [System.String] $IPAddress = ( Get-IPv4Address | Select-Object -First 1 )
    )
    $targetResource = Get-TargetResource @PSBoundParameters
    $isCompliant = $true
    
    if ($targetResource.Ensure -ne $Ensure)
    {
        Write-Verbose ($LocalizedData.IncorrectPropertyValue -f 'Ensure', $Ensure, $targetResource.Ensure)
        $isCompliant = $false

    }
    elseif ($Ensure -eq 'Present')
    {
        if ($targetResource.DnsName -ne $DnsName)
        {
            Write-Verbose ($LocalizedData.IncorrectPropertyValue -f 'DnsName', $DnsName, $targetResource.DnsName)
            $isCompliant = $false
        }
        if ($targetResource.IPAddress -ne $IPAddress)
        {
            Write-Verbose ($LocalizedData.IncorrectPropertyValue -f 'IPAddress', $IPAddress, $targetResource.IPAddress)
            $isCompliant = $false
        }
    }
    
    if ($isCompliant)
    {
        Write-Verbose ($LocalizedData.ResourceInDesiredState -f $DnsName)
    }
    else {
        Write-Verbose ($LocalizedData.ResourceNotInDesiredState -f $DnsName)
    }
    return $isCompliant
}

## Internal function used to return all IPv4 addresses
function Get-IPv4Address
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ( )
    process
    {
        Write-Verbose $LocalizedData.ResolvingIPv4Address
        Get-WmiObject Win32_NetworkAdapterConfiguration -Namespace 'root\CIMV2' |
            Where-Object IPEnabled -eq 'True' |
                ForEach-Object {
                    Write-Output ($_.IPAddress -notmatch ':')
                }
    } #end process
} #end function Get-IPv4Address

## Internal function used to resolve the local hostname
function Get-Hostname {
    [CmdletBinding()]
    [OutputType([System.String])]
    param ( )
    process
    {
        Write-Verbose $LocalizedData.ResolvingHostname;
        $globalIpProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties();
        if ($globalIpProperties.DomainName)
        {
            return '{0}.{1}' -f $globalIpProperties.HostName, $globalIpProperties.DomainName
        }
        else
        {
            return $globalIpProperties.HostName
        }
    } #end process
} #end function Get-Hostname

Export-ModuleMember -Function *-TargetResource;
