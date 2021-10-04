configuration Sample_xVMScsiController
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
        $diskNameOS = "$VMName-OS.vhdx"

        # Install HyperV feature, if not installed - Server SKU only
        WindowsFeature HyperV
        {
            Ensure = 'Present'
            Name   = 'Hyper-V'
        }

        # Create the VHD for the OS
        xVHD DiskOS
        {
            Ensure           = 'Present'
            Name             = $diskNameOS
            Path             = $VhdPath
            Generation       = 'vhdx'
            MaximumSizeBytes = 20GB
            DependsOn        = '[WindowsFeature]HyperV'
        }

        # Create the VM
        xVMHyperV NewVM
        {
            Ensure     = 'Present'
            Name       = $VMName
            VhdPath    = Join-Path -Path $VhdPath -ChildPath $diskNameOS
            Generation = 2
            DependsOn  = '[xVHD]DiskOS'
        }

        # Add and additional SCSI controller
        xVMScsiController Controller
        {
            Ensure           = 'Present'
            VMName           = $VMName
            ControllerNumber = 1
            DependsOn        = '[xVMHyperV]NewVM'
        }

    }
}

$mofPath = "C:\temp\Sample_xVMScsiController"

Sample_xVMScsiController -VMName "test1" -VhdPath "C:\temp\Tests" -OutputPath $mofPath
Start-DscConfiguration -Path $mofPath -Verbose -Wait -Force
