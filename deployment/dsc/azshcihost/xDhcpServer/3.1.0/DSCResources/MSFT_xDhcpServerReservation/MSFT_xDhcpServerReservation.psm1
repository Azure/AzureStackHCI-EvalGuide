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
        [System.String]
        $ScopeID,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ClientMACAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily = 'IPv4'
    )

    Write-Verbose -Message (
        $script:localizedData.GetServerReservationMessage -f $ScopeID
    )

    #region input validation
    # Check for DhcpServer module/role
    Assert-Module -ModuleName DHCPServer

    # Convert the ScopeID to be a valid IPAddress
    $ScopeID = (Get-ValidIpAddress -ipString $ScopeID -AddressFamily $AddressFamily -parameterName 'ScopeID').ToString()

    # Test if the ScopeID is valid
    $null = Get-DhcpServerv4Scope -ScopeId $ScopeID -ErrorAction 'SilentlyContinue' -ErrorVariable err
    if ($err)
    {
        $errorMessage = $script:localizedData.InvalidScopeIdMessage -f $ScopeID
        New-InvalidOperationException -Message $errorMessage
    }

    # Convert the Start Range to be a valid IPAddress
    $IPAddress = (Get-ValidIpAddress -ipString $IPAddress -AddressFamily $AddressFamily -parameterName 'IPAddress').ToString()

    #endregion input validation

    $reservation = Get-DhcpServerv4Reservation -ScopeID $ScopeID | Where-Object -FilterScript {
        $_.IPAddress -eq $IPAddress
    }

    if ($reservation)
    {
        $ensure = 'Present'
    }
    else
    {
        $ensure = 'Absent'
    }

    return @{
        ScopeID          = $ScopeID
        IPAddress        = $IPAddress
        ClientMACAddress = $reservation.ClientId
        Name             = $reservation.Name
        AddressFamily    = $AddressFamily
        Ensure           = $Ensure
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeID,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ClientMACAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily = 'IPv4',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.SetServerReservationMessage -f $ScopeID
    )

    if ($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }

    if ($PSBoundParameters.ContainsKey('AddressFamily'))
    {
        $null = $PSBoundParameters.Remove('AddressFamily')
    }

    $null = Update-ResourceProperties @PSBoundParameters -Apply
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeID,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ClientMACAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily = 'IPv4',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message (
        $script:localizedData.TestServerReservationMessage -f $ScopeID
    )

    #region input validation
    # Check for DhcpServer module/role
    Assert-Module -ModuleName DHCPServer

    # Convert the ScopeID to be a valid IPAddress
    $ScopeID = (Get-ValidIpAddress -ipString $ScopeID -AddressFamily $AddressFamily -parameterName 'ScopeID').ToString()

    # Test if the ScopeID is valid
    $null = Get-DhcpServerv4Scope -ScopeId $ScopeID -ErrorAction 'SilentlyContinue' -ErrorVariable err
    if ($err)
    {
        $errorMessage = $script:localizedData.InvalidScopeIdMessage -f $ScopeID
        New-InvalidOperationException -Message $errorMessage
    }

    # Convert the Start Range to be a valid IPAddress
    $IPAddress = (Get-ValidIpAddress -ipString $IPAddress -AddressFamily $AddressFamily -parameterName 'IPAddress').ToString()

    #Convert the MAC Address into normalized form for comparison
    $ClientMACAddress = $ClientMACAddress.Replace('-', '')

    #endregion input validation

    if ($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }

    if ($PSBoundParameters.ContainsKey('AddressFamily'))
    {
        $null = $PSBoundParameters.Remove('AddressFamily')
    }

    return Update-ResourceProperties @PSBoundParameters
}

#region Helper function

