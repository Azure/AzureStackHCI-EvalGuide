Configuration InternalSwitch
{
    Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMSwitch HostSwitch {
        Name = 'HostSwitch'
        Type = 'Internal'
        Ensure = 'Present'
    }
}
