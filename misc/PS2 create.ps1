$cred = Get-Credential
$VMsize = "Standard_D4_v3"
$VMname = "AzSHCIHost001"
$RGName = "AzSHCILab"
$RGlocation = "eastus"
$OSDiskName = "$VMname" + "001vhd"
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize | `
    Set-AzVMOperatingSystem -Windows -ComputerName $VMname -Credential $cred -ProvisionVMAgent -EnableAutoUpdate | `
    Set-AzVMOSDisk -Name $OSDiskName -StorageAccountType "StandardSSD_LRS" -CreateOption "FromImage" | `
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" | `
    Set-AzVMBootDiagnostic -Disable

New-AzResourceGroup -Name "$RGName" -Location "$RGlocation"

New-AzVM `
    -ResourceGroupName "$RGName" `
    -Location "$RGlocation" `
    -VM $VirtualMachine `
    -VirtualNetworkName "AzSHCILabvNet" `
    -SubnetName "AzSHCILabSubnet" `
    -SecurityGroupName "AzSHCILabNSG" `
    -PublicIpAddressName "AzSHCILabPubIP" `
    -OpenPorts 3389 `
    -Verbose