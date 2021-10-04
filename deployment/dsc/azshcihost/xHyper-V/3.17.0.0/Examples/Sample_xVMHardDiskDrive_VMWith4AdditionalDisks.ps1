configuration Sample_xVMHardDiskDrive
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
        $VhdPath
    )

    Import-DscResource -ModuleName 'xHyper-V'
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node $NodeName
    {
        $diskNameOS = "$VMName-OS.vhdx"

        # Install HyperV feature, if not installed - Server SKU only
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

        # Create the VHD for the OS
        xVHD DiskOS
        {

            Name             = $diskNameOS
            Path             = $VhdPath
            Generation       = 'vhdx'
            MaximumSizeBytes = 20GB
            Ensure           = 'Present'
            DependsOn        = '[WindowsFeature]HyperV'
        }

        # Create the VM
        xVMHyperV NewVM
        {
            Name       = $VMName
            VhdPath    = Join-Path $VhdPath -ChildPath $diskNameOS
            Generation = 1
            Ensure     = 'Present'
            DependsOn  = '[xVHD]DiskOS'
        }

        # Ensures a SCSI controller exists on the VM
        xVMScsiController Controller
        {
            Ensure           = 'Present'
            VMName           = $VMName
            ControllerNumber = 0
            DependsOn        = '[xVMHyperV]NewVM'
        }

        foreach ($i in 0 .. 3)
        {
            $diskName = "$VMName-Disk-$i.vhdx"

            # Create the VHD
            xVHD "Disk-$i"
            {

                Name             = $diskName
                Path             = $VhdPath
                Generation       = 'vhdx'
                MaximumSizeBytes = 20GB
                Ensure           = 'Present'
                DependsOn        = '[WindowsFeature]HyperV'
            }

            # Attach the VHD
            xVMHardDiskDrive "ExtraDisk-$i"
            {
                VMName             = $VMName
                Path               = Join-Path $VhdPath -ChildPath $diskName
                ControllerType     = 'SCSI'
                ControllerLocation = $i
                Ensure             = 'Present'
                DependsOn          = '[xVMScsiController]Controller', "[xVHD]Disk-$i"
            }
        }
    }
}
