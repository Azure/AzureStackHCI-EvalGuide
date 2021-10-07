configuration Sample_xVMHyperV_SimpleWithNestedVirtualization
{
    param
    (
        [Parameter()]
        [string[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [string]
        $VMName,

        [Parameter(Mandatory = $true)]
        [string]
        $VhdPath,

        [Parameter(Mandatory = $true)]
        [Uint64]
        $Memory
    )

    Import-DscResource -module xHyper-V

    Node $NodeName
    {
        # Install HyperV feature, if not installed - Server SKU only
        WindowsFeature HyperV
        {
            Ensure = 'Present'
            Name   = 'Hyper-V'
        }

        # Ensures a VM with default settings
        xVMHyperV NewVM
        {
            Ensure        = 'Present'
            Name          = $VMName
            VhdPath       = $VhdPath
            Generation    = 2
            StartupMemory = $Memory
            MinimumMemory = $Memory
            MaximumMemory = $Memory
            DependsOn     = '[WindowsFeature]HyperV'
        }

        # Set the VM options
        xVMProcessor NestedVirtualization
        {
            VMName                         = $VMName
            ExposeVirtualizationExtensions = $true
            DependsOn                      = '[xVMHyperV]NewVM'
        }
    }
}
