#Using cVMNetworkAdapterVlan resource#
This DSC resource can be used to assign VLAN information to a NIC that is created attached to either the management OS or a virtual machine. There are several possibilities here.

![](http://i.imgur.com/GMsXDyK.png)

This resource has three mandatory properties. 

The *Id* property is  a unique identifier to differentiate between multiple VMs containing the same network adapter name or same VM having multiple adapters named same.

The *Name* property identifies the name of the network adapter for which the VLAN information needs to be configured.

The *VMName* property identifies where the network adapter is connected. You can specify host OS by specifying a value *ManagementOS*. If the value of *VMName* property is not *ManagementOS*, it will be considered a Virtual Machine configuration and the network adapter attached to the VM will be configured for VLAN settings. 

The *AdapterMode* property specifies the operation mode of the adapter and is by default set to *Untagged* which means there is no VLAN configuration. The possible and valid values for this property are *Untagged*, *Access*, *Trunk*, *Community*, *Isolated*, and *Promiscuous*. Each of these modes have a corresponding VLAN property that is mandatory. 

If you set the *AdapterMode* property to *Access*, then it is mandatory to provide *VlanId* property. 

If you set the *AdapterMode* to *Trunk*, the *NativeVlanId* property must be specified.

The following examples demonstrate how to use this DSC resource.

##Simple Management OS NIC VLAN configuration for Access VLAN##

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
    }

##Multiple Management OS NIC VLAN configuration for Access and Untagged VLAN##

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

In the above example, setting the *AdapterMode* to *Untagged* removes any VLAN configuration on the NIC, if present. By default, all VM network adapters will be in Untagged mode.

##Multiple Management OS NIC VLAN configuration for Access and Untagged VLAN##

    Configuration HostOSAdapterVlan
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterVlan
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMNetworkAdapterVlan VMMgmtAdapterVlan {
    	    Id = 'VMManagement-NIC'
            Name = 'VMManagement-NIC'
            VMName = 'SQLVM01'
            AdapterMode = 'Access'
            VlanId = 10
        }
    
        cVMNetworkAdapterVlan VMiSCSIAdapterVlan {
    	    Id = 'VMiSCSI-NIC'
            Name = 'VMiSCSI-NIC'
            VMName = 'SQLVM01'
            AdapterMode = 'Untagged'
        }
    }

