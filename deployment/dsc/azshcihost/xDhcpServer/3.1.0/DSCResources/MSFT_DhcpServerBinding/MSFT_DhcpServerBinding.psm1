$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DscResource.Common'
$script:moduleHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.Common'
$script:moduleOptionValueHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.OptionValueHelper'

Import-Module -Name $script:moduleHelperPath
Import-Module -Name $script:moduleOptionValueHelperPath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

$script:ensureLookup = @{
    Present = $true
    Absent  = $false
}

<#
    .SYNOPSIS
        This function gets a DHCP server binding.

    .PARAMETER InterfaceAlias
        The alias of the network adapter to get binding status for
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias
    )

    Write-Verbose -Message (
        $script:localizedData.GettingCurrentState -f $InterfaceAlias
    )

    # Check for DhcpServer module/role
    Assert-Module -ModuleName 'DHCPServer'

    [System.Array] $bindings = Get-DhcpServerv4Binding

    if ($bindings.InterfaceAlias -inotcontains $InterfaceAlias)
    {
        $errorMessage = $script:localizedData.InterfaceAliasIsMissing -f $InterfaceAlias, $env:COMPUTERNAME

        New-ObjectNotFoundException -Message $errorMessage
    }
    else
    {
        $targetBinding = $bindings.Where( { $_.InterfaceAlias -eq $InterfaceAlias })

        $Ensure = $script:ensureLookup.GetEnumerator().Where( { $_.Value -eq $targetBinding.BindingState }).Name

        return @{
            Ensure         = $Ensure
            InterfaceAlias = $InterfaceAlias
        }
    }
}

<#
    .SYNOPSIS
        This function sets a DHCP server binding.

    .PARAMETER Ensure
        Toggles the binding on or off

    .PARAMETER InterfaceAlias
        The alias of the network adapter to set binding status for
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias
    )

    # Check for DhcpServer module/role
    Assert-Module -ModuleName 'DHCPServer'

    $parameters = @{
        BindingState   = $script:ensureLookup.$Ensure
        InterfaceAlias = $InterfaceAlias
    }

    Write-Verbose "Setting interface '$InterfaceAlias' binding state to '$($script:ensureLookup[$Ensure])'"

    Set-DhcpServerv4Binding @parameters
}

<#
    .SYNOPSIS
        This function tests a DHCP server binding.

    .PARAMETER Ensure
        Toggles the binding on or off

    .PARAMETER InterfaceAlias
        The alias of the network adapter to get binding status for
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $InterfaceAlias
    )

    Write-Verbose -Message (
        $script:localizedData.TestingCurrentState -f $InterfaceAlias
    )

    # Check for DhcpServer module/role
    Assert-Module -ModuleName 'DHCPServer'

    $bindingState = Get-TargetResource -InterfaceAlias $InterfaceAlias

    Write-Verbose -Message (
        $script:localizedData.FoundInterfaceState -f $InterfaceAlias, $script:ensureLookup[($bindingState.Ensure)]
    )

    if ($bindingState.Ensure -eq $Ensure)
    {
        Write-Verbose "Interface '$InterfaceAlias' is in desired state"

        return $true
    }
    else
    {
        Write-Verbose "Interface '$InterfaceAlias' is NOT in desired state"

        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
