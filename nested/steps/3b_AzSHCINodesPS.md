Deploy nested Azure Stack HCI nodes with PowerShell
==============
Overview
-----------

With your Hyper-V host up and running, along with the management infrastructure, it's now time to deploy the Azure Stack HCI nodes into VMs on your Hyper-V host.  For this, you'll be using a simple PowerShell script to automate much of the creation experience.

Contents
-----------
* [Architecture](#architecture)
* [Create your first nested Azure Stack HCI node](#create-your-first-nested-azure-stack-hci-node)
* [Repeat creation process](#repeat-creation-process)
* [Next steps](#next-steps)

Architecture
-----------

As shown on the architecture graphic below, in this step, **you'll deploy a number of nested Azure Stack HCI nodes**. The minimum number for deployment of a local Azure Stack HCI cluster is **2 nodes**, however if your Hyper-V host has enough spare capacity, you could deploy additional nested nodes, and explore more complex scenarios, such as a nested **stretch cluster**.  For the purpose of this step, we'll focus on deploying 4 nodes, however you should make adjustments based on your environment.

![Architecture diagram for Azure Stack HCI nested](/media/nested_virt_nodes.png "Architecture diagram for Azure Stack HCI nested")

Create your first nested Azure Stack HCI node
-----------
There are 3 main steps to create the virtualized Azure Stack HCI node on our Hyper-V host:

1. Create the AZSHCINODE01 VM using PowerShell
2. Complete the Out of Box Experience (OOBE)
3. Join the domain using SConfig

### Create the AZSHCINODE01 VM using PowerShell ###
On your Hyper-V host, **open PowerShell as administrator**.  Make any changes that you require, to the script below, and then run it:

```powershell
# Define the characteristics of the VM, and create
$nodeName = "AZSHCINODE01"
New-VM `
    -Name $nodeName  `
    -MemoryStartupBytes 4GB `
    -SwitchName "InternalNAT" `
    -Path "C:\VMs\" `
    -NewVHDPath "C:\VMs\$nodeName\Virtual Hard Disks\$nodeName.vhdx" `
    -NewVHDSizeBytes 30GB `
    -Generation 2
```

#### Dynamic Memory and Runtime Memory Resize ####
When Hyper-V is running inside a virtual machine, the virtual machine must be turned off to adjust its memory. This means that even if dynamic memory is enabled, **the amount of memory will not fluctuate**. For virtual machines without dynamic memory enabled, any attempt to adjust the amount of memory while it's on will fail.  Note that simply enabling nested virtualization will have no effect on dynamic memory or runtime memory resize. The incompatibility only occurs while Hyper-V is running in the VM.

**NOTE** If you have additional capacity, feel free to allocate higher levels of memory to your AZSHCINODE01 VM.

Once the VM is successfully created, you should connect the Azure Stack HCI ISO file, downloaded earlier.

```powershell
# Disable Dynamic Memory
Set-VMMemory -VMName $nodeName -DynamicMemoryEnabled $false
# Add the DVD drive, attach the ISO to DC01 and set the DVD as the first boot device
$DVD = Add-VMDvdDrive -VMName $nodeName -Path C:\ISO\AzSHCI.iso -Passthru
Set-VMFirmware -VMName $nodeName -FirstBootDevice $DVD
```

Finally, you need to add some additional network adapters, set the vCPU count, enable nested virtualization, and add data hard drives.

```powershell
# Set the VM processor count for the VM
Set-VM -VMname $nodeName -ProcessorCount 4
# Add the virtual network adapters to the VM and configure appropriately
1..3 | ForEach-Object { 
    Add-VMNetworkAdapter -VMName $nodeName -SwitchName InternalNAT
    Set-VMNetworkAdapter -VMName $nodeName -MacAddressSpoofing On -AllowTeaming On 
}
# Create the DATA virtual hard disks and attach them
$dataDrives = 1..4 | ForEach-Object { New-VHD -Path "C:\VMs\$nodeName\Virtual Hard Disks\DATA0$_.vhdx" -Dynamic -Size 100GB }
$dataDrives | ForEach-Object {
    Add-VMHardDiskDrive -Path $_.path -VMName $nodeName
}
# Disable checkpoints
Set-VM -VMName $nodeName -CheckpointType Disabled
# Enable nested virtualization
Set-VMProcessor -VMName $nodeName -ExposeVirtualizationExtensions $true -Verbose
```

When those commands have completed, this is what you would see in Hyper-V Manager, in the settings view:

![Finished settings for the AZSHCINODE01 node](/media/azshci_settings_ps.png "Finished settings for the AZSHCINODE01 node")

With the VM configured correctly, you can use the following commands to connect to the VM using VM Connect, and at the same time, start the VM.  To boot from the ISO, you'll need to click on the VM and quickly press a key to trigger the boot from the DVD inside the VM.  If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

```powershell
# Open a VM Connect window, and start the VM
vmconnect.exe localhost $nodeName
Start-VM -Name $nodeName
```

![Booting the VM and triggering the boot from DVD](/media/boot_from_dvd.png "Booting the VM and triggering the boot from DVD")

### Complete the Out of Box Experience (OOBE) ###
With the VM running, and the boot process initiated, you should be in a position to start the deployment of the Azure Stack HCI OS.

![Initiate setup of the Azure Stack HCI OS](/media/azshci_setup.png "Initiate setup of the Azure Stack HCI OS")

Proceed through the process, making the following selections:

1. On the initial screen, select your **Language to install**, **Time and currency format**, and **Keyboard or input method**, then press **Next**
2. Click **Install now**
3. On the **Applicable notices and license terms** screen, read the information, **tick I accept the license terms** and click **Next**
4. On the **What type of installation do you want** screen, select **Custom: Install the newer version of Azure Stack HCI only (advanced)** and click **Next**
5. On the **Where do you want to install Azure Stack HCI?** screen, select the **30GB Drive 0** and click **Next**

Installation will then begin, and will take a few minutes, automatically rebooting as part of the process.

![Completed setup of the Azure Stack HCI OS](/media/azshci_setup_complete.png "Completed setup of the Azure Stack HCI OS")

With the installation complete, you'll be prompted to change the password before logging in.  Enter a password and exit to command line. Once complete, you should be at the **command prompt** on the "Welcome to Azure Stack HCI" screen.  Minimize the VM Connect window.

#### Configure Azure Stack HCI node networking using PowerShell Direct ####
With the node up and running, it's time to configure the networking with PowerShell Direct, so it can communicate with the rest of the environment.  Open **PowerShell** as an administrator on the Hyper-V host, and run the following:

```powershell
# Define local credentials
$azsHCILocalCreds = Get-Credential -UserName "Administrator" -Message "Enter the password used when you deployed the Azure Stack HCI OS"
# Define new name and IP
$nodeName = "AZSHCINODE01"
$newIP = "192.168.0.4"
Invoke-Command -VMName "$nodeName" -Credential $azsHCILocalCreds -ScriptBlock {
    # Set Static IP
    New-NetIPAddress -IPAddress "$using:newIP" -DefaultGateway "192.168.0.1" -InterfaceAlias "Ethernet" -PrefixLength "24" | Out-Null
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("192.168.0.2")
    $nodeIP = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" | Select-Object IPAddress
    Write-Verbose "The currently assigned IPv4 address for $using:nodeName is $($nodeIP.IPAddress)" -Verbose 
}
```

### Join the domain using PowerShell Direct ###
To save a later step, you can quickly use PowerShell Direct to join your AZSHCINODE01 to the domain:

```powershell
$azsHCILocalCreds = Get-Credential -UserName "Administrator" -Message "Enter the password used when you deployed the Azure Stack HCI OS"
# Define domain-join credentials
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
# Define node name
$nodeName = "AZSHCINODE01"
Invoke-Command -VMName "$nodeName" -Credential $azsHCILocalCreds -ScriptBlock {
    # Join the domain and change the name at the same time
    Add-Computer -DomainName azshci.local -NewName $Using:nodeName -Credential $Using:domainCreds -Force
}

Write-Verbose "Rebooting node for changes to take effect" -Verbose
Stop-VM -Name $nodeName
Start-VM -Name $nodeName

# Test for the node to be back online and responding
while ((Invoke-Command -VMName $nodeName -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "$nodeName is now online. Proceed to the next step...." -Verbose
```

### Enable the Hyper-V role on your Azure Stack HCI Node ###
There is an **bug** in the **public preview** when running Azure Stack HCI within a nested virtualization configuration, specifically, when using Windows Admin Center to enable the Hyper-V role, within a running instance of Azure Stack HCI, inside a **Generation 2 Hyper-V VM**.  To workaround this, you can run the following PowerShell command **from the Hyper-V host** to fix this issue.

```powershell
# Provide the domain credentials to log into the VM
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
# Define node name
Invoke-Command -VMName "$nodeName" -Credential $domainCreds -ScriptBlock {
    # Enable the Hyper-V role within the Azure Stack HCI OS
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -Verbose
}

Write-Verbose "Rebooting node for changes to take effect" -Verbose
Stop-VM -Name $nodeName
Start-VM -Name $nodeName

# Test for the node to be back online and responding
while ((Invoke-Command -VMName $nodeName -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "$nodeName is now online. Proceeding to install Hyper-V PowerShell...." -Verbose

Invoke-Command -VMName "$nodeName" -Credential $domainCreds -ScriptBlock {
    # Enable the Hyper-V PowerShell within the Azure Stack HCI OS
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -All -NoRestart -Verbose
}

Write-Verbose "Rebooting node for changes to take effect" -Verbose
Stop-VM -Name $nodeName
Start-VM -Name $nodeName

# Test for the node to be back online and responding
while ((Invoke-Command -VMName $nodeName -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "$nodeName is now online. Proceed to the next step...." -Verbose
```

When prompted, ensure you **restart** the OS to complete the installation of the Hyper-V role.

Repeat creation process
-----------
You have now created your first Azure Stack HCI node, inside a VM, running nested on Hyper-V.  You need a minimum of 2 nodes for deployment of an Azure Stack HCI cluster, so **repeat the creation process** to add at least one additional node, or more, depending on your Hyper-V host resources.  Use AZSHCINODE0x for your node names and increment your IP addresses by 1 for each node you add, so 192.168.0.5, 192.168.0.6 and so on. - you should only have to change the **nodeName** and **newIP** parameters and then rerun the PowerShell commands.

Next Steps
-----------
In this step, you've successfully created your nested Azure Stack HCI nodes.  You can now proceed to [create your Azure Stack HCI cluster](/nested/steps/4_AzSHCICluster.md "Create your Azure Stack HCI cluster")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI, Windows Admin Center, or the Azure Arc integration and experience, let us know!  We want to hear from you!  [Head on over to our Azure Stack HCI UserVoice page](https://feedback.azure.com/forums/929833-azure-stack-hci "Azure Stack HCI UserVoice"), where you can share your thoughts and ideas about making the technologies better.  If however, you have an issue that you'd like some help with, read on...

Raising issues
-----------
If you notice something is wrong with the evaluation guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If however, you're having a problem with Azure Stack HCI **outside** of this evaluation guide, make sure you post to [our Microsoft Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Microsoft Q&A Forum"), where Microsoft experts and valuable members of the Azure Stack HCI community will do their best to help you.