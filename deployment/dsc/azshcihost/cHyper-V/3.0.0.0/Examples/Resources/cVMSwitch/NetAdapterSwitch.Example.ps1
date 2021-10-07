Configuration SimpleNetAdaptervSwitch
{
    Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMSwitch HostSwitch {
        Name = 'HostSwitch'
        Type = 'External'
        AllowManagementOS = $true
        NetAdapterName = 'NIC1'
        Ensure = 'Present'
    }
}
