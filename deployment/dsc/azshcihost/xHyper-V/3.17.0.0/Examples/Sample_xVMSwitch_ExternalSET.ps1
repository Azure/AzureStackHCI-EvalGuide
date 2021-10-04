Configuration Sample_xVMSwitch_External
{
    param
    (
        [Parameter()]
        [string[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [string]
        $SwitchName,

        [Parameter(Mandatory = $true)]
        [string[]]
        $NetAdapterNames
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

        WindowsFeature HyperVTools
        {
            Ensure    = 'Present'
            Name      = 'RSAT-Hyper-V-Tools'
            DependsOn = '[WindowsFeature]HyperV'
        }

        # Ensures a VM with default settings
        xVMSwitch ExternalSwitch
        {
            Ensure                = 'Present'
            Name                  = $SwitchName
            Type                  = 'External'
            NetAdapterName        = $NetAdapterNames
            EnableEmbeddedTeaming = $true
            DependsOn             = '[WindowsFeature]HyperVTools'
        }
    }
}
