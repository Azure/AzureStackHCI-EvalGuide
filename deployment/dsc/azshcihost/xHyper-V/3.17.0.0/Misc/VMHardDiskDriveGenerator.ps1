New-xDscResource -Name MSFT_xVMHardDiskDrive -Path . -ClassVersion 1.0.0 -FriendlyName xVMHardDiskDrive -Property $(
    New-xDscResourceProperty -Name VMName -Type String -Attribute Key -Description "Specifies the name of the virtual machine whose hard disk drive is to be manipulated"
    New-xDscResourceProperty -Name Path -Type String -Attribute Key -Description "Specifies the full path to the location of the VHD that represents the hard disk drive"
    New-xDscResourceProperty -Name ControllerType -Type String -Attribute Write -ValidateSet "IDE","SCSI" -Description "Specifies the controller type - IDE/SCSI where the disk is attached"
    New-xDscResourceProperty -Name ControllerNumber -Type Uint32 -Attribute Write -ValidateSet 0,1,2,3 -Description "Specifies the number of the controller where the disk is attached"
    New-xDscResourceProperty -Name ControllerLocation -Type Uint32 -Attribute Write -Description "Specifies the number of the location on the controller where the disk is attached"
    New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present","Absent" -Description "Specifies if the hard disk drive must be present or absent"
)
