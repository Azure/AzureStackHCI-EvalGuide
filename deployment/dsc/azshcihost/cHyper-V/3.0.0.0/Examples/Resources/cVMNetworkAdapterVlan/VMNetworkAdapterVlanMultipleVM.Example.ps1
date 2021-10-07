Configuration HostOSAdapterVlan
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterVlan
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapterVlan VMMgmtAdapterVlan {
        Id = 'VMManagement-NIC'
        Name = 'VMManagement-NIC'
        VMName = 'SQLVM01'
        AdapterMode = 'Access'
        VlanId = 10
    }

    cVMNetworkAdapterVlan VMiSCSIAdapterVlan {
        Id = 'VMiSCSI-NIC'
        Name = 'VMiSCSI-NIC'
        VMName = 'SQLVM01'
        AdapterMode = 'Untagged'
    }
}
