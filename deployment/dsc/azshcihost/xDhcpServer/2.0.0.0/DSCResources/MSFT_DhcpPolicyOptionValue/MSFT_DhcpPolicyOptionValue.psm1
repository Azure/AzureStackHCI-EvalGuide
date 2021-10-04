$currentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

$modulePathhelper            = (Join-Path -Path (Split-Path -Path $currentPath -Parent) -ChildPath 'Helper.psm1')
$modulePathOptionValueHelper = (Join-Path -Path (Join-Path -Path (Join-Path -Path (Split-Path -Path (Split-Path -Path $currentPath -Parent) -Parent) `
                                -ChildPath 'modules') -ChildPath 'DhcpServerDsc.OptionValueHelper') -ChildPath 'OptionValueHelper.psm1')

Import-Module -Name $modulePathhelper
Import-Module -Name $modulePathOptionValueHelper

<#
    .SYNOPSIS
        This function gets a DHCP policy option value.

    .PARAMETER PolicyName
        The Policy name.
    
    .PARAMETER OptionId
        The ID of the option.

    .PARAMETER ScopeId
        The scope ID to get the value. If not used server level values are retrieved.

    .PARAMETER VendorClass
        The vendor class of the option. Use an empty string for standard class.

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
        [ValidateNotNullOrEmpty()]  
        [String]
        $PolicyName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [UInt32]
        $OptionId,

        [Parameter()]
        [AllowNull()]
        [String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily
    )
  
    $hashTable = Get-TargetResourceHelper -ApplyTo 'Policy' -UserClass '' @PSBoundParameters
    
    # Removing properties that are not in the schema.mof before returning the hash table
    $hashTable.Remove('ApplyTo')
    $hashTable.Remove('ReservedIP')
    $hashTable.Remove('UserClass')
    
    $hashTable
}

<#
    .SYNOPSIS
        This function sets a DHCP policy option value.

    .PARAMETER PolicyName
        The policy name.

    .PARAMETER OptionId
        The ID of the option.

    .PARAMETER Value
        The data value option.

    .PARAMETER ScopeId
        The scope ID to set the value. If not used server level values are used.
        
    .PARAMETER VendorClass
        The vendor class of the option. Use an empty string for standard class.

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
        [ValidateNotNullOrEmpty()]  
        [String]
        $PolicyName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [UInt32]
        $OptionId,
        
        [Parameter()]
        [String[]]
        $Value,

        [Parameter()]
        [String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    Set-TargetResourceHelper -ApplyTo 'Policy' -UserClass '' @PSBoundParameters
}

<#
    .SYNOPSIS
        This function tests a DHCP policy option value.

    .PARAMETER PolicyName
        The policy name.

    .PARAMETER OptionId
        The ID of the option.

    .PARAMETER Value
        The data value option.

    .PARAMETER ScopeId
        The scope ID to test the value. If not used server level values are tested.
        
    .PARAMETER VendorClass
        The vendor class of the option. Use an empty string for standard class.

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
        [ValidateNotNullOrEmpty()]  
        [String]
        $PolicyName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [UInt32]
        $OptionId,

        [Parameter()]
        [String[]]
        $Value,

        [Parameter()]
        [String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4')]
        [String]
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    $result = Test-TargetResourceHelper -ApplyTo 'Policy' -UserClass '' @PSBoundParameters
    $result
}
