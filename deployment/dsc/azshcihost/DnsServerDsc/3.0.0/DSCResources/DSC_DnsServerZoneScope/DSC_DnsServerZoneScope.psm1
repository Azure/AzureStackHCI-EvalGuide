$script:dscResourceCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
$script:dnsServerDscCommonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DnsServerDsc.Common'

Import-Module -Name $script:dscResourceCommonPath
Import-Module -Name $script:dnsServerDscCommonPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This will return the current state of the resource.

    .PARAMETER Name
        Specifies the name of the Zone Scope.

    .PARAMETER ZoneName
        Specify the existing DNS Zone to add a scope to.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ZoneName

    )

    Write-Verbose -Message ($script:localizedData.GettingDnsServerZoneScopeMessage -f $Name, $ZoneName)
    $record = Get-DnsServerZoneScope -Name $Name -ZoneName $ZoneName -ErrorAction SilentlyContinue

    if ($null -eq $record)
    {
        return @{
            Name     = $Name
            ZoneName = $ZoneName
            ZoneFile = $null
            Ensure   = 'Absent'
        }
    }

    return @{
        Name     = $record.ZoneScope
        ZoneName = $record.ZoneName
        ZoneFile = $record.FileName
        Ensure   = 'Present'
    }
} #end function Get-TargetResource

<#
    .SYNOPSIS
        This will configure the resource.

    .PARAMETER Name
        Specifies the name of the Zone Scope.

    .PARAMETER ZoneName
        Specify the existing DNS Zone to add a scope to.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ZoneName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $clientSubnet = Get-DnsServerZoneScope -Name $Name -ZoneName $ZoneName -ErrorAction SilentlyContinue
    if ($Ensure -eq 'Present')
    {
        if (!$clientSubnet)
        {
            Write-Verbose -Message ($script:localizedData.CreatingDnsServerZoneScopeMessage -f $Name, $ZoneName)
            Add-DnsServerZoneScope -ZoneName $ZoneName -Name $Name
        }
    }
    elseif ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($script:localizedData.RemovingDnsServerZoneScopeMessage -f $Name, $ZoneName)
        Remove-DnsServerZoneScope -Name $Name -ZoneName $ZoneName
    }
} #end function Set-TargetResource

<#
    .SYNOPSIS
        This will return whether the resource is in desired state.

    .PARAMETER Name
        Specifies the name of the Zone Scope.

    .PARAMETER ZoneName
        Specify the existing DNS Zone to add a scope to.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ZoneName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $result = Get-TargetResource -Name $Name -ZoneName $ZoneName

    if ($Ensure -ne $result.Ensure)
    {
        Write-Verbose -Message ($script:localizedData.NotDesiredPropertyMessage -f 'Ensure', $Ensure, $result.Ensure)
        Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage -f $Name)
        return $false
    }

    Write-Verbose -Message ($script:localizedData.InDesiredStateMessage -f $Name)
    return $true
} #end function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
