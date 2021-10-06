$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    This resource contains a references to an offensive word that we do not use
    in the DSC community. But due to the underlying class MicrosoftDNS_Server is
    using the offensive word this resource need to use it too. This will change
    as soon as the underlying class changes, or we can remove the property
    altogether, see https://docs.microsoft.com/en-us/windows/win32/dns/microsoftdns-server.
#>

<#
    .SYNOPSIS
        Returns the current state of the DNS server settings.

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DnsServer
    )

    Assert-Module -ModuleName 'DnsServer'

    Write-Verbose -Message $script:localizedData.GettingDnsServerSettings

    $dnsServerInstance = Get-CimClassMicrosoftDnsServer -DnsServer $DnsServer

    $returnValue = @{}

    $classProperties = @(
        'DisjointNets'
        'LogLevel'
        'IsSlave'
    )

    foreach ($property in $classProperties)
    {
        $propertyName = $property

        if ($propertyName -eq 'IsSlave')
        {
            $propertyName = 'NoForwarderRecursion'
        }

        $returnValue.Add($propertyName, $dnsServerInstance.$property)
    }

    $returnValue.DnsServer = $DnsServer

    return $returnValue
}

<#
    .SYNOPSIS
        Set the desired state of the DNS server legacy settings.

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.

    .PARAMETER DisjointNets
        Indicates whether the default port binding for a socket used to send queries
        to remote DNS Servers can be overridden.

    .PARAMETER NoForwarderRecursion
        TRUE if the DNS server does not use recursion when name-resolution through
        forwarders fails.

    .PARAMETER LogLevel
        Indicates which policies are activated in the Event Viewer system log.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DnsServer,

        [Parameter()]
        [System.Boolean]
        $DisjointNets,

        [Parameter()]
        [System.Boolean]
        $NoForwarderRecursion,

        [Parameter()]
        [System.UInt32]
        $LogLevel
    )

    Assert-Module -ModuleName 'DnsServer'

    $getTargetResourceResult = Get-TargetResource -DnsServer $DnsServer

    $PSBoundParameters.Remove('DnsServer')

    $dnsProperties = Remove-CommonParameter -Hashtable $PSBoundParameters

    $dnsServerInstance = Get-CimClassMicrosoftDnsServer -DnsServer $DnsServer

    $propertiesInDesiredState = @()

    foreach ($property in $dnsProperties.keys)
    {
        if ($dnsProperties.$property -ne $getTargetResourceResult.$property)
        {
            # Property not in desired state.

            Write-Verbose -Message ($script:localizedData.SetDnsServerSetting -f $property, $dnsProperties[$property])
        }
        else
        {
            # Property in desired state.

            Write-Verbose -Message ($script:localizedData.PropertyInDesiredState -f $property)

            $propertiesInDesiredState += $property
        }
    }

    # Remove passed parameters that are in desired state.
    $propertiesInDesiredState | ForEach-Object -Process {
        $dnsProperties.Remove($_)
    }

    # Handle renaming properties to what the class expects.
    if ($dnsProperties.ContainsKey('NoForwarderRecursion'))
    {
        $dnsProperties.IsSlave = $dnsProperties.NoForwarderRecursion

        $dnsProperties.Remove('NoForwarderRecursion')
    }

    if ($dnsProperties.Keys.Count -eq 0)
    {
        Write-Verbose -Message $script:localizedData.LegacySettingsInDesiredState
    }
    else
    {
        $setCimInstanceParameters = @{
            InputObject = $dnsServerInstance
            Property    = $dnsProperties
            ErrorAction = 'Stop'
        }

        if ($DnsServer -ne 'localhost')
        {
            $setCimInstanceParameters['ComputerName'] = $DnsServer
        }

        Set-CimInstance @setCimInstanceParameters
    }
}

<#
    .SYNOPSIS
        Tests the desired state of the DNS server settings.

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.

    .PARAMETER DnsServer
        Specifies the DNS server to connect to, or use 'localhost' for the current
        node.

    .PARAMETER DisjointNets
        Indicates whether the default port binding for a socket used to send queries
        to remote DNS Servers can be overridden.

    .PARAMETER NoForwarderRecursion
        TRUE if the DNS server does not use recursion when name-resolution through
        forwarders fails.

    .PARAMETER LogLevel
        Indicates which policies are activated in the Event Viewer system log.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DnsServer,

        [Parameter()]
        [System.Boolean]
        $DisjointNets,

        [Parameter()]
        [System.Boolean]
        $NoForwarderRecursion,

        [Parameter()]
        [System.UInt32]
        $LogLevel
    )

    Write-Verbose -Message $script:localizedData.EvaluatingDnsServerSettings

    $currentState = Get-TargetResource -DnsServer $DnsServer

    $null = $PSBoundParameters.Remove('DnsServer')

    $result = $true

    # Returns an item for each property that is not in desired state.
    if (Compare-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters -Verbose:$VerbosePreference)
    {
        $result = $false
    }

    return $result
}

function Get-CimClassMicrosoftDnsServer
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DnsServer
    )

    $getCimInstanceParameters = @{
        NameSpace   = 'root\MicrosoftDNS'
        ClassName   = 'MicrosoftDNS_Server'
        ErrorAction = 'Stop'
    }

    if ($DnsServer -ne 'localhost')
    {
        $getCimInstanceParameters['ComputerName'] = $DnsServer
    }

    $dnsServerInstance = Get-CimInstance @getCimInstanceParameters

    return $dnsServerInstance
}
