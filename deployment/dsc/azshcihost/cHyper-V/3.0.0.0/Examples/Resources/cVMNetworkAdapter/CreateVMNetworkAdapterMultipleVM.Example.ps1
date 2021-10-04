Configuration VMAdapter
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapter
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapter MyVM01NIC {
        Id = 'MyVM01-NIC'
        Name = 'MyVM01-NIC'
        SwitchName = 'SETSwitch'
        VMName = 'MyVM01'
        Ensure = 'Present'
    }

    cVMNetworkAdapter MyVM02NIC {
        Id = 'MyVM02-NIC'
        Name = 'NetAdapter'
        SwitchName = 'SETSwitch'
        VMName = 'MyVM02'
        Ensure = 'Present'
    }

    cVMNetworkAdapter MyVM03NIC {
        Id = 'MyVM03-NIC'
        Name = 'NetAdapter'
        SwitchName = 'SETSwitch'
        VMName = 'MyVM03'
        Ensure = 'Present'
    }    
}
