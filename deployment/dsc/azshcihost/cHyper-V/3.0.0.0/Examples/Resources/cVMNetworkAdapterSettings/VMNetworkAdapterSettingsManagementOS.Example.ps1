Configuration HostOSAdapterSettings
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterSettings
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapterSettings HostOSAdapterSettings {
        Id = 'Management-NIC'
        Name = 'Management-NIC'
        VMName = 'ManagementOS'
        SwitchName = 'SETSwitch'
        MinimumBandwidthWeight = 20
    }
}
