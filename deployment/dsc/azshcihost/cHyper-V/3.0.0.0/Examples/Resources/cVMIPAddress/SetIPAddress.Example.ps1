Configuration VMIPAddress
{
    Import-DscResource -ModuleName cHyper-V -Name cVMIPAddress
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMIPAddress VMAdapter1IPAddress {
        Id = 'VMMgmt-NIC'
        NetAdapterName = 'VMMgmt-NIC'
        VMName = 'SQLVM01'
        IPAddress = '172.16.101.101'
        DefaultGateway = '172.16.101.1'
        Subnet = '255.255.255.0'
        DnsServer = '172.16.101.2'
    }
}
