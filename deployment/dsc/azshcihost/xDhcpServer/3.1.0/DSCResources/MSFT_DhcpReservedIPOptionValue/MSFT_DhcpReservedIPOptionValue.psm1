$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DscResource.Common'
$script:moduleHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.Common'
$script:moduleOptionValueHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.OptionValueHelper'

Import-Module -Name $script:moduleHelperPath
Import-Module -Name $script:moduleOptionValueHelperPath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        This function gets a DHCP reserved IP option value.

    .PARAMETER ReservedIP
        The Reserved IP to get the option value from.

    .PARAMETER OptionId
        The ID of the option.

    .PARAMETER VendorClass
        The vendor class of the option. Use an empty string for standard class.

    .PARAMETER UserClass
        The user class of the option.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.
#>
function Get-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', "", Justification = 'Verbose messages are present in Get-TargetResourceHelper')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ReservedIP,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $UserClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily
    )

    $hashTable = Get-TargetResourceHelper -ApplyTo 'ReservedIP' @PSBoundParameters

    # Removing properties that are not in the schema.mof before returning the hash table
    $hashTable.Remove('ApplyTo')
    $hashTable.Remove('ScopeId')
    $hashTable.Remove('PolicyName')

    $hashTable
}

<#
    .SYNOPSIS
        This function sets a DHCP reserved IP option value.

    .PARAMETER ReservedIP
        The reserved IP.

    .PARAMETER OptionId
        The Option ID.

    .PARAMETER Value
        The option data value.

    .PARAMETER VendorClass
        The vendor class of the option. Use an empty string for standard class.

    .PARAMETER UserClass
        The user class of the option.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

    .PARAMETER Ensure
        When set to 'Present', the option will be created.
        When set to 'Absent', the option will be removed.
#>
function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', "", Justification = 'Verbose messages are present in Set-TargetResourceHelper')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ReservedIP,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.UInt32]
        $OptionId,

        [Parameter()]
        [System.String[]]
        $Value,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $UserClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Set-TargetResourceHelper -ApplyTo 'ReservedIP' @PSBoundParameters
}

<#
    .SYNOPSIS
        This function tests a DHCP reserved IP option value.

    .PARAMETER ReservedIP
        The reserved IP.

    .PARAMETER OptionId
        The Option ID.

    .PARAMETER Value
        The option data value.

    .PARAMETER VendorClass
        The vendor class of the option. Use an empty string for standard class.

    .PARAMETER UserClass
        The user class of the option.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.

    .PARAMETER Ensure
        When set to 'Present', the option will be created.
        When set to 'Absent', the option will be removed.
#>
function Test-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', "", Justification = 'Verbose messages are present in Test-TargetResourceHelper')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ReservedIP,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.UInt32]
        $OptionId,

        [Parameter()]
        [System.String[]]
        $Value,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $UserClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $result = Test-TargetResourceHelper -ApplyTo 'ReservedIP' @PSBoundParameters
    $result
}
