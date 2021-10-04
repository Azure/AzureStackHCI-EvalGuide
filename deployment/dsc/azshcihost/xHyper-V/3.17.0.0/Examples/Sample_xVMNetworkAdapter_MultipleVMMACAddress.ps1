Configuration VMAdapter
{
    Import-DscResource -ModuleName xHyper-V -Name xVMNetworkAdapter
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    xVMNetworkAdapter MyVM01NIC {
        Id = 'MyVM01-NIC'
        Name = 'MyVM01-NIC'
        SwitchName = 'SETSwitch'
        MacAddress = '001523be0c'
        VMName = 'MyVM01'
        Ensure = 'Present'
    }

    xVMNetworkAdapter MyVM02NIC {
        Id = 'MyVM02-NIC'
        Name = 'MyVM02-NIC'
        SwitchName = 'SETSwitch'
        MacAddress = '001523be0d'
        VMName = 'MyVM02'
        Ensure = 'Present'
    }
}
