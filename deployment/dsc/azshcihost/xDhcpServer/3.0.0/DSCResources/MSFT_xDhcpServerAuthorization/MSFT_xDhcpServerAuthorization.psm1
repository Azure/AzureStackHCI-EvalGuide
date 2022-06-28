$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DscResource.Common'
$script:moduleHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.Common'

Import-Module -Name $script:resourceHelperModulePath
Import-Module -Name $script:moduleHelperPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DnsName = (Get-Hostname),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $IPAddress = (Get-IPv4Address | Select-Object -First 1)
    )

    Write-Verbose -Message (
        $script:localizedData.GetServerAuthorizationMessage -f $ScopeId
    )

    Assert-Module -ModuleName 'DHCPServer'

    $IPAddress = Get-ValidIPAddress -IPString $IPAddress -AddressFamily 'IPv4' -ParameterName 'IPAddress'

    $dhcpServer = Get-DhcpServerInDC | Where-Object -FilterScript {
        ($_.DnsName -eq $DnsName) -and ($_.IPAddress -eq $IPAddress)
    }

    $targetResource = @{
        DnsName   = $dhcpServer.DnsName
        IPAddress = $dhcpServer.IPAddress
    }

    if ($dhcpServer)
    {
        Write-Verbose ($script:localizedData.ServerIsAuthorized -f $DnsName, $IPAddress)

        $targetResource['Ensure'] = 'Present'
    }
    else
    {
        Write-Verbose ($script:localizedData.ServerNotAuthorized -f $DnsName, $IPAddress)

        $targetResource['Ensure'] = 'Absent'
    }

    return $targetResource
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DnsName = (Get-Hostname),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $IPAddress = (Get-IPv4Address | Select-Object -First 1)
    )

    Write-Verbose -Message (
        $script:localizedData.SetServerAuthorizationMessage -f $ScopeId
    )

    Assert-Module -ModuleName 'DHCPServer'

    $IPAddress = Get-ValidIPAddress -IPString $IPAddress -AddressFamily 'IPv4' -ParameterName 'IPAddress'

    if ($Ensure -eq 'Present')
    {
        Write-Verbose ($script:localizedData.AuthorizingServer -f $DnsName, $IPAddress)

        Add-DhcpServerInDc -DnsName $DnsName -IPAddress $IPAddress
    }
    elseif ($Ensure -eq 'Absent')
    {
        Write-Verbose ($script:localizedData.UnauthorizingServer -f $DnsName, $IPAddress)

        Get-DhcpServerInDC | Where-Object -FilterScript {
            ($_.DnsName -eq $DnsName) -and ($_.IPAddress -eq $IPAddress)
        } | Remove-DhcpServerInDc
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DnsName = (Get-Hostname),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $IPAddress = (Get-IPv4Address | Select-Object -First 1)
    )

    Write-Verbose -Message (
        $script:localizedData.TestServerAuthorizationMessage -f $ScopeId
    )

    $targetResource = Get-TargetResource @PSBoundParameters

    $isCompliant = $true

    if ($targetResource.Ensure -ne $Ensure)
    {
        Write-Verbose ($script:localizedData.IncorrectPropertyValue -f 'Ensure', $Ensure, $targetResource.Ensure)
        $isCompliant = $false

    }
    elseif ($Ensure -eq 'Present')
    {
        if ($targetResource.DnsName -ne $DnsName)
        {
            Write-Verbose ($script:localizedData.IncorrectPropertyValue -f 'DnsName', $DnsName, $targetResource.DnsName)
            $isCompliant = $false
        }

        if ($targetResource.IPAddress -ne $IPAddress)
        {
            Write-Verbose ($script:localizedData.IncorrectPropertyValue -f 'IPAddress', $IPAddress, $targetResource.IPAddress)
            $isCompliant = $false
        }
    }

    if ($isCompliant)
    {
        Write-Verbose ($script:localizedData.ResourceInDesiredState -f $DnsName)
    }
    else
    {
        Write-Verbose ($script:localizedData.ResourceNotInDesiredState -f $DnsName)
    }

    return $isCompliant
}

## Internal function used to return all IPv4 addresses
function Get-IPv4Address
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()
    process
    {
        Write-Verbose -Message $script:localizedData.ResolvingIPv4Address

        Get-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' -Namespace 'root\CIMV2' |
            Where-Object -FilterScript {
                $_.IPEnabled -eq 'True' -and $_.IPAddress -notmatch ':'
            } |
                Select-Object -ExpandProperty 'IPAddress'
    } #end process
} #end function Get-IPv4Address

## Internal function used to resolve the local hostname
function Get-Hostname
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()
    process
    {
        Write-Verbose $script:localizedData.ResolvingHostname

        $globalIpProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()

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

Export-ModuleMember -Function *-TargetResource
