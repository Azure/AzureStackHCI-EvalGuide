# DSCResources #
### Custom DSC resource module for Microsoft Hyper-V Networking by [PowerShell Magazine](http://www.powershellmagazine.com "PowerShell Magazine"). ###
----------

### This release (3.0.0.0) removed the cSwitchEmbededTeaming and cNATSwitch from this resource module. The functionality for creating SET team is now a part of cVMSwitch and cNatSwitch will go to xNetworking soon! ###

Microsoft Hyper-V DSC resource module contains a set of resources for managing Hyper-V management OS and guest networking.

- [cVMSwitch](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMSwitch) is used to create virtual machine switches.
- [cVMNetworkAdapter](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMNetworkAdapter) is used to create VM network adapters to attach to either management OS or the virtual machines.
- [cVMNetworkAdapterSettings](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMNetworkAdapterSettings) is used to configure VM network adapter settings such as bandwidth weights, port mirroring, DHCP guard, MAC address spoofing, etc.
- [cVMNetworkAdapterVlan](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMNetworkAdapterVlan) is used to configure VLANs on virtual network adapters either in the management OS or virtual machines.
- [cVMIPAddress](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cVMIPAddress) is used to inject IP Address into a virtual machine running on Hyper-V host.
- [cWaitForVMGuestIntegration](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V/DSCResources/cWaitForVMGuestIntegration) is used to ensure that the VM integration components are running. This will be useful when you want to wait until a VM completes reboot and then perform an action.

Note that before using any of the custom resources, you must either import the individual resources or the entire module containing these resources. You can do this using the Import-DscResource cmdlet.

Note: For documentation of each of these resources, visit the resource page.