$Properties = @{
    ScopeID          = New-xDscResourceProperty -Name ScopeID -Type String -Attribute Key `
                                              -Description 'ScopeId for which reservations are set'
    IPAddress        = New-xDscResourceProperty -Name IPAddress -Type String -Attribute Required `
                                         -Description 'IP address of the reservation for which the properties are modified'
    ClientMACAddress = New-xDscResourceProperty -Name ClientMACAddress -Type String -Attribute Required `
                                         -Description 'Client ID to set on the reservation For Windows clients it is the MAC address'
    Name             = New-xDscResourceProperty -Name Name -Type String -Attribute Write `
                                         -Description 'Reservation name'
    AddressFamily    = New-xDscResourceProperty -Name AddressFamily -Type String -Attribute Write `
                                        -ValidateSet 'IPv4' -Description 'Address family type'
    Ensure           = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write `
                                      -ValidateSet 'Present','Absent' `
                                      -Description 'Whether option should be set or removed'
}

New-xDscResource -Name MSFT_xDhcpServerReservation -Property $Properties.Values -ModuleName xDhcpServer -FriendlyName xDhcpServerReservation
