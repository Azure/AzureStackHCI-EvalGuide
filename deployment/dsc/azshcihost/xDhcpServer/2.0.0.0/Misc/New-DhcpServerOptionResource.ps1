$Properties = @{
    DnsServer     = New-xDscResourceProperty -Name DnsServerIPAddress -Type String[] -Attribute Required `
                                         -Description 'IP address of DNS Servers'
    Router     = New-xDscResourceProperty -Name Router -Type String[] -Attribute Required `
                                         -Description 'IP address of the router/default gateway.'
    DnsDomain     = New-xDscResourceProperty -Name DnsDomain -Type String -Attribute Write `
                                         -Description 'Domain name of DNS Server'
    AddressFamily = New-xDscResourceProperty -Name AddressFamily -Type String -Attribute Write `
                                        -ValidateSet 'IPv4' -Description 'Address family type'
    ScopeID       = New-xDscResourceProperty -Name ScopeID -Type String -Attribute Key `
                                       -Description 'ScopeId for which options are set'
    Ensure        = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write `
                                      -ValidateSet 'Present','Absent' `
                                      -Description 'Whether option should be set or removed'
}

New-xDscResource -Name MSFT_xDhcpServerOption -Property $Properties.Values -ModuleName xDhcpServer -FriendlyName xDhcpServerOption
