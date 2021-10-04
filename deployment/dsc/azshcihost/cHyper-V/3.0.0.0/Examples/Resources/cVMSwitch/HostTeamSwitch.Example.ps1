Configuration SimpleHostTeamvSwitch
{
    Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMSwitch HostSwitch {
        Name = 'HostSwitch'
        Type = 'External'
        AllowManagementOS = $true
        MinimumBandwidthMode = 'Weight'
        NetAdapterName = 'HostTeam'
        Ensure = 'Present'
    }
}
