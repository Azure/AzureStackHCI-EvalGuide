Configuration Sample_xVMHyperV_MultipleNICs
{
    param
    (
        [string[]]$NodeName = 'localhost',

        [Parameter(Mandatory)]
        [string]$VMName,

        [Parameter(Mandatory)]
        [string]$VhdPath,

        [Parameter(Mandatory)]
        [string[]]$SwitchName,

        [Parameter()]
        [string[]]$MACAddress
    )

    Import-DscResource -module xHyper-V

    Node $NodeName
    {
        # Install HyperV features, if not installed - Server SKU only
        WindowsFeature HyperV
        {
            Ensure = 'Present'
            Name   = 'Hyper-V'
        }

        WindowsFeature HyperVPowerShell
        {
            Ensure = 'Present'
            Name   = 'Hyper-V-PowerShell'
        }

        # Dynamically build the 'DependsOn' array for the 'xVMHyperV' feature
        # based on the number of virtual switches specified
        $xVMHyperVDependsOn = @('[WindowsFeature]HyperV','[WindowsFeature]HyperVPowerShell')

        # Create each virtual switch
        foreach ($vmSwitch in $SwitchName)
        {
            # Remove spaces and hyphens from the identifier
            $vmSwitchName = $vmSwitch -replace ' ','' -replace '-',''
            # Add the virtual switch dependency
            $xVMHyperVDependsOn += "[xVMHyperV]$vmSwitchName"

            xVMSwitch $vmSwitchName
            {
                Ensure         = 'Present'
                Name           = $vmSwitch
                Type           = 'Internal'
                DependsOn      = '[WindowsFeature]HyperV','[WindowsFeature]HyperVPowerShell'
            }
        }

        # Ensures a VM with all the properties
        xVMHyperV $VMName
        {
            Ensure     = 'Present'
            Name       = $VMName
            VhdPath    = $VhdPath
            SwitchName = $SwitchName
            MACAddress = $MACAddress
            # Use the dynamically created dependency list/array
            DependsOn  = $xVMHyperVDependsOn
        }
    }
}

Sample_xVMHyperV_MultipleNICs -VMName 'MultiNICVM' -VhdPath 'C:\VMs\MultiNICVM.vhdx' -SwitchName 'Switch 1','Switch-2'
