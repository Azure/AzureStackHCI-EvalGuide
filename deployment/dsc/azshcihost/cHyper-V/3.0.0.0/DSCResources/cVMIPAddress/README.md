#cVMIPAddress#
This DSC resource helps in injecting IP addresses into a running VM on the Hyper-V host. This is especially useful in a bootstrap scenario where there is no DHCP server or unattended XML method to configure an IP Address inside the guest OS. I use this quite a lot for building VMs from template VHDx files.

![](http://i.imgur.com/S3UVP7F.png)

The *Id* property is used to uniquely differentiate a VM network adapter that needs configuration. This is not a adapter property but a property that identifies the resource instance. This is a mandatory property.

The *NetAdapterName* property identifies the VM network adapter. This is a mandatory property.

The *VMName* property identifies the VM to which the network adapter is connected to. This is a mandatory property.

The *IPAddress* property is the IP address that will be assigned to the network adapter. This is a mandatory property. If you want to remove a configured IP address or reset the IP address to DHCP, specify 'DHCP' as the value of this parameter.

The *DefaultGateway* property is the default gateway address that will be assigned to the network adapter.

The *Subnet* property is the subnet mask that will be assigned to the network adapter.

The *DnsServer* property is the DNS Server address that will be assigned to the network adapter.

Here are some examples that demonstrates how to use this resource.

##Assigning an IP address to a VM adapter##
    Configuration VMIPAddress
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMIPAddress
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMIPAddress VMAdapter1IPAddress {
    	    Id = 'VMMgmt-NIC'
            NetAdapterName = 'VMMgmt-NIC'
            VMName = 'SQLVM01'
            IPAddress = '172.16.101.101'
            DefaultGateway = '172.16.101.1'
            Subnet = '255.255.255.0'
            DnsServer = '172.16.101.2'
        }
    }

##Removing an IP address assigned to a VM adapter##
    Configuration VMIPAddress
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMIPAddress
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMIPAddress VMAdapter1IPAddress {
    	    Id = 'VMMgmt-NIC'
            NetAdapterName = 'VMMgmt-NIC'
            VMName = 'SQLVM01'
            IPAddress = 'DHCP'
        }
    }