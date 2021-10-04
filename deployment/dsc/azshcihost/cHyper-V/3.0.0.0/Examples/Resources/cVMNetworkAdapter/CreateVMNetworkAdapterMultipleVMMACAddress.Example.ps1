Configuration VMAdapter
{
    Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapter
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    cVMNetworkAdapter MyVM01NIC {
        Id = 'MyVM01-NIC'
        Name = 'MyVM01-NIC'
        SwitchName = 'SETSwitch'
        MacAddress = '001523be0c'
        VMName = 'MyVM01'
        Ensure = 'Present'
    }

    cVMNetworkAdapter MyVM02NIC {
        Id = 'MyVM02-NIC'
        Name = 'MyVM02-NIC'
        SwitchName = 'SETSwitch'
        MacAddress = '001523be0d'
        VMName = 'MyVM02'
        Ensure = 'Present'
    }
}
