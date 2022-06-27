$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DscResource.Common'
$script:moduleHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.Common'
$script:moduleOptionValueHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.OptionValueHelper'

Import-Module -Name $script:moduleHelperPath
Import-Module -Name $script:moduleOptionValueHelperPath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets a DHCP server exclusion range.

    .PARAMETER ScopeId
        The Scope ID of the exclusion range.

    .PARAMETER IPStartRange
        The starting IP Address of the exclusion range.

    .PARAMETER IPEndRange
        The ending IP Address of the exclusion range.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [String]
        $IPEndRange,

        [Parameter()]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily = 'IPv4'
    )

    # Check for DhcpServer module/role
    Assert-Module -ModuleName 'DHCPServer'

    $ScopeId = (Get-ValidIpAddress -IpString $ScopeId -AddressFamily $AddressFamily -ParameterName 'ScopeId').IPAddressToString
    $IPStartRange = (Get-ValidIpAddress -IpString $IPStartRange -AddressFamily $AddressFamily -ParameterName 'StartRange').IPAddressToString
    $IPEndRange = (Get-ValidIpAddress -IpString $IPEndRange -AddressFamily $AddressFamily -ParameterName 'EndRange').IPAddressToString

    # Check to ensure startRange is smaller than endRange
    if ($IPEndRange.Address -lt $IPStartRange.Address)
    {
        $errorMessage = $script:localizedData.InvalidStartAndEndRange

        New-InvalidArgumentException -ArgumentName 'StartRange' -Message $errorMessage
    }

    # Retrieve exclusions for the scope
    Write-Verbose -Message ($script:localizedData.RetrievingExclusion -f $ScopeId)

    [System.Array] $dhcpExclusionRange = Get-DhcpServerv4ExclusionRange -ScopeId $ScopeId -ErrorAction 'SilentlyContinue'

    $testExclusionRange = $dhcpExclusionRange |
        Where-Object -FIlterScript {
            $_.StartRange -eq $IPStartRange -and $_.EndRange -eq $IPEndRange
    }

    $ipStart = $testExclusionRange.StartRange.IPAddressToString
    $ipEnd = $testExclusionRange.EndRange.IPAddressToString

    if ($testExclusionRange)
    {
        Write-Verbose -Message ($script:localizedData.FoundExclusion -f $ScopeId, $ipStart, $ipEnd)

        $ensure = 'Present'
    }
    else
    {
        $ensure = 'Absent'
    }

    @{
        Ensure        = $ensure
        ScopeId       = $ScopeId
        IPStartRange  = $ipStart
        IPEndRange    = $ipEnd
        AddressFamily = $AddressFamily
    }
}

<#
    .SYNOPSIS
        This function sets a DHCP server exclusion range.

    .PARAMETER ScopeId
        The Scope ID of the exclusion range.

    .PARAMETER IPStartRange
        The starting IP Address of the exclusion range.

    .PARAMETER IPEndRange
        The ending IP Address of the exclusion range.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

    .PARAMETER Ensure
        When set to 'Present', the option will be created.
        When set to 'Absent', the option will be removed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [String]
        $IPEndRange,

        [Parameter()]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily = 'IPv4',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    # Check for DhcpServer module/role
    Assert-Module -ModuleName 'DHCPServer'

    if ($Ensure -eq 'Present')
    {
        # Add exclusion range
        Write-Verbose -Message ($script:localizedData.SettingExclusionRange -f $IPStartRange, $IPEndRange, $ScopeId)

        Add-DhcpServerv4ExclusionRange -ScopeId $ScopeId -StartRange $IPStartRange -EndRange $IPEndRange
    }
    else
    {
        # Remove exclusion range
        Write-Verbose -Message ($script:localizedData.RemovingExclusionRange -f $IPStartRange, $IPEndRange, $ScopeId)

        Remove-DhcpServerv4ExclusionRange -ScopeId $ScopeId -StartRange $IPStartRange -EndRange $IPEndRange
    }
}

<#
    .SYNOPSIS
        This function tests a DHCP server exclusion range.

    .PARAMETER ScopeId
        The Scope ID of the exclusion range.

    .PARAMETER IPStartRange
        The starting IP Address of the exclusion range.

    .PARAMETER IPEndRange
        The ending IP Address of the exclusion range.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

    .PARAMETER Ensure
        When set to 'Present', the option will be created.
        When set to 'Absent', the option will be removed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [String]
        $IPEndRange,

        [Parameter()]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily = 'IPv4',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present'
    )

    # Check for DhcpServer module/role
    Assert-Module -ModuleName 'DHCPServer'

    $validStartRange = Get-ValidIpAddress -IpString $IPStartRange -AddressFamily $AddressFamily -ParameterName 'StartRange'
    $validEndRange = Get-ValidIpAddress -IpString $IPEndRange -AddressFamily $AddressFamily -ParameterName 'EndRange'

    # Check to ensure startRange is smaller than endRange
    if ($validEndRange.Address -lt $validStartRange.Address)
    {
        $errorMessage = $script:localizedData.InvalidStartAndEndRange

        New-InvalidArgumentException -ArgumentName 'StartRange' -Message $errorMessage
    }

    # Retrieve exclusions for the scope
    Write-Verbose -Message ($script:localizedData.TestingExclusionRange -f $ScopeId)

    [System.Array] $dhcpExclusionRange = Get-DhcpServerv4ExclusionRange -ScopeId $ScopeId -ErrorAction 'SilentlyContinue'

    $testExclusionRange = $dhcpExclusionRange |
        Where-Object -FilterScript {
            $_.StartRange -eq $IPStartRange -and $_.EndRange -eq $IPEndRange
        }

    $ipStart = $testExclusionRange.StartRange.IPAddressToString
    $ipEnd = $testExclusionRange.EndRange.IPAddressToString

    if ($Ensure -ieq 'Present')
    {
        if ($testExclusionRange)
        {
            Write-Verbose -Message ($script:localizedData.FoundExclusion -f $ScopeId, $ipStart, $ipEnd)
            Write-Verbose -Message ($script:localizedData.InDesiredState -f $ScopeId)

            return $true
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.ExclusionNotFound -f $IPStartRange, $IPEndRange)
            Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $ScopeId, $Ensure, "Absent")

            return $false
        }
    }
    elseif ($Ensure -ieq 'Absent')
    {
        if (-not $testExclusionRange)
        {
            Write-Verbose -Message ($script:localizedData.ExclusionNotFound -f $IPStartRange, $IPEndRange)
            Write-Verbose -Message ($script:localizedData.InDesiredState -f $ScopeId)

            return $true
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.FoundExclusion -f $ScopeId, $ipStart, $ipEnd)
            Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $ScopeId, $Ensure, "Present")

            return $false
        }
    }
}

Export-ModuleMember -Function *-TargetResource
