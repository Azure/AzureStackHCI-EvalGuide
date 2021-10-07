configuration Sample_xVMHardDiskDrive
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        [Parameter(Mandatory = $true)]
        [System.String]
        $VMName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VhdPath
    )

    Import-DscResource -ModuleName 'xHyper-V'
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node $NodeName
    {
        # Install HyperV feature, if not installed - Server SKU only
        $diskNameOS = "$VMName-DiskOS.vhdx"
        $diskNameExtra1 = "$VMName-Disk1.vhdx"

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

        xVHD DiskOS
        {
            Name             = $diskNameOS
            Path             = $VhdPath
            Generation       = 'vhdx'
            MaximumSizeBytes = 20GB
            Ensure           = 'Present'
            DependsOn        = '[WindowsFeature]HyperV'
        }

        xVHD Disk1
        {
            Name             = $diskNameExtra1
            Path             = $VhdPath
            Generation       = 'vhdx'
            MaximumSizeBytes = 20GB
            Ensure           = 'Present'
            DependsOn        = '[WindowsFeature]HyperV'
        }

        xVMHyperV NewVM
        {
            Ensure     = 'Present'
            Name       = $VMName
            VhdPath    = Join-Path $VhdPath -ChildPath $diskNameOS
            Generation = 1
            DependsOn  = '[xVHD]DiskOS'
        }

        xVMHardDiskDrive ExtraDisk
        {
            VMName             = $VMName
            Path               = Join-Path $VhdPath -ChildPath $diskNameExtra1
            ControllerType     = 'IDE'
            ControllerNumber   = 0
            ControllerLocation = 1
            Ensure             = 'Present'
            DependsOn          = '[xVHD]Disk1'
        }
    }
}
