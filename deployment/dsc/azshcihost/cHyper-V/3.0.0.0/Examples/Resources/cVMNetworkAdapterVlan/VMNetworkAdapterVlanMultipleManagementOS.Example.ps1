Configuration HostOSAdapterVlan
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterVlan
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapterVlan HostOSAdapterVlan {
        Id = 'Management-NIC'
        Name = 'Management-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Access'
        VlanId = 10
    }

    cVMNetworkAdapterVlan ClusterAdapterVlan {
        Id = 'Cluster-NIC'
        Name = 'Cluster-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Access'
        VlanId = 20
    }

    #The following configuration removes any VLAN setting, if present.
    cVMNetworkAdapterVlan JustAnotherAdapterVlan {
        Id = 'JustAnother-NIC'
        Name = 'JustAnother-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Untagged'
    }
}
