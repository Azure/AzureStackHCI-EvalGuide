#Using cVMNetworkAdapterSettings resource#
Once the VM network adapters are created, we can assign the bandwidth reservation or priority settings as needed. If we set the *MinimumBandwidthMode* to *Weight* during VM switch creation, we need to specify the percentage of bandwidth reservation for each adapter.  We can this DSC resource for the purpose of updating the VM network adapter settings. This DSC resource can used for many other settings such as *DhcpGuard*, *RouterGuard*, *DeviceNaming*, and so on.

![](http://i.imgur.com/tZ1d4Fv.png)

The *Id* property is mandatory as a unique key for the resource configuration. This identifies the right resource instance of the network adapter in the system. This was chosen as an input property because the VM network adapter name can be the same for multiple adapters connected to the same VM or management OS.

The *Name* property identifies the name of the virtual network adapter. This is a required property.

The *SwitchName* property is used to specify where (the VM switch) the network adapter is connected. This is a required property too.

The *VMName* property is used to if a network adapter is connected to a VM or Management OS. If you need to add a network adapter to the management OS, specify *VMName* as 'ManagementOS'. If the value of *VMName* property is not 'ManagementOS', it will be considered a VM configuration and the network adapter attached to the VM will be configured for specified settings. 

The *MaximumBandwidth* property is used to specify the maximum bandwidth, in bits per second, for the VM network adapter. 

The *MinimumBandwidthAbsolute* specifies the minimum bandwidth, in bits per second, for the virtual network adapter. By default, these properties are set to zero which means those parameters within the network adapter are disabled. 

The *MinimumBandwidthWeight* specifies the minimum bandwidth, in terms of relative weight, for the virtual network adapter. The weight describes how much bandwidth to provide to the virtual network adapter relative to other virtual network adapters connected to the same virtual switch.

If you want allow teaming of network adapters in the guest OS, you can set the *AllowTeaming* property to On. By default, this is set to *Off* and therefore disallows network teaming inside guest OS. 

Similar to this, there are other settings of a VM network adapter that you can configure. These properties include *DhcpGuard*, *MacAddressSpoofing*, *PortMirroring*, *RouterGuard*, *IeeePriorityTag*, *DeviceNaming*, and *VmqWeight*. These properties are self explanatory and are left to defaults for a VM network adapter.

The following examples demonstrate how to use this DSC resource.

##Setting MinimumBandwidthWeight for a VM adapter in management OS## 
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

##Setting DHCP guard for a VM adapter connected to a VM##
    Configuration VMAdapterSettings
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterSettings
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMNetworkAdapterSettings VMAdapterSettings {
    	    Id = 'Management-NIC'
            Name = 'Management-NIC'
            VMName = 'DHCPVM01'
            SwitchName = 'SETSwitch'
            DhcpGuard = 'On'
        }
    }

##Setting DHCPGuard and DeviceNaming on multiple VM network adapters connected to the same VM##
    Configuration VMAdapterSettings
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMNetworkAdapterSettings
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMNetworkAdapterSettings VMAdapterSettings01 {
    	    Id = 'Management-NIC'
            Name = 'Management-NIC'
            VMName = 'DHCPVM01'
            SwitchName = 'SETSwitch'
            DhcpGuard = 'On'
            DeviceNaming = 'On'
        }
    
        cVMNetworkAdapterSettings VMAdapterSettings02 {
    	    Id = 'App-NIC'
            Name = 'App-NIC'
            VMName = 'DHCPVM01'
            SwitchName = 'SETSwitch'
            DeviceNaming = 'On'
        }
    }