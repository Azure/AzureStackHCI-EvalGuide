Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
InvalidScopeIDMessage      = DHCP server scopeID {0} is not valid. Supply a valid scopeID and try again
CheckingReservationMessage = Checking DHCP server reservation in scope id {0} for IP address {1} ...
TestReservationMessage     = DHCP server reservation in the given scope id for the IP address is {0} and it should be {1} 
RemovingReservationMessage = Removing DHCP server reservation from scope id {0} for MAC address {1} ...
DeleteReservationMessage   = DHCP server reservation for the given MAC address is now absent
AddingReservationMessage   = Adding DHCP server reservation with the given IP address ...
SetReservationMessage      = DHCP server reservation in the given scope id for the IP address {0} is now present

CheckPropertyMessage       = Checking DHCP server reservation {0} for the given ipaddress ...
NotDesiredPropertyMessage  = DHCP server reservation for the given ipaddress doesn't have correct {0}. Expected {1}, actual {2}
DesiredPropertyMessage     = DHCP server reservation {0} for the given ipaddress is correct.
SetPropertyMessage         = DHCP server reservation {0} for the given ipaddress is set.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String]$ScopeID,

        [parameter(Mandatory)]
        [String]$ClientMACAddress,

        [parameter(Mandatory)]
        [String]$IPAddress,

        [ValidateSet("IPv4")]
        [String]$AddressFamily = 'IPv4'
    )

#region input validation
    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer
    
    # Convert the ScopeID to be a valid IPAddress
    $ScopeID = (Get-ValidIpAddress -ipString $ScopeID -AddressFamily $AddressFamily -parameterName 'ScopeID').ToString()

    # Test if the ScopeID is valid
    $null = Get-DhcpServerv4Scope -ScopeId $ScopeID -ErrorAction SilentlyContinue -ErrorVariable err
    if($err)
    {
        $errorMsg = $($LocalizedData.InvalidScopeIdMessage) -f $ScopeID
        New-TerminatingError -errorId ScopeIdNotFound -errorMessage $errorMsg -errorCategory InvalidOperation
    }

    # Convert the Start Range to be a valid IPAddress
    $IPAddress = (Get-ValidIpAddress -ipString $IPAddress -AddressFamily $AddressFamily -parameterName 'IPAddress').ToString()
    
#endregion input validation

    $reservation = Get-DhcpServerv4Reservation -ScopeID $ScopeID | Where-Object IPAddress -eq $IPAddress
    
    if($reservation)
    {
        $ensure = 'Present'
    }
    else
    {
        $ensure = 'Absent'
    }

    @{
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
        [parameter(Mandatory)]
        [String]$ScopeID,

        [parameter(Mandatory)]
        [String]$ClientMACAddress,

        [parameter(Mandatory)]
        [String]$IPAddress,

        [String]$Name,

        [ValidateSet("IPv4")]
        [String]$AddressFamily = 'IPv4',

        [ValidateSet("Present","Absent")]
        [String]$Ensure = 'Present'
    )

    if($PSBoundParameters.ContainsKey('Debug')){ $null = $PSBoundParameters.Remove('Debug')}
    if($PSBoundParameters.ContainsKey('AddressFamily')) {$null = $PSBoundParameters.Remove('AddressFamily')}

    Validate-ResourceProperties @PSBoundParameters -Apply
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [String]$ScopeID,

        [parameter(Mandatory)]
        [String]$ClientMACAddress,

        [parameter(Mandatory)]
        [String]$IPAddress,

        [String]$Name,

        [ValidateSet("IPv4")]
        [String]$AddressFamily = 'IPv4',

        [ValidateSet("Present","Absent")]
        [String]$Ensure = 'Present'
    )

#region input validation
    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    # Convert the ScopeID to be a valid IPAddress
    $ScopeID = (Get-ValidIpAddress -ipString $ScopeID -AddressFamily $AddressFamily -parameterName 'ScopeID').ToString()

    # Test if the ScopeID is valid
    $null = Get-DhcpServerv4Scope -ScopeId $ScopeID -ErrorAction SilentlyContinue -ErrorVariable err
    if($err)
    {
        $errorMsg = $($LocalizedData.InvalidScopeIdMessage) -f $ScopeID
        New-TerminatingError -errorId ScopeIdNotFound -errorMessage $errorMsg -errorCategory InvalidOperation
    }

    # Convert the Start Range to be a valid IPAddress
    $IPAddress = (Get-ValidIpAddress -ipString $IPAddress -AddressFamily $AddressFamily -parameterName 'IPAddress').ToString()

    #Convert the MAC Address into normalized form for comparison
    $ClientMACAddress = $ClientMACAddress.Replace('-','') 

#endregion input validation
    
    if($PSBoundParameters.ContainsKey('Debug')){ $null = $PSBoundParameters.Remove('Debug')}
    if($PSBoundParameters.ContainsKey('AddressFamily')) {$null = $PSBoundParameters.Remove('AddressFamily')}

    Validate-ResourceProperties @PSBoundParameters
}

