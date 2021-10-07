$Properties = @{
    ScopeID       = New-xDscResourceProperty -Name ScopeID -Type String -Attribute Read `
                                             -Description 'ScopeId for which properties are set'
    Name          = New-xDscResourceProperty -Name Name -Type String -Attribute Required `
                                         -Description 'Name of DHCP Scope'
    AddressFamily = New-xDscResourceProperty -Name AddressFamily -Type String -Attribute Write `
                                        -ValidateSet 'IPv4' -Description 'Address family type'
    IPStartRange  = New-xDscResourceProperty -Name IPStartRange -Type String -Attribute Key `
                                            -Description 'Starting address to set for this scope'
    IPEndRange    = New-xDscResourceProperty -Name IPEndRange -Type String -Attribute Key `
                                            -Description 'Ending address to set for this scope'
    SubnetMask    = New-xDscResourceProperty -Name SubnetMask -Type String -Attribute Write `
                                         -Description 'Subnet mask for the scope specified in IP address format'
    LeaseDuration = New-xDscResourceProperty -Name LeaseDuration -Type String -Attribute Write `
                                         -Description 'Time interval for which an IP address should be leased'
    State         = New-xDscResourceProperty -Name State -Type String -Attribute Write `
                                      -ValidateSet 'Active','Inactive' `
                                      -Description 'Whether scope should be active or inactive'
    Ensure        = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write `
                                      -ValidateSet 'Present','Absent' `
                                      -Description 'Whether scope should be set or removed'
}

New-xDscResource -Name MSFT_xDhcpServerScope -Property $Properties.Values -ModuleName xDhcpServer -FriendlyName xDhcpServerScope
