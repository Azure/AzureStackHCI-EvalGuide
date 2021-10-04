Configuration SETTeamSwitch
{
    Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMSwitch HostSwitch {
        Name = 'HostSwitch'
        Type = 'External'
        AllowManagementOS = $true
        MinimumBandwidthMode = 'Weight'
        TeamingMode = 'SwitchIndependent'
        LoadBalancingAlgorithm = 'HyperVPort'
        NetAdapterName = 'NIC1','NIC2','NIC3','NIC4'
        Ensure = 'Present'
    }
}
