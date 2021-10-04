ConvertFrom-StringData @'    
    HyperVModuleNotFound=Hyper-V PowerShell Module not found.
    VMNameAndManagementTogether=VMName cannot be provided when ManagementOS is set to True.
    MustProvideVMName=Must provide VMName parameter when ManagementOS is set to False.
    GetVMNetAdapter=Getting VM Network Adapter information.
    FoundVMNetAdapter=Found VM Network Adapter.
    NoVMNetAdapterFound=No VM Network Adapter found.
    VMNetAdapterDoesNotExist=VM Network Adapter does not exist.
    PerformVMVlanSet=Perfoming VM Network Adapter VLAN setting configuration.
    IgnoreVlan=Ignoring VLAN configuration when the opeartion mode chosen is Untagged.
    VlanIdRequiredInAccess=VlanId must be specified when chosen operation mode is Access.
    MustProvideNativeVlanId=NativeVlanId must be specified when chosen operation mode is Trunk.
    PrimaryVlanIdRequired=PrimaryVlanId is required when the chosen operation mode is Community or Isolated or Promiscuous.
    AccessVlanMustChange=VlanId in Access mode is different. It will be changed.
    AdaptersExistsWithVlan=VM Network adapter exists with required VLAN configuration.
    NativeVlanMustChange=NativeVlanId in Trunk mode is different and it wil be changed.
    AllowedVlanListMustChange=AllowedVlanIdList is different in trunk mode. It will be changed.
    PrimaryVlanMustChange=PrimaryVlanId is different and must be changed.
    SecondaryVlanMustChange=SecondaryVlanId is different and must be changed.
    SecondaryVlanListMustChange=SecondaryVlanIdList is different and must be changed.
    AdapterExistsWithDifferentVlanMode=VM Network adapter exists with different Vlan configuration. It will be fixed.
'@
