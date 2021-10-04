# xHyper-V

The **xHyper-V** module contains DSC resources for deployment and configuration of
 Hyper-V hosts, virtual machines and related resources.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
 or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
 additional questions or comments.

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/tsdbv0hgrxvmbo5y/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xhyper-v/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xHyper-V/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xHyper-V/branch/master)

This is the branch containing the latest release - no contributions should be
made directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/tsdbv0hgrxvmbo5y/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xhyper-v/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xHyper-V/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xHyper-V/branch/dev)

This is the development branch to which contributions should be proposed by
contributors as pull requests. This development branch will periodically be
merged to the master branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

* [**xVHD**](#xvhd) manages VHDs in a Hyper-V host.
* [**xVhdFile**](#xvhdfile) manages files or directories in a VHD.
 You can use it to copy files/folders to the VHD, remove files/folders from a VHD,
 and change attributes of a file in a VHD (e.g. change a file attribute to
 'ReadOnly' or 'Hidden').
 This resource is particularly useful when bootstrapping DSC Configurations
 into a VM.
* [**xVMDvdDrive**](#xvmdvddrive) manages DVD drives attached to a Hyper-V
 virtual machine.
* [**xVMHardDiskDrive**](#xvmharddiskdrive) manages VHD(X)s attached to a Hyper-V virtual machine.
* [**xVMHost**](#xvmhost) manages Hyper-V host settings.
* [**xVMHyperV**](#xvmhyperv) manages VMs in a Hyper-V host.
* [**xVMNetworkAdapter**](#xvmnetworkadapter) manages VMNetadapters attached to
 a Hyper-V virtual machine or the management OS.
* [**xVMProcessor**](#xvmprocessor) manages Hyper-V virtual machine processor options.
* [**xVMScsiController**](#xvmscsicontroller) manages the SCSI controllers attached to a Hyper-V virtual machine.
* [**xVMSwitch**](#xvmswitch) manages virtual switches in a Hyper-V host.

### xVHD

Manages VHDs in a Hyper-V host.

#### Requirements for xVHD

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVHD

* **`[String]` Name** _(Key)_: The desired VHD file name.
* **`[String]` Path** _(Key)_: The desired Path where the VHD will be created.
* **`[String]` ParentPath** _(Write)_: Parent VHD file path, for differencing disk.
* **`[Uint64]` MaximumSizeBytes** _(Write)_: Maximum size of VHD to be created.
* **`[String]` Generation** _(Write)_: Virtual disk format.
 The default value is Vhd. { *Vhd* | Vhdx }.
* **`[String]` Type** _(Write)_: Virtual disk type.
 The default value is Dynamic. { *Dynamic* | Fixed | Differencing }.
* **`[String]` Ensure** _(Write)_: Ensures that the VHD is Present or Absent.
 The default value is Present. { *Present* | Absent }.

#### Read-Only Properties from Get-TargetResource for xVHD

* **`[String]` ID** _(Read)_: Virtual Disk Identifier.
* **`[String]` Type** _(Read)_: Type of Vhd - Dynamic, Fixed, Differencing.
* **`[Uint64]` FileSizeBytes** _(Read)_: Current size of the VHD.
* **`[Boolean]` IsAttached** _(Read)_: Is the VHD attached to a VM or not.

#### Examples xVHD

* [Create a new VHD](/Examples/Sample_xVHD_NewVHD.ps1)
* [Create a new Fixed VHD](/Examples/Sample_xVHD_FixedVHD.ps1)
* [Create a differencing VHD](/Examples/Sample_xVHD_DiffVHD.ps1)

### xVhdFile

Manages files or directories in a VHD.
 You can use it to copy files/folders to the VHD, remove files/folders from a VHD,
 and change attributes of a file in a VHD (e.g. change a file attribute to
 'ReadOnly' or 'Hidden').
 This resource is particularly useful when bootstrapping DSC Configurations
 into a VM.

#### Requirements for xVhdFile

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVhdFile

* **`[String]` VhdPath** _(Key)_: Path to the VHD.
* **`[MSFT_xFileDirectory[]]` FileDirectory** _(Required)_: The FileDirectory objects
 to copy to the VHD (as used in the "File" resource).
 Please see the Examples section for more details.
* **`[String]` CheckSum** _(Write)_: Indicates the checksum type to use when determining
 whether two files are the same. The default value is ModifiedDate.
 { *ModifiedDate* | SHA-1 | SHA-256 | SHA-512 }.

##### MSFT_xFileDirectory Class

* **`[String]` DestinationPath** _(Required)_: Indicates the location where you want
 to ensure the state for a file or directory.
* **`[String]` SourcePath** _(Write)_: Indicates the path from which to copy the
 file or folder resource.
* **`[String]` Ensure** _(Write)_: Indicates if the file or directory exists.
 Set this property to "Absent" to ensure that the file or directory does not exist.
 Set it to "Present" to ensure that the file or directory does exist.
 { Present | Absent }.
* **`[String]` Type** _(Write)_: Indicates if the resource being configured is a
 directory or a file. Set this property to "Directory" to indicate that the resource
 is a directory. Set it to "File" to indicate that the resource is a file.
 { File | Directory }.
* **`[Boolean]` Recurse** _(Write)_: Indicates if subdirectories are included.
 Set this property to $true to indicate that you want subdirectories to be included.
* **`[Boolean]` Force** _(Write)_: Certain file operations (such as overwriting a
 file or deleting a directory that is not empty) will result in an error. Using the
 Force property overrides such errors.
* **`[String]` Content** _(Write)_: Specifies the contents of a file, such as a
 particular string.
* **`[String[]]` Attributes** _(Write)_: Specifies the desired state of the attributes
 for the targeted file or directory. { ReadOnly | Hidden | System | Archive }.

#### Read-Only Properties from Get-TargetResource for xVhdFile

None

#### Examples xVhdFile

* [Multiple examples](/Examples/Sample_xVhdFileExamples.ps1)

### xVMDvdDrive

Manages DVD drives attached to a Hyper-V virtual machine.

#### Requirements for xVMDvdDrive

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVMDvdDrive

* **`[String]` VMName** _(Key)_: Specifies the name of the virtual machine
 to which the DVD drive is to be added.
* **`[Uint32]` ControllerNumber** _(Key)_: Specifies the number of the controller
 to which the DVD drive is to be added.
* **`[Uint32]` ControllerLocation** _(Key)_: Specifies the number of the location
 on the controller at which the DVD drive is to be added.
* **`[String]` Path** _(Write)_: Specifies the full path to the virtual hard disk
 file or physical hard disk volume for the added DVD drive.
* **`[String]` Ensure** _(Write)_: Specifies if the DVD Drive should exist or not.
  The default value is Present. { *Present* | Absent }.

#### Read-Only Properties from Get-TargetResource for xVMDvdDrive

None

#### Examples xVMDvdDrive

* [Create a VM, given a VHDX and add a DVD Drives](/Examples/Sample_xVMHyperV_SimpleWithDVDDrive.ps1)

### xVMHardDiskDrive

Manages VHD(X)s attached to a Hyper-V virtual machine.
When ControllerNumber or ControllerLocation is not provided, the same logic as
 Set-VMHardDiskDrive cmdlet is used.

#### Requirements for xVMHardDiskDrive

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVMHardDiskDrive

* **`[String]` VMName** _(Key)_: Specifies the name of the virtual machine
 whose hard disk drive is to be manipulated.
* **`[String]` VhdPath** _(Key)_: Specifies the full path of the VHD file to be
 manipulated.
* **`[String]` ControllerType** _(Write)_: Specifies the type of controller to which
 the hard disk drive is to be set. The default value is SCSI. { *SCSI* | IDE }.
* **`[Uint32]` ControllerNumber** _(Write)_: Specifies the number of the controller
 to which the hard disk drive is to be set.
 For IDE: { 0, 1 }, for SCSI: { 0 | 1 | 2 | 3 }.
 Defaults to 0.
* **`[Uint32]` ControllerLocation** _(Write)_: Specifies the number of the location
 on the controller at which the hard disk drive is to be set.
 For IDE: { 0 | 1 }, for SCSI: { 0 .. 63 }.
 Defaults to 0.
* **`[String]` Ensure** _(Write)_: Specifies if the hard disk drive should exist or
 not. The default value is Present. { *Present* | Absent }.

#### Read-Only Properties from Get-TargetResource for xVMHardDiskDrive

None

#### Examples xVMHardDiskDrive

* [Create a VM, with an OS drive and an additional data drive](/Examples/Sample_xVMHardDiskDrive_VMWithExtraDisk.ps1)
* [Create a VM, with an OS drive and 4 data drives](/Examples/Sample_xVMHardDiskDrive_VMWith4AdditionalDisks.ps1)

### xVMHost

Manages Hyper-V host settings.

#### Requirements for xVMHost

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVMHost

* **`[String]` IsSingleInstance** _(Key)_: Specifies the resource is a single instance,
 the value must be 'Yes'. { *Yes* }.
* **`[Boolean]` EnableEnhancedSessionMode** _(Write)_: Indicates whether users
 can use enhanced mode when they connect to virtual machines on this server
 by using Virtual Machine Connection.
* **`[String]` FibreChannelWwnn** _(Write)_: Specifies the default value of
 the World Wide Node Name on the Hyper-V host.
* **`[String]` FibreChannelWwpnMaximum** _(Write)_: Specifies the maximum value
 that can be used to generate World Wide Port Names on the Hyper-V host.
 Use with the FibreChannelWwpnMinimum parameter to establish a range of WWPNs
 that the specified Hyper-V host can assign to virtual Fibre Channel adapters.
* **`[String]` FibreChannelWwpnMinimum** _(Write)_: Specifies the minimum value
 that can be used to generate the World Wide Port Names on the Hyper-V host.
 Use with the FibreChannelWwpnMaximum parameter to establish a range of WWPNs
 that the specified Hyper-V host can assign to virtual Fibre Channel adapters.
* **`[String]` MacAddressMaximum** _(Write)_: Specifies the maximum MAC address
 using a valid hexadecimal value. Use with the MacAddressMinimum parameter
 to establish a range of MAC addresses that the specified Hyper-V host can assign
 to virtual machines configured to receive dynamic MAC addresses.
* **`[String]` MacAddressMinimum** _(Write)_: Specifies the minimum MAC address
 using a valid hexadecimal value. Use with the MacAddressMaximum parameter to
 establish a range of MAC addresses that the specified Hyper-V host can assign
 to virtual machines configured to receive dynamic MAC addresses.
* **`[Uint32]` MaximumStorageMigrations** _(Write)_: Specifies the maximum number
 of storage migrations that can be performed at the same time on the Hyper-V host.
* **`[Uint32]` MaximumVirtualMachineMigrations** _(Write)_: Specifies the maximum
 number of live migrations that can be performed at the same time
 on the Hyper-V host.
* **`[Boolean]` NumaSpanningEnabled** _(Write)_: Specifies whether virtual machines
 on the Hyper-V host can use resources from more than one NUMA node.
* **`[Uint32]` ResourceMeteringSaveIntervalMinute** _(Write)_: Specifies how often
 the Hyper-V host saves the data that tracks resource usage. The range is a minimum
 of 60 minutes to a maximum 1440 minutes (24 hours).
* **`[Boolean]` UseAnyNetworkForMigration** _(Write)_: Specifies how networks are
 selected for incoming live migration traffic. If set to $True, any available network
 on the host can be used for this traffic. If set to $False, incoming live migration
 traffic is transmitted only on the networks specified in the MigrationNetworks
 property of the host.
* **`[String]` VirtualHardDiskPath** _(Write)_: Specifies the default folder to
 store virtual hard disks on the Hyper-V host.
* **`[String]` VirtualMachineMigrationAuthenticationType** _(Write)_: Specifies the
 type of authentication to be used for live migrations. { Kerberos | CredSSP }.
* **`[String]` VirtualMachineMigrationPerformanceOption** _(Write)_: Specifies the
 performance option to use for live migration. { TCPIP | Compression | SMB }.
* **`[String]` VirtualMachinePath** _(Write)_: Specifies the default folder
 to store virtual machine configuration files on the Hyper-V host.
* **`[Boolean]` VirtualMachineMigrationEnabled** _(Write)_: Indicates whether Live
 Migration should be enabled or disabled on the Hyper-V host.

#### Read-Only Properties from Get-TargetResource for xVMHost

None

#### Examples xVMHost

* [Change VM Host paths](/Examples/Sample_xVMHost_Paths.ps1)

### xVMHyperV

Manages VMs in a Hyper-V host.

The following properties **cannot** be changed after VM creation:

* VhdPath
* Path
* Generation

#### Requirements for xVMHyperV

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVMHyperV

* **`[String]` Name** _(Key)_: The desired VM name.
* **`[String]` VhdPath** _(Required)_: The desired VHD associated with the VM.
* **`[String[]]` SwitchName** _(Write)_: Virtual switch(es) associated with the VM.
  Multiple NICs can now be assigned.
* **`[String]` State** _(Write)_: State of the VM: { Running | Paused | Off }.
* **`[String]` Path** _(Write)_: Folder where the VM data will be stored.
* **`[Uint32]` Generation** _(Write)_: Virtual machine generation.
  Generation 2 virtual machines __only__ support VHDX files.
  The default value is 1. { *1* | 2 }.
* **`[Boolean]` SecureBoot** _(Write)_: Enables or disables secure boot
 __only on generation 2 virtual machines__.
 The default value is $true.
* **`[Uint64]` StartupMemory** _(Write)_: Startup RAM for the VM.
  If neither MinimumMemory nor MaximumMemory is specified, dynamic memory will be disabled.
* **`[Uint64]` MinimumMemory** _(Write)_: Minimum RAM for the VM.
  Setting this property enables dynamic memory. Exception:
  If MinimumMemory, MaximumMemory and StartupMemory is equal, dynamic memory will be disabled.
* **`[Uint64]` MaximumMemory** _(Write)_: Maximum RAM for the VM.
  Setting this property enables dynamic memory. Exception:
  If MinimumMemory, MaximumMemory and StartupMemory is equal, dynamic memory will be disabled.
* **`[String[]]` MACAddress** _(Write)_: MAC address(es) of the VM.
  Multiple MAC addresses can now be assigned.
* **`[Uint32]` ProcessorCount** _(Write)_: Processor count for the VM.
* **`[Boolean]` WaitForIP** _(Write)_: If specified, waits for the VM to get
 valid IP address.
* **`[Boolean]` RestartIfNeeded** _(Write)_: If specified, will shutdown and
 restart the VM as needed for property changes.
* **`[String]` Ensure** _(Write)_: Ensures that the VM is Present or Absent.
 The default value is Present. { *Present* | Absent }.
* **`[String]` Notes** _(Write)_: Notes about the VM.
* **`[Boolean]` EnableGuestService** _(Write)_: Enable Guest Service Interface
 for the VM. The default value is $false.

#### Read-Only Properties from Get-TargetResource for xVMHyperV

* **`[String]` ID** _(Read)_: VM unique ID.
* **`[String]` Status** _(Read)_: Status of the VM.
* **`[Uint32]` CPUUsage** _(Read)_: CPU Usage of the VM.
* **`[Uint64]` MemoryAssigned** _(Read)_: Memory assigned to the VM.
* **`[String]` Uptime** _(Read)_: Uptime of the VM.
* **`[DateTime]` CreationTime** _(Read)_: Creation time of the VM.
* **`[Boolean]` HasDynamicMemory** _(Read)_: Does VM has dynamic memory enabled.
* **`[String[]]` NetworkAdapters** _(Read)_: Network adapters' IP addresses of
 the VM".

#### Examples xVMHyperV

* [Create a VM (Simple)](/Examples/Sample_xVMHyperV_Simple.ps1)
* [Create a VM with dynamic memory](/Examples/Sample_xVMHyperV_DynamicMemory.ps1)
* [Create a VM (Complete)](/Examples/Sample_xVMHyperV_Complete.ps1)
* [Create a VM with multiple NICs attached to multiple switches](/Examples/Sample_xVMHyperV_MultipleNICs.ps1)

### xVMNetworkAdapter

Manages VMNetadapters attached to a Hyper-V virtual machine or the management OS.

#### Requirements for xVMNetworkAdapter

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVMNetworkAdapter

* **`[String]` Id** _(Key)_: Unique string for identifying the resource instance.
* **`[String]` Name** _(Required)_: Name of the network adapter as it appears either
  in the management OS or attached to a VM.
* **`[String]` SwitchName** _(Required)_: Virtual Switch name to connect to.
* **`[String]` VMName** _(Required)_: Name of the VM to attach to.
  If you want to attach new VM Network adapter to the management OS,
  set this property to 'Management OS'.
* **`[xNetworkSettings]` NetworkSetting** _(Write)_: Network Settings of the network adapter.
  If this parameter is not supplied, DHCP will be used.
* **`[String]` MacAddress** _(Write)_: Use this to specify a Static MAC Address.
  If this parameter is not specified, dynamic MAC Address will be set.
* **`[String]` VlanId** _(Write)_: Use this to specify a Vlan id on the
* Network Adapter.
* **`[String]` Ensure** _(Write)_: Ensures that the VM Network Adapter is
  Present or Absent. The default value is Present. { *Present* | Absent }.

##### xNetworkSettings Class

* **`[String]` IpAddress** _(Write)_: IpAddress to give the network adapter.
  Only used if not Dhcp. Required if not Dhcp.
* **`[String]` Subnet** _(Write)_: Subnet to give the network adapter.
  Only used if not Dhcp. Required if not Dhcp.
* **`[String]` DefaultGateway** _(Write)_: DefaultGateway to give the network adapter.
  Only used if not Dhcp.
* **`[String]` DnsServer** _(Write)_: DNSServer to give the network adapter.
  Only used if not Dhcp.

#### Read-Only Properties from Get-TargetResource for xVMNetworkAdapter

* **`[Boolean]` DynamicMacAddress** _(Read)_: Does the VMNetworkAdapter use a
 Dynamic MAC Address.

#### Examples xVMNetworkAdapter

* [Add a new VM Network adapter in the management OS](/Examples/Sample_xVMNetworkAdapter_ManagementOS.ps1)
* [Add multiple VM Network adapters to a VM](/Examples/Sample_xVMNetworkAdapter_MultipleVM.ps1)
* [Add a couple of VM Network adapters in the management OS](/Examples/Sample_xVMNetworkAdapter_MultipleManagementOS.ps1)
* [Add multiple VM Network adapters to a VM using status MAC addresses](/Examples/Sample_xVMNetworkAdapter_MultipleVMMACAddress.ps1)
* [Add VM Network adapters to a VM with a Vlan tag](/Examples/Sample_xVMNetworkAdapter_VMVlanTagging.ps1)
* [Add VM Network adapters to a VM with a static IpAddress](/Examples/Sample_xVMNetworkAdapter_VMStaticNetworkSettings.ps1)

### xVMProcessor

Manages Hyper-V virtual machine processor options.

#### Requirements for xVMProcessor

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVMProcessor

* **`[String]` VMName** _(Key)_: Specifies the name of the virtual machine
 on which the processor is to be configured.
* **`[Boolean]` EnableHostResourceProtection** _(Write)_: Specifies whether to
 enable host resource protection. NOTE: Only supported on Windows 10 and Server 2016.
* **`[Boolean]` ExposeVirtualizationExtensions** _(Write)_: Specifies whether
 nested virtualization is enabled. NOTE: Only supported on
 Windows 10 and Server 2016.
* **`[Uint64]` HwThreadCountPerCore** _(Write)_: Specifies the maximum thread core
 per processor core. NOTE: Only supported on Windows 10 and Server 2016.
* **`[Uint64]` Maximum** _(Write)_: Specifies the maximum percentage of resources
 available to the virtual machine processor to be configured.
 Allowed values range from 0 to 100.
* **`[Uint32]` MaximumCountPerNumaNode** _(Write)_: Specifies the maximum number
 of processors per NUMA node to be configured for the virtual machine.
* **`[Uint32]` MaximumCountPerNumaSocket** _(Write)_: Specifies the maximum number
 of sockets per NUMA node to be configured for the virtual machine.
* **`[Unit32]` RelativeWeight** _(Write)_: Specifies the priority for allocating
 the physical computer's processing power to this virtual machine relative to others.
 Allowed values range from 1 to 10000.
* **`[Uint64]` Reserve** _(Write)_: Specifies the percentage of processor resources
 to be reserved for this virtual machine. Allowed values range from 0 to 100.
* **`[String]` ResourcePoolName** _(Write)_: Specifies the name of the processor
 resource pool to be used.
* **`[Boolean]` CompatibilityForMigrationEnabled** _(Write)_: Specifies whether
 the virtual processors features are to be limited for compatibility when migrating
 the virtual machine to another host.
* **`[Boolean]` CompatibilityForOlderOperatingSystemsEnabled** _(Write)_: Specifies
 whether the virtual processor’s features are to be limited for compatibility
 with older operating systems.
* **`[Boolean]` RestartIfNeeded** _(Write)_: If specified, shutdowns and restarts
 the VM if needed for property changes.

#### Read-Only Properties from Get-TargetResource for xVMProcessor

None

#### Examples xVMProcessor

* [Create a secure boot gen 2 VM for a given VHD with nested virtualisation enabled](/Examples/Sample_xVMHyperV_SimpleWithNestedVirtualization.ps1)

### xVMScsiController

Manages the SCSI controllers attached to a Hyper-V virtual machine.
When removing a controller, all the disks still connected to the controller will be detached.

#### Requirements for xVMScsiController

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVMScsiController

* **`[String]` VMName** _(Key)_: Specifies the name of the virtual machine whose SCSI
 controller is to be manipulated.
* **`[Uint32]` ControllerNumber** _(Key)_: Specifies the number of the controller to
 be set: { 0 | 1 | 2 | 3 }.
* **`[String]` Ensure** _(Write)_: Specifies if the SCSI controller should exist or
 not. The default value is Present. { *Present* | Absent }.

#### Read-Only Properties from Get-TargetResource for xVMScsiController

None

#### Examples xVMScsiController

* [Add a secondary SCSI controller](/Examples/Sample_xVMScsiController_AddControllers.ps1)

### xVMSwitch

Manages virtual switches in a Hyper-V host.

#### Requirements for xVMSwitch

* The Hyper-V Role has to be installed on the machine.
* The Hyper-V PowerShell module has to be installed on the machine.

#### Parameters for xVMSwitch

* **`[String]` Name** _(Key)_: The desired VM Switch name.
* **`[String]` Type** _(Key)_: The desired type of switch.
 { External | Internal | Private }
* **`[String[]]` NetAdapterName** _(Write)_: Network adapter name(s)
 for external switch type.
* **`[Boolean]` AllowManagementOS** _(Write)_: Specify if the VM host
 has access to the physical NIC. The default value is $false.
* **`[Boolean]` EnableEmbeddedTeaming** _(Write)_: Should embedded NIC teaming
 be used (Windows Server 2016 only). The default value is $false.
* **`[String]` BandwidthReservationMode** _(Write)_: Specify the QoS mode used
 (options other than NA are only supported on Hyper-V 2012+).
 The default value is NA. { Default | Weight | Absolute | None | *NA* }.
* **`[String]` LoadBalancingAlgorithm** _(Write)_: Specify the Load Balancing algorithm which should be used for the embedded NIC teaming.
 { Dynamic | HyperVPort }.
* **`[Boolean]` Id** _(Write)_: Specify the desired Unique ID of the Hyper-V switch. If not specified the ID will be generated by the system every time the Hyper-V Switch is created. (Windows Server 2016 only)
* **`[String]` Ensure** _(Write)_: Ensures that the VM Switch is Present or Absent.
 The default value is Present. { *Present* | Absent }.

#### Read-Only Properties from Get-TargetResource for xVMSwitch

* **`[String]` NetAdapterInterfaceDescription** _(Read)_: Description of the
 network interface.

#### Examples xVMSwitch

* [Create an internal VM Switch](/Examples/Sample_xVMSwitch_Internal.ps1)
* [Create an external VM Switch](/Examples/Sample_xVMSwitch_External.ps1)
* [Create an external VM Switch with embedded teaming](/Examples/Sample_xVMSwitch_ExternalSET.ps1)
