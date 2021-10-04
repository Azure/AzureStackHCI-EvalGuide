New-xDscResource -Name MSFT_xVMScsiController -Path . -ClassVersion 1.0.0 -FriendlyName xVMScsiController -Property $(
    New-xDscResourceProperty -Name VMName -Type String -Attribute Key -Description "Specifies the name of the virtual machine whose SCSI controller status is to be controlled"
    New-xDscResourceProperty -Name ControllerNumber -Type Uint32 -Attribute Key -ValidateSet 0,1,2,3 -Description "Specifies the number of the SCSI controller whose status is to be controlled"
    New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present","Absent" -Description "Specifies if the SCSI controller should exist or not"
)
