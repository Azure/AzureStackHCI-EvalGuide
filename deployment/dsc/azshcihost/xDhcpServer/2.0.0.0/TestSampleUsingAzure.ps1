# To Run this test create a Windows Server 2012 or 2012 R2 VM in Azure
# and run this script.  It will prompt you to choose a VM, choose the VM.
# wait a while, RDP into the machine and manually verify that the DHCP Server
# is configured as specified in .\samples\SampleConfiguration.ps1

Write-Verbose -Message 'Publishing configuration ...' -Verbose
Publish-AzureVMDscConfiguration -ConfigurationPath .\Samples\SampleConfiguration.ps1  -Verbose -force
Write-Verbose -Message 'Choosing VM ...' -Verbose
$vm = get-azurevm | Out-GridView -Title 'choose vm to test with' -OutputMode Single 
if($vm)
{
    Write-Verbose -Message 'Setting Extension ...' -Verbose
    Set-AzureVMDscExtension -ConfigurationArchive SampleConfiguration.ps1.zip -ConfigurationName Sample_xDhcpsServerScope_NewScope -VM $vm -Verbose
    Write-Verbose -Message 'Updating Vm ...' -Verbose
    $vm | Update-AzureVM
}
Write-Verbose -Message 'Done' -Verbose
