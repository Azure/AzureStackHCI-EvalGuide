$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#

    .SYNOPSIS
        Get desired state

    .PARAMETER IsSingleInstance
        Key for the resource. This value must be set to 'Yes'

#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        [AllowEmptyCollection()]
        $NameServer
    )

    Assert-Module -ModuleName 'DNSServer'

    Write-Verbose -Message $script:localizedData.GettingCurrentRootHintsMessage

    $result = @{
        IsSingleInstance = 'Yes'
        NameServer       = Convert-RootHintsToHashtable -RootHints @(Get-DnsServerRootHint)
    }

    Write-Verbose -Message ($script:localizedData.FoundRootHintsMessage -f $result.NameServer.Count)
    $result
}

<#

    .SYNOPSIS
        Set desired state

    .PARAMETER IsSingleInstance
        Key for the resource. This value must be set to 'Yes'

    .PARAMETER NameServer
        A list of names and IP addresses as a hashtable. This may look like this: NameServer = @{ 'rh1.vm.net.' = '20.1.1.1' }

#>
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        [AllowEmptyCollection()]
        $NameServer
    )

    Write-Verbose -Message $script:localizedData.RemovingAllRootHintsMessage
    Get-DnsServerRootHint | Remove-DnsServerRootHint -Force

    foreach ($item in $NameServer)
    {
        Write-Verbose -Message ($script:localizedData.AddingRootHintMessage -f $item.Key)
        Add-DnsServerRootHint -NameServer $item.Key -IPAddress ($item.value -split ',' | ForEach-Object { $_.Trim() })
    }
}

<#

    .SYNOPSIS
        Test desired state

    .PARAMETER IsSingleInstance
        Key for the resource. This value must be set to 'Yes'

    .PARAMETER NameServer
        A list of names and IP addresses as a hashtable. This may look like this: NameServer = @{ 'rh1.vm.net.' = '20.1.1.1' }

#>
function Test-TargetResource
{
    [OutputType([Bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        [AllowEmptyCollection()]
        $NameServer
    )

    Write-Verbose -Message $script:localizedData.ValidatingRootHintsMessage
    $currentState = Get-TargetResource @PSBoundParameters
    $desiredState = $PSBoundParameters

    foreach ($entry in $desiredState.NameServer)
    {
        $entry.Value = $entry.Value -replace ' ', ''
    }

    $result = Test-DscDnsParameterState -CurrentValues $currentState -DesiredValues $desiredState -TurnOffTypeChecking -ReverseCheck

    $result
}
