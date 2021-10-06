$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    Write-Verbose -Message $script:localizedData.GettingDnsForwardersMessage

    $currentServerForwarders = Get-DnsServerForwarder

    $targetResource = @{
        IsSingleInstance = $IsSingleInstance
        IPAddresses      = @()
        UseRootHint      = $currentServerForwarders.UseRootHint
        EnableReordering = $currentServerForwarders.EnableReordering
        Timeout          = $currentServerForwarders.Timeout
    }

    [System.Array] $currentIPs = $currentServerForwarders.IPAddress

    if ($currentIPs)
    {
        $targetResource.IPAddresses = $currentIPs
    }

    return $targetResource
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]
        $IPAddresses,

        [Parameter()]
        [System.Boolean]
        $UseRootHint,

        [Parameter()]
        [System.Boolean]
        $EnableReordering,

        [Parameter()]
        [ValidateRange(0, 15)]
        [System.UInt32]
        $Timeout
    )

    $setDnsServerForwarderParameters = @{}

    if ($PSBoundParameters.ContainsKey('IPAddresses'))
    {
        if ($IPAddresses.Count -eq 0)
        {
            Write-Verbose -Message $script:localizedData.DeletingDnsForwardersMessage

            Get-DnsServerForwarder | Remove-DnsServerForwarder -Force
        }
        else
        {
            Write-Verbose -Message $script:localizedData.SettingDnsForwardersMessage

            $setDnsServerForwarderParameters['IPAddress'] = $IPAddresses
        }
    }

    if ($PSBoundParameters.ContainsKey('UseRootHint'))
    {
        Write-Verbose -Message ($script:localizedData.SettingUseRootHintProperty -f $UseRootHint)

        $setDnsServerForwarderParameters['UseRootHint'] = $UseRootHint
    }

    if ($PSBoundParameters.ContainsKey('EnableReordering'))
    {
        Write-Verbose -Message ($script:localizedData.SettingEnableReorderingProperty -f $EnableReordering)

        $setDnsServerForwarderParameters['EnableReordering'] = $EnableReordering
    }

    if ($PSBoundParameters.ContainsKey('Timeout'))
    {
        Write-Verbose -Message ($script:localizedData.SettingTimeoutProperty -f $Timeout)

        $setDnsServerForwarderParameters['Timeout'] = $Timeout
    }

    # Only do set if there are any parameters values added to the hashtable.
    if ($setDnsServerForwarderParameters.Count -gt 0)
    {
        Set-DnsServerForwarder @setDnsServerForwarderParameters -WarningAction 'SilentlyContinue'
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]
        $IPAddresses,

        [Parameter()]
        [System.Boolean]
        $UseRootHint,

        [Parameter()]
        [System.Boolean]
        $EnableReordering,

        [Parameter()]
        [ValidateRange(0, 15)]
        [System.UInt32]
        $Timeout
    )

    Write-Verbose -Message $script:localizedData.ValidatingIPAddressesMessage

    $currentConfiguration = Get-TargetResource -IsSingleInstance $IsSingleInstance

    [System.Array] $currentIPs = $currentConfiguration.IPAddresses

    if ($currentIPs.Count -ne $IPAddresses.Count)
    {
        return $false
    }

    foreach ($ip in $IPAddresses)
    {
        if ($ip -notin $currentIPs)
        {
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey('UseRootHint'))
    {
        if ($currentConfiguration.UseRootHint -ne $UseRootHint)
        {
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey('EnableReordering'))
    {
        if ($currentConfiguration.EnableReordering -ne $EnableReordering)
        {
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey('Timeout'))
    {
        if ($currentConfiguration.Timeout -ne $Timeout)
        {
            return $false
        }
    }

    return $true
}