# Internal function to validate dhcpOptions properties
function Update-ResourceProperties
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeID,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ClientMACAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('IPv4')]
        [System.String]
        $AddressFamily = 'IPv4',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Apply
    )

    $reservationMessage = $script:localizedData.CheckingReservationMessage -f $ScopeID, $IPAddress
    Write-Verbose -Message $reservationMessage

    $reservation = Get-DhcpServerv4Reservation -ScopeID $ScopeID | Where-Object -FilterScript {
        $_.IPAddress -eq $IPAddress
    }

    # Initialize the parameter collection
    if ($Apply)
    {
        $parameters = @{
            IPAddress = $IPAddress
        }
    }
    # Found DHCP reservation
    if ($reservation)
    {
        $TestReservationMessage = $($script:localizedData.TestReservationMessage) -f 'present', $Ensure
        Write-Verbose -Message $TestReservationMessage

        # if it should be present, test individual properties to match parameter values
        if ($Ensure -eq 'Present')
        {
            #Convert the MAC Address into normalized form for comparison
            $normalizedClientID = $reservation.ClientId.Replace('-', '')

            #region Test MAC address
            $checkPropertyMsg = $($script:localizedData.CheckPropertyMessage) -f 'client MAC address'
            Write-Verbose -Message $checkPropertyMsg

            if ($normalizedClientID -ne $ClientMACAddress)
            {
                $notDesiredPropertyMsg = $($script:localizedData.NotDesiredPropertyMessage) -f 'client MAC address', $ClientMACAddress, $normalizedClientID
                Write-Verbose -Message $notDesiredPropertyMsg

                if ($Apply)
                {
                    $parameters['ClientID'] = $ClientMACAddress
                }
                else
                {
                    return $false
                }
            } # end ClientID ne ClientMACAddress
            else
            {
                $desiredPropertyMsg = $($script:localizedData.DesiredPropertyMessage) -f 'client MAC address'
                Write-Verbose -Message $desiredPropertyMsg
            }
            #endregion Test MAC address

            #region Test reservation name
            $checkPropertyMsg = $($script:localizedData.CheckPropertyMessage) -f 'name'
            Write-Verbose -Message $checkPropertyMsg

            if ($reservation.Name -ne $Name)
            {
                $notDesiredPropertyMsg = $($script:localizedData.NotDesiredPropertyMessage) -f 'name', $Name, $($reservation.Name)
                Write-Verbose -Message $notDesiredPropertyMsg

                if ($Apply)
                {
                    $parameters['Name'] = $Name
                }
                else
                {
                    return $false
                }
            } # end reservation.Name -ne Name
            else
            {
                $desiredPropertyMsg = $($script:localizedData.DesiredPropertyMessage) -f 'name'
                Write-Verbose -Message $desiredPropertyMsg
            }
            #endregion Test reservation name

            if ($Apply)
            {
                # If parameters contains more than 1 key, set the DhcpServer reservation
                if ($parameters.Count -gt 1)
                {
                    Set-DhcpServerv4Reservation @parameters

                    Write-PropertyMessage -Parameters $parameters -keysToSkip IPAddress `
                        -Message $($script:localizedData.SetPropertyMessage) -Verbose
                }
            } # end Apply
            else
            {
                return $true
            }
        } # end ensure -eq present

        # If dhcpreservation should be absent
        else
        {
            if ($Apply)
            {
                $removingReservationMsg = $($script:localizedData.RemovingReservationMessage) -f $ScopeID, $ClientMACAddress
                Write-Verbose -Message $removingReservationMsg

                # Remove the reservation
                Remove-DhcpServerv4Reservation -ScopeId $ScopeID -ClientId $ClientMACAddress

                $deleteReservationMsg = $script:localizedData.deleteReservationMessage
                Write-Verbose -Message $deleteReservationMsg
            }
            else
            {
                return $false
            }
        } # end ensure -eq absent
    } # end found resevation

    else
    {
        $TestReservationMessage = $($script:localizedData.TestReservationMessage) -f 'absent', $Ensure
        Write-Verbose -Message $TestReservationMessage

        if ($Ensure -eq 'Present')
        {
            if ($Apply)
            {
                # Add other mandatory parameters
                $parameters['ScopeId'] = $ScopeID
                $parameters['ClientId'] = $ClientMACAddress

                # Check if reservation name is specified, add to parameter collection
                if ($PSBoundParameters.ContainsKey('Name'))
                {
                    $parameters['Name'] = $Name
                }

                $addingReservationeMessage = $script:localizedData.AddingReservationMessage
                Write-Verbose -Message $addingReservationeMessage

                try
                {
                    # Create a new scope with specified properties
                    Add-DhcpServerv4Reservation @parameters

                    $setReservationMessage = $($script:localizedData.SetReservationMessage) -f $Name
                    Write-Verbose -Message $setReservationMessage
                }
                catch
                {
                    $errorMessage = $script:localizedData.DhcpServerReservationFailure -f $ScopeID
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
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
    } # end ! reservation
}

#endregion

Export-ModuleMember -Function *-TargetResource
