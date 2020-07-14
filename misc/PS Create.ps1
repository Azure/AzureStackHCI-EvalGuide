## VM Account
# Credentials for Local Admin account you created in the sysprepped (generalized) vhd image
$cred = Get-Credential
## Azure Account
$LocationName = "eastus"
$ResourceGroupName = "MyResourceGroup"

## VM
$OSDiskName = "MyClient"
$ComputerName = "MyClientVM"
$VMName = "MyVM"
$VMSize = "Standard_D4_v3"
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"

## Networking
$NetworkName = "MyNet"
$NICName = "MyNIC"
$PublicIPAddressName = "MyPIP"
$SubnetName = "MySubnet"
$SubnetAddressPrefix = "10.0.0.0/24"
$VnetAddressPrefix = "10.0.0.0/16"

$SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
$PIP = New-AzPublicIpAddress -Name $PublicIPAddressName -DomainNameLabel $DNSNameLabel -ResourceGroupName $ResourceGroupName -Location $LocationName -AllocationMethod Dynamic
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize | `
    Set-AzVMOperatingSystem -Windows -ComputerName $ComputerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate | `
    Add-AzVMNetworkInterface -Id $NIC.Id | `
    Set-AzVMOSDisk -Name $OSDiskName -StorageAccountType "StandardSSD_LRS" -CreateOption "FromImage" -Caching $OSDiskCaching | `
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" | `
    Set-AzVMBootDiagnostic -Disable

New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose