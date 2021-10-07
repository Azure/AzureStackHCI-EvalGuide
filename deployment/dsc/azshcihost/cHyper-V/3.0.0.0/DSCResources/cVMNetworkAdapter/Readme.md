#Using cVMNetworkAdapter resource#
This DSC resource can be used to attach network adapters to VM switches and add them to either management OS or virtual machines on the host.

![](http://i.imgur.com/KVSWBo8.png)

The *Id* property is the unique key within this DSC resource. This property isn't related to any VM network adapter configuration but instead used as a way to uniquely identify each VM network adapter resource in a configuration. This property was introduced in an earlier version of this resource to ensure you can add netowrk adapter with the same name to different virtual machines. Make a note of that. **This won't still let you create two network adapters with the same name and attach them to same VM.** When configuring management OS or VM with multiple network adapters, you should still use unique name for each network adapter. *DO NOT USE A GUID AS AN ARGUMENT. ESPECIALLY, DYNAMICALLY GENERATED GUIDs*

In the previous version of this DSC resource, *Name* property was the key property. Having *Name* as the key property prevented creating network adapters with the same name and attach them to different VMs. So, if you need to add a network adapter to the management OS, specify *VMName* as 'ManagementOS'. If the value of *VMName* property is not 'ManagementOS', it will be considered a Virtual Machine configuration and a network adapter will be added to VM on the Hyper-V host.

The *Name* property and *SwitchName* property identify the name to be assigned to the VM network adapter and the name of the switch to attach to. 

If you want to assign a static MAC address to the VM network adapter, you can use the *MacAddress* property. Providing a value to this property sets the static MAC address on the VM network adapter. Removing this value will make it a dynamic MAC address. This can be used only with the virtual machine adapters and not management OS.

The following examples demonstrate how to use this resource module.

## Create a management OS adapter on the Hyper-V host ##
    Configuration HostOSAdapter
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapter
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMNetworkAdapter HostOSAdapter {
    	    Id = 'Management-NIC'
            Name = 'Management-NIC'
    	    SwitchName = 'SETSwitch'
            VMName = 'ManagementOS'
    	    Ensure = 'Present'
        }
    }

## Create multiple management OS adapters on the Hyper-V host ##
    Configuration HostOSAdapter
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapter
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMNetworkAdapter ManagementAdapter {
    	    Id = 'Management-NIC'
            Name = 'Management-NIC'
    	    SwitchName = 'SETSwitch'
            VMName = 'ManagementOS'
    	    Ensure = 'Present'
        }
    
        cVMNetworkAdapter ClusterAdapter {
    	    Id = 'Cluster-NIC'
            Name = 'Cluster-NIC'
    	    SwitchName = 'SETSwitch'
            VMName = 'ManagementOS'
    	    Ensure = 'Present'
        }
    }

## Create multiple management OS adapters on the Hyper-V host ##
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
    
       #The following resource configuration shows that the different VMs can have network adapters with the same name. This is possible because Id is the key property and not Name.
       cVMNetworkAdapter MyVM03NIC {
           Id = 'MyVM03-NIC'
           Name = 'NetAdapter'
    	   SwitchName = 'SETSwitch'
           VMName = 'MyVM03'
    	   Ensure = 'Present'
       }
    }
    
##Create multiple management OS adapters with static MAC address on the Hyper-V host ##
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

If you want to remove a network adapter either from the management OS or virtual machine, you need to set the *Ensure* property to *Absent*. 