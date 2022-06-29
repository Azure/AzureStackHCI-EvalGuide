$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DscResource.Common'
$script:moduleHelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../Modules/DhcpServerDsc.Common'

Import-Module -Name $script:resourceHelperModulePath
Import-Module -Name $script:moduleHelperPath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Gets current status of the scope with specified ScopeId.

    .DESCRIPTION
        Used by DSC Resource to perform Get method.
        For existing scopes retrieves all information that might be defined in the resource.
        Fore missing scopes returns only ScopeId, AddressFamily and the fact that it is absent.

    .EXAMPLE
        Get-TargetResource -ScopeId 192.168.1.0 -Name MyScope -IPStartRange 192.168.1.1 -IPEndRange 192.168.1.250 -SubnetMask 255.255.255.0
        Gets information about scope 192.168.1.0 (if exists) or retunrs information about missing scope.

    .PARAMETER ScopeId
        ScopeId of the DHCP scope

    .PARAMETER Name
        Name of the DHCP scope

    .PARAMETER IPStartRange
        StartRange of the DHCP scope

    .PARAMETER IPEndRange
        EndRange of the DHCP scope

    .PARAMETER SubnetMask
        SubnetMask of the DHCP scope

    .PARAMETER AddressFamily
        AddressFamily of the DHCP scope
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPEndRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily = 'IPv4'
    )

    Write-Verbose -Message (
        $script:localizedData.GetServerScopeMessage -f $ScopeId
    )

    #region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -ModuleName 'DHCPServer'

    # Check values of IP Addresses used to define the scope
    $ipAddressesAssertionParameters = @{
        ScopeId       = $ScopeId
        IPStartRange  = $IPStartRange
        IPEndRange    = $IPEndRange
        SubnetMask    = $SubnetMask
        AddressFamily = $AddressFamily
    }

    Assert-ScopeParameter @ipAddressesAssertionParameters

    #endregion Input Validation

    $dhcpScope = Get-DhcpServerv4Scope -ScopeId $ScopeId -ErrorAction 'SilentlyContinue'

    if ($dhcpScope)
    {
        $ensure = 'Present'
        $leaseDuration = $dhcpScope.LeaseDuration.ToString()
    }
    else
    {
        $ensure = 'Absent'
        $leaseDuration = ''
    }

    return @{
        ScopeID       = $ScopeId
        Name          = $dhcpScope.Name
        IPStartRange  = $dhcpScope.StartRange
        IPEndRange    = $dhcpScope.EndRange
        SubnetMask    = $dhcpScope.SubnetMask
        Description   = $dhcpScope.Description
        LeaseDuration = $leaseDuration
        State         = $dhcpScope.State
        AddressFamily = $AddressFamily
        Ensure        = $ensure
    }
}

<#
    .SYNOPSIS
        Sets the scope with specified ScopeId.

    .DESCRIPTION
        Used by DSC Resource to perform Set method.
        It will add/remove/modify Scope based on input parameters

    .EXAMPLE
        Set-TargetResource -ScopeId 192.168.1.0 -Name MyScope -IPStartRange 192.168.1.1 -IPEndRange 192.168.1.250 -SubnetMask 255.255.255.0
        Sets or creates scope with ScopeId 192.168.1.0 with parameters specified.

    .PARAMETER ScopeId
        ScopeId of the DHCP scope

    .PARAMETER Name
        Expected name of the DHCP scope

    .PARAMETER IPStartRange
        Expected startRange of the DHCP scope

    .PARAMETER IPEndRange
        Expected endRange of the DHCP scope

    .PARAMETER SubnetMask
        Expected subnetMask of the DHCP scope

    .PARAMETER Description
        Expected description of the DHCP scope

    .PARAMETER LeaseDuration
        Expected duration of the lease of the DHCP scope

    .PARAMETER AddressFamily
        Expected address family of the DHCP scope

    .PARAMETER State
        Expected state of the DHCP scope

    .PARAMETER Ensure
        Expected presence of the DHCP scope
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPEndRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LeaseDuration,

        [Parameter()]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily = 'IPv4',

        [Parameter()]
        [ValidateSet('Active', 'Inactive')]
        [System.String]
        $State = 'Active',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.SetServerScopeMessage -f $ScopeId
    )

    #region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -ModuleName DHCPServer

    # Check values of IP Addresses used to define the scope
    $ipAddressesAssertionParameters = @{
        ScopeId       = $ScopeId
        IPStartRange  = $IPStartRange
        IPEndRange    = $IPEndRange
        SubnetMask    = $SubnetMask
        AddressFamily = $AddressFamily
    }
    Assert-ScopeParameter @ipAddressesAssertionParameters

    #endregion Input Validation


    if ($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }
    if ($PSBoundParameters.ContainsKey('AddressFamily'))
    {
        $null = $PSBoundParameters.Remove('AddressFamily')
    }

    Update-ResourceProperties @PSBoundParameters -Apply
}

