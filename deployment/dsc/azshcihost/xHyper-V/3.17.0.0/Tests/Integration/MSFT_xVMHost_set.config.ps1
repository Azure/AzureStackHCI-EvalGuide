configuration MSFT_xVMHost_Set_Config 
{
    param
    (
        [Parameter(Mandatory  = $true)]
        [System.String]
        $VirtualHardDiskPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VirtualMachinePath,

        [Parameter()]
        [System.Boolean]
        $EnableEnhancedSessionMode
    )

    Import-DscResource -ModuleName xHyper-V

    node localhost {
        xVMHost Integration_Test {
            IsSingleInstance          = 'Yes'
            VirtualHardDiskPath       = $VirtualHardDiskPath
            VirtualMachinePath        = $VirtualMachinePath
            EnableEnhancedSessionMode = $EnableEnhancedSessionMode
        }
    }

}
