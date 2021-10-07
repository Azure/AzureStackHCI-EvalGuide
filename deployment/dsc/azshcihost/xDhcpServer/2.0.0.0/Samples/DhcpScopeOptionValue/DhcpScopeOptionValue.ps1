<#
    .SYNOPSiS
        This example shows how to substitute the xDhcpServerOption resource, setting the gateway (option 3), DNS Servers (option 6) and domain name (Option 15).
#>
configuration Example
{
    Import-DscResource -ModuleName PSDscResources
    Import-DscResource -moduleName xDhcpServer
    WindowsFeature DHCP
    {
       Name = 'DHCP'
       Ensure = 'Present'
    }

    # Setting scope gateway
    DhcpScopeOptionValue scopeOptionGateway
    {
        OptionId = 3
        Value = 1.1.1.1
        ScopeId =   '1.1.1.0'
        VendorClass = ''
        UserClass   = ''
        AddressFamily = 'IPv4'
    }

    # Setting scope DNS servers
    DhcpScopeOptionValue scopeOptionDNS
    {
        OptionId = 6
        Value = 1.1.1.1,2.2.2.2
        ScopeId =   '1.1.1.0'
        VendorClass = ''
        UserClass   = ''
        AddressFamily = 'IPv4'
    }

    # Setting scope DNS domain name
    DhcpScopeOptionValue scopeOptionDNSDomainName
    {
        OptionId = 15
        Value = 'Contoso.com'
        ScopeId =   '1.1.1.0'
        VendorClass = ''
        UserClass   = ''
        AddressFamily = 'IPv4'
    }
}