<#
    .SYNOPSIS
        Tests the scope with specified ScopeId.

    .DESCRIPTION
        Used by DSC Resource to perform Test method.
        It will verify that Scope is configured as described in the parameters.

    .EXAMPLE
        Test-TargetResource -ScopeId 192.168.1.0 -Name MyScope -IPStartRange 192.168.1.1 -IPEndRange 192.168.1.250 -SubnetMask 255.255.255.0
        Returns $true if scope is configured as described and $false if it's not

    .PARAMETER ScopeId
        ScopeId of the DHCP scope

    .PARAMETER Name
        Expected name of the DHCP scope

    .PARAMETER IPStartRange
        Expected startRange of the DHCP scope

    .PARAMETER IPEndRange
        Expected endRange of the DHCP scope

    .PARAMETER SubnetMask
        Expected subnetMask of the DHCP scope

    .PARAMETER Description
        Expected description of the DHCP scope

    .PARAMETER LeaseDuration
        Expected duration of the lease of the DHCP scope

    .PARAMETER AddressFamily
        Expected address family of the DHCP scope

    .PARAMETER State
        Expected state of the DHCP scope

    .PARAMETER Ensure
        Expected presence of the DHCP scope
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPEndRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LeaseDuration,

        [Parameter()]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily = 'IPv4',

        [Parameter()]
        [ValidateSet('Active', 'Inactive')]
        [System.String]
        $State = 'Active',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.TestServerScopeMessage -f $ScopeId
    )

    #region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -ModuleName DHCPServer

    # Check values of IP Addresses used to define the scope
    $ipAddressesAssertionParameters = @{
        ScopeId       = $ScopeId
        IPStartRange  = $IPStartRange
        IPEndRange    = $IPEndRange
        SubnetMask    = $SubnetMask
        AddressFamily = $AddressFamily
    }

    Assert-ScopeParameter @ipAddressesAssertionParameters

    #endregion Input Validation

    if ($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }
    if ($PSBoundParameters.ContainsKey('AddressFamily'))
    {
        $null = $PSBoundParameters.Remove('AddressFamily')
    }

    Update-ResourceProperties @PSBoundParameters -Apply:$false
}

