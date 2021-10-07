Configuration VMIPAddress
{
    Import-DscResource -ModuleName cHyper-V -Name cVMIPAddress
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMIPAddress VMAdapter1IPAddress {
        Id = 'VMMgmt-NIC'
        NetAdapterName = 'VMMgmt-NIC'
        VMName = 'SQLVM01'
        IPAddress = 'DHCP'
    }
}