#region Helper function

# Internal function to validate dhcpOptions properties
function Validate-ResourceProperties
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [String]$ScopeID,

        [parameter(Mandatory)]
        [String]$ClientMACAddress,

        [parameter(Mandatory)]
        [String]$IPAddress,

        [String]$Name,

        [ValidateSet("IPv4")]
        [String]$AddressFamily = 'IPv4',

        [ValidateSet("Present","Absent")]
        [String]$Ensure = 'Present',

        [Switch]$Apply
    )

    $reservationMessage = $($LocalizedData.CheckingReservationMessage) -f $ScopeID, $IPAddress
    Write-Verbose -Message $reservationMessage
    
    $reservation = Get-DhcpServerv4Reservation -ScopeID $ScopeID | Where-Object IPAddress -eq $IPAddress

    # Initialize the parameter collection
    if($Apply)
    { 
        $parameters = @{IPAddress = $IPAddress}
    }
    # Found DHCP reservation
    if($reservation)
    {
        $TestReservationMessage = $($LocalizedData.TestReservationMessage) -f 'present', $Ensure
        Write-Verbose -Message $TestReservationMessage
                
        # if it should be present, test individual properties to match parameter values
        if($Ensure -eq 'Present')
        {    
            #Convert the MAC Address into normalized form for comparison
            $normalizedClientID = $reservation.ClientId.Replace('-','')

            #region Test MAC address
            $checkPropertyMsg = $($LocalizedData.CheckPropertyMessage) -f 'client MAC address'
            Write-Verbose -Message $checkPropertyMsg
            
            if($normalizedClientID -ne $ClientMACAddress)
            {
                $notDesiredPropertyMsg = $($LocalizedData.NotDesiredPropertyMessage) -f 'client MAC address',$ClientMACAddress,$normalizedClientID
                Write-Verbose -Message $notDesiredPropertyMsg

                if($Apply)
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
                $desiredPropertyMsg = $($LocalizedData.DesiredPropertyMessage) -f 'client MAC address'
                Write-Verbose -Message $desiredPropertyMsg
            }
            #endregion Test MAC address

            #region Test reservation name
            $checkPropertyMsg = $($LocalizedData.CheckPropertyMessage) -f 'name'
            Write-Verbose -Message $checkPropertyMsg
            
            if($reservation.Name -ne $Name)
            {
                $notDesiredPropertyMsg = $($LocalizedData.NotDesiredPropertyMessage) -f 'name',$Name,$($reservation.Name)
                Write-Verbose -Message $notDesiredPropertyMsg

                if($Apply)
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
                $desiredPropertyMsg = $($LocalizedData.DesiredPropertyMessage) -f 'name'
                Write-Verbose -Message $desiredPropertyMsg
            }
            #endregion Test reservation name

            if($Apply)
            {
                # If parameters contains more than 1 key, set the DhcpServer reservation
                if($parameters.Count -gt 1) 
                {
                    Set-DhcpServerv4Reservation @parameters

                    Write-PropertyMessage -Parameters $parameters -keysToSkip IPAddress `
                                          -Message $($LocalizedData.SetPropertyMessage) -Verbose
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
            if($Apply)
            {
                $removingReservationMsg = $($LocalizedData.RemovingReservationMessage) -f $ScopeID,$ClientMACAddress
                Write-Verbose -Message $removingReservationMsg

                # Remove the reservation
                Remove-DhcpServerv4Reservation -ScopeId $ScopeID -ClientId $ClientMACAddress

                $deleteReservationMsg = $LocalizedData.deleteReservationMessage
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
           $TestReservationMessage = $($LocalizedData.TestReservationMessage) -f 'absent', $Ensure
            Write-Verbose -Message $TestReservationMessage

            if($Ensure -eq 'Present')
            {
                if($Apply)
                {
                    # Add other mandatory parameters
                    $parameters['ScopeId']  = $ScopeID
                    $parameters['ClientId'] = $ClientMACAddress

                    # Check if reservation name is specified, add to parameter collection
                    if($PSBoundParameters.ContainsKey('Name'))
                    {
                        $parameters['Name'] = $Name
                    }

                    $addingReservationeMessage = $LocalizedData.AddingReservationMessage
                    Write-Verbose -Message $addingReservationeMessage

                    try
                    {
                        # Create a new scope with specified properties
                        Add-DhcpServerv4Reservation @parameters

                        $setReservationMessage = $($LocalizedData.SetReservationMessage) -f $Name
                        Write-Verbose -Message $setReservationMessage
                    }
                    catch
                    {
                        New-TerminatingError -errorId DhcpServerReservationFailure -errorMessage $_.Exception.Message -errorCategory InvalidOperation
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