function Update-ResourceProperties
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPEndRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SubnetMask,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LeaseDuration,

        [Parameter()]
        [ValidateSet('Active', 'Inactive')]
        [System.String]
        $State = 'Active',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Apply
    )

    # Convert the Lease duration to be a valid timespan
    if ($LeaseDuration)
    {
        $LeaseDuration = (Get-ValidTimeSpan -tsString $LeaseDuration -parameterName 'Leaseduration').ToString()
    }

    $checkScopeMessage = $script:localizedData.CheckScopeMessage -f $ScopeId
    Write-Verbose -Message $checkScopeMessage

    $dhcpScope = Get-DhcpServerv4Scope -ScopeId $ScopeId -ErrorAction 'SilentlyContinue'
    # Initialize the parameter collection
    if ($Apply)
    {
        $parameters = @{}
    }

    # dhcpScope is set
    if ($dhcpScope)
    {
        $TestScopeMessage = $($script:localizedData.TestScopeMessage) -f $ScopeId, 'present', $Ensure
        Write-Verbose -Message $TestScopeMessage

        # if it should be present, test individual properties to match parameter values
        if ($Ensure -eq 'Present')
        {
            #region Test the Scope Name
            $checkPropertyMsg = $($script:localizedData.CheckPropertyMessage) -f 'name'
            Write-Verbose -Message $checkPropertyMsg

            if ($dhcpScope.Name -ne $Name)
            {
                $notDesiredPropertyMsg = $($script:localizedData.NotDesiredPropertyMessage) -f 'name', $Name, $($dhcpScope.Name)
                Write-Verbose -Message $notDesiredPropertyMsg

                if ($Apply)
                {
                    $parameters['Name'] = $Name
                }
                else
                {
                    return $false
                }
            }
            else
            {
                $desiredPropertyMsg = $($script:localizedData.DesiredPropertyMessage) -f 'name'
                Write-Verbose -Message $desiredPropertyMsg
            }
            #endregion scope name

            #region Test the IPStartRange and IPEndRange
            if ($dhcpScope.StartRange -ne $IPStartRange -or $dhcpScope.EndRange -ne $IPEndRange)
            {
                $notDesiredPropertyMsg = $($script:localizedData.NotDesiredPropertyMessage) -f 'Start/EndRange', "$IPStartRange/$IPEndRange", "$($dhcpScope.StartRange)/$($dhcpScope.EndRange)"
                Write-Verbose -Message $notDesiredPropertyMsg

                if ($Apply)
                {
                    $parameters['StartRange'] = $IPStartRange
                    $parameters['EndRange'] = $IPEndRange
                }
                else
                {
                    return $false
                }
            }
            #endregion IPStartRange and IPEndRange

            #region Test the Scope Description
            if ($PSBoundParameters.ContainsKey('Description'))
            {
                $checkPropertyMsg = $($script:localizedData.CheckPropertyMessage) -f 'description'
                Write-Verbose -Message $checkPropertyMsg

                if ($dhcpScope.Description -ne $Description)
                {
                    $notDesiredPropertyMsg = $($script:localizedData.NotDesiredPropertyMessage) -f 'description', $Description, $($dhcpScope.Description)
                    Write-Verbose -Message $notDesiredPropertyMsg

                    if ($Apply)
                    {
                        $parameters['Description'] = $Description
                    }
                    else
                    {
                        return $false
                    }
                }
                else
                {
                    $desiredPropertyMsg = $($script:localizedData.DesiredPropertyMessage) -f 'description'
                    Write-Verbose -Message $desiredPropertyMsg
                }
            }
            #endregion scope description

            #region Test the Lease duration
            if ($PSBoundParameters.ContainsKey('LeaseDuration'))
            {
                $checkPropertyMsg = $($script:localizedData.CheckPropertyMessage) -f 'lease duration'
                Write-Verbose -Message $checkPropertyMsg

                if ($dhcpScope.LeaseDuration -ne $LeaseDuration)
                {
                    $notDesiredPropertyMsg = $($script:localizedData.NotDesiredPropertyMessage) -f 'lease duration', $LeaseDuration, $($dhcpScope.LeaseDuration)
                    Write-Verbose -Message $notDesiredPropertyMsg

                    if ($Apply)
                    {
                        $parameters['LeaseDuration'] = $LeaseDuration
                    }
                    else
                    {
                        return $false
                    }
                }
                else
                {
                    $desiredPropertyMsg = $($script:localizedData.DesiredPropertyMessage) -f 'lease duration'
                    Write-Verbose -Message $desiredPropertyMsg
                }
            }
            #endregion lease duration

            #region Test the Scope State
            if ($PSBoundParameters.ContainsKey('State'))
            {
                $checkPropertyMsg = $($script:localizedData.CheckPropertyMessage) -f 'state'
                Write-Verbose -Message $checkPropertyMsg

                if ($dhcpScope.State -ne $State)
                {
                    $notDesiredPropertyMsg = $($script:localizedData.NotDesiredPropertyMessage) -f 'state', $State, $($dhcpScope.State)
                    Write-Verbose -Message $notDesiredPropertyMsg

                    if ($Apply)
                    {
                        $parameters['State'] = $State
                    }
                    else
                    {
                        return $false
                    }
                }
                else
                {
                    $desiredPropertyMsg = $($script:localizedData.DesiredPropertyMessage) -f 'state'
                    Write-Verbose -Message $desiredPropertyMsg
                }
            }
            #endregion scope state

            #region Test the Subnet Mask
            $checkPropertyMsg = $($script:localizedData.CheckPropertyMessage) -f 'subnet mask'
            Write-Verbose -Message $checkPropertyMsg

            if ($dhcpScope.SubnetMask -ne $SubnetMask)
            {
                $notDesiredPropertyMsg = $($script:localizedData.NotDesiredPropertyMessage) -f 'subnet mask', $SubnetMask, $($dhcpScope.SubnetMask)
                Write-Verbose -Message $notDesiredPropertyMsg

                if ($Apply)
                {
                    try
                    {
                        # To set the subnet mask scope, the only ways is to remove the old scope and add a new scope
                        Remove-DhcpServerv4Scope -ScopeId $ScopeId

                        ## We can't splat two hashtables and $parameters may be empty, so just clone the existing one
                        $addDhcpServerv4ScopeParams = $parameters.Clone()
                        $addDhcpServerv4ScopeParams['Type'] = 'Dhcp'
                        $addDhcpServerv4ScopeParams['StartRange'] = $IPStartRange
                        $addDhcpServerv4ScopeParams['EndRange'] = $IPEndRange
                        $addDhcpServerv4ScopeParams['Name'] = $Name
                        $addDhcpServerv4ScopeParams['SubnetMask'] = $SubnetMask

                        Add-DhcpServerv4Scope @addDhcpServerv4ScopeParams
                    }
                    catch
                    {
                        New-TerminatingError -errorId DhcpServerScopeFailure -errorMessage $_.Exception.Message -errorCategory InvalidOperation
                    }

                    $setPropertyMsg = $($script:localizedData.SetPropertyMessage) -f 'subnet mask', $SubnetMask
                    Write-Verbose -Message $setPropertyMsg
                }
                else
                {
                    return $false
                }
            }
            else
            {
                $desiredPropertyMsg = $($script:localizedData.DesiredPropertyMessage) -f 'subnet mask'
                Write-Verbose -Message $desiredPropertyMsg
            }
            #endregion subnet mask

            if ($Apply)
            {
                # If parameters contains more than 0 key, set the DhcpServer scope
                if ($parameters.Count -gt 0)
                {
                    Set-DhcpServerv4Scope @parameters -ScopeId $dhcpScope.ScopeId

                    Write-PropertyMessage -Parameters $parameters -keysToSkip ScopeId `
                        -Message $($script:localizedData.SetPropertyMessage) -Verbose
                }
            } # end Apply
            else
            {
                return $true
            }
        } # end ensure eq present

        # If dhcpscope should be absent
        else
        {
            if ($Apply)
            {
                $removingScopeMsg = $script:localizedData.RemovingScopeMessage -f $ScopeId
                Write-Verbose -Message $removingScopeMsg

                # Remove the scope
                Remove-DhcpServerv4Scope -ScopeId $ScopeId

                $deleteScopeMsg = $script:localizedData.deleteScopeMessage -f $ScopeId
                Write-Verbose -Message $deleteScopeMsg
            }
            else
            {
                return $false
            }
        }# end ensure -eq 'Absent'
    } # if $dhcpScope

    #If dhcpScope is not set, create it if needed
    else
    {
        $TestScopeMessage = $($script:localizedData.TestScopeMessage) -f $ScopeId, 'absent', $Ensure
        Write-Verbose -Message $TestScopeMessage

        if ($Ensure -eq 'Present')
        {
            if ($Apply)
            {
                # Add mandatory parameters
                $parameters['Name'] = $Name
                $parameters['StartRange'] = $IPStartRange
                $parameters['EndRange'] = $IPEndRange
                $parameters['SubnetMask'] = $SubnetMask

                # Check if Lease duration is specified, add to parameter collection
                if ($PSBoundParameters.ContainsKey('LeaseDuration'))
                {
                    $parameters['LeaseDuration'] = $LeaseDuration
                }

                # Check if State is specified, add to parameter collection
                if ($PSBoundParameters.ContainsKey('State'))
                {
                    $parameters['State'] = $State
                }

                $addingScopeMessage = $script:localizedData.AddingScopeMessage -f $ScopeId
                Write-Verbose -Message $addingScopeMessage

                try
                {
                    # Create a new scope with specified properties
                    Add-DhcpServerv4Scope @parameters -Type dhcp

                    $setScopeMessage = $($script:localizedData.SetScopeMessage) -f $Name
                    Write-Verbose -Message $setScopeMessage
                }
                catch
                {
                    New-TerminatingError -errorId DhcpServerScopeFailure -errorMessage $_.Exception.Message -errorCategory InvalidOperation
                }
            }# end Apply
            else
            {
                return $false
            }
        } # end Ensure -eq Present
        else
        {
            return $true
        }
    } # else !dhcpscope
}

Export-ModuleMember -Function *-TargetResource
