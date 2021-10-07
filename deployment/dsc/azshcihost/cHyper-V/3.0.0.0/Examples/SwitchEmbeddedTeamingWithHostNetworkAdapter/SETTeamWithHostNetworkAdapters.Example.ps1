Configuration SETTeam
{
    param (
        [String] $SwitchName,
        [String[]] $NetAdapterName,
        [Int] $ManagementVlan,
        [Int] $ManagementBandwidthWeight,
        [String] $ClusterAdapterName,
        [Int] $ClusterVlan,
        [Int] $ClusterBandwidthWeight,
        [String] $LiveMigrationAdapterName,
        [Int] $LiveMigrationVlan,
        [Int] $LiveMigrationBandwidthWeight
    )
    Import-DscResource -ModuleName cHyper-V

    cVMSwitch $SwitchName
    {
        Name = $SwitchName
        NetAdapterName = $NetAdapterName
        Type = 'External'
        MinimumBandwidthMode = 'Weight'
        TeamingMode = 'SwitchIndependent'
        LoadBalancingAlgorithm = 'Dynamic'
        Ensure = 'Present'
    }

    cVMNetworkAdapterVlan $SwitchName
    {
        Id = 'Mgmt-NIC'
        Name = $SwitchName
        AdapterMode = 'Access'
        VlanId = $ManagementVlan
        VMName = 'ManagementOS'
        DependsOn = "[cVMSwitch]$SwitchName"
    }

    cVMNetworkAdapterSettings $SwitchName
    {
        Id = 'Mgmt-NIC'
        Name = $SwitchName
        VMName = 'ManagementOS'
        SwitchName = $SwitchName
        MinimumBandwidthWeight = $ManagementBandwidthWeight
        DependsOn = "[cVMSwitch]$SwitchName"
    }

    cVMNetworkAdapter $ClusterAdapterName
    {
        Id = 'Cluster-NIC'
        Name = $ClusterAdapterName
        VMName = 'ManagementOS'
        SwitchName = $SwitchName
        DependsOn = "[cVMSwitch]$SwitchName"
    }

    cVMNetworkAdapterVlan $ClusterAdapterName
    {
        Id = 'Cluster-NIC'
        Name = $ClusterAdapterName
        AdapterMode = 'Access'
        VlanId = $ClusterVlan
        VMName = 'ManagementOS'
        DependsOn = "[cVMNetworkAdapter]$ClusterAdapterName"
    }

    cVMNetworkAdapterSettings $ClusterAdapterName
    {
        Id = 'Cluster-NIC'
        Name = $ClusterAdapterName
        VMName = 'ManagementOS'
        SwitchName = $SwitchName
        MinimumBandwidthWeight = $ClusterBandwidthWeight
        DependsOn = "[cVMNetworkAdapter]$ClusterAdapterName"
    }

    cVMNetworkAdapter $LiveMigrationAdapterName
    {
        Id = 'LM-NIC'
        Name = $LiveMigrationAdapterName
        VMName = 'ManagementOS'
        SwitchName = $SwitchName
        DependsOn = "[cVMSwitch]$SwitchName"
    }

    cVMNetworkAdapterVlan $LiveMigrationAdapterName
    {
        Id = 'LM-NIC'
        Name = $LiveMigrationAdapterName
        AdapterMode = 'Access'
        VlanId = $LiveMigrationVlan
        VMName = 'ManagementOS'
        DependsOn = "[cVMNetworkAdapter]$LiveMigrationAdapterName"
    }

    cVMNetworkAdapterSettings $LiveMigrationAdapterName
    {
        Id = 'LM-NIC'
        Name = $LiveMigrationAdapterName
        VMName = 'ManagementOS'
        SwitchName = $SwitchName
        MinimumBandwidthWeight = $LiveMigrationBandwidthWeight
        DependsOn = "[cVMNetworkAdapter]$LiveMigrationAdapterName"
    }
}
