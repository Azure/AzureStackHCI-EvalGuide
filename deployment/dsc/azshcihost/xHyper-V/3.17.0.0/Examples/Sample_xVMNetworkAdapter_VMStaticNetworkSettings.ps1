Configuration VMAdapter
{
    Import-DscResource -ModuleName xHyper-V -Name xVMNetworkAdapter
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    xVMNetworkAdapter MyVM01NIC {
        Id = 'MyVM01-NIC'
        Name = 'MyVM01-NIC'
        SwitchName = 'SETSwitch'
        MacAddress = '001523be0c'
        VMName = 'MyVM01'
        NetworkSetting = xNetworkSettings {
            IpAddress = "192.168.0.100"
            Subnet = "255.255.255.255"
            DefaultGateway = "192.168.0.1"
            DnsServer = "192.168.0.1"
        }
        Ensure = 'Present'
    }
}
