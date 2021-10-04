configuration MSFT_xVMDvdDrive_Remove_Config {

    Import-DscResource -ModuleName xHyper-V

    node localhost {
        xVMDvdDrive Integration_Test {
            VMName             = $Node.VMName
            ControllerNumber   = $Node.ControllerNumber
            ControllerLocation = $Node.ControllerLocation
            Path               = $Node.Path
            Ensure             = 'Absent'
        }
    }
}
