<#
    .SYNOPSiS
       This example sets an option ID 8 (cookie servers) on a a reserved IP level.
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

    DhcpReservedIPOptionValue ReservedIPOptionValue_ID-008
    {
        ReservedIP    = '192.168.0.1'
        OptionId      = 8
        Value         ='1.1.1.1'
        VendorClass   = ''
        UserClass     = ''
        AddressFamily = 'IPv4'
        Ensure        = 'Present'
    }
}
