Deploy nested Azure Stack HCI 20H2 nodes with PowerShell
==============
Overview
-----------

With your Hyper-V host up and running, along with the management infrastructure, it's now time to deploy the Azure Stack HCI 20H2 nodes into VMs on your Hyper-V host.  For this, you'll be using a simple PowerShell script to automate much of the creation experience.

Contents
-----------
- [Overview](#overview)
- [Contents](#contents)
- [Architecture](#architecture)
- [Create your first nested Azure Stack HCI 20H2 node](#create-your-first-nested-azure-stack-hci-20h2-node)
- [Repeat creation process](#repeat-creation-process)
- [Next Steps](#next-steps)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)
- [Full Script - Creating your AzSHCI Nodes](#full-script---creating-your-azshci-nodes)

Architecture
-----------

As shown on the architecture graphic below, in this step, **you'll deploy a number of nested Azure Stack HCI 20H2 nodes**. The minimum number for deployment of a local Azure Stack HCI 20H2 cluster is **2 nodes**, however if your Hyper-V host has enough spare capacity, you could deploy additional nested nodes, and explore more complex scenarios, such as a nested **stretch cluster**.  For the purpose of this step, we'll focus on deploying 2 nodes, however you should make adjustments based on your environment.

![Architecture diagram for Azure Stack HCI 20H2 nested](/archive/media/nested_virt_nodes_ga.png "Architecture diagram for Azure Stack HCI 20H2 nested")

Create your first nested Azure Stack HCI 20H2 node
-----------
There are 3 main steps to create the virtualized Azure Stack HCI 20H2 node on our Hyper-V host:

1. Create the AZSHCINODE01 VM using PowerShell
2. Complete the Out of Box Experience (OOBE)
3. Join the domain using SConfig

### Create the AZSHCINODE01 VM using PowerShell ###
On your Hyper-V host, **open PowerShell as administrator**.  Make any changes that you require, to the script below, and then run it. You'll notice I'm using 24GB memory for my nodes, but if you're running on a smaller system, adjust accordingly.  If you're deploying nested in Azure, and used the recommended host VM size, you should have 64GB memory available to use across your nested configuration.

```powershell
# Define the characteristics of the VM, and create
$nodeName = "AZSHCINODE01"
$newIP = "192.168.0.4"
New-VM `
    -Name $nodeName  `
    -MemoryStartupBytes 24GB `
    -SwitchName "InternalNAT" `
    -Path "C:\VMs\" `
    -NewVHDPath "C:\VMs\$nodeName\Virtual Hard Disks\$nodeName.vhdx" `
    -NewVHDSizeBytes 30GB `
    -Generation 2
```

#### Dynamic Memory and Runtime Memory Resize ####
When Hyper-V is running inside a virtual machine, the virtual machine must be turned off to adjust its memory. This means that even if dynamic memory is enabled, **the amount of memory will not fluctuate**. For virtual machines without dynamic memory enabled, any attempt to adjust the amount of memory while it's on will fail.  Note that simply enabling nested virtualization will have no effect on dynamic memory or runtime memory resize. The incompatibility only occurs while Hyper-V is running in the VM.

**NOTE** If you have additional capacity, feel free to allocate higher levels of memory to your AZSHCINODE01 VM.

Once the VM is successfully created, you should connect the Azure Stack HCI 20H2 ISO file, downloaded earlier.

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
Set-VM -VMname $nodeName -ProcessorCount 16
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

![Finished settings for the AZSHCINODE01 node](/archive/media/azshci_settings_ps_ga.png "Finished settings for the AZSHCINODE01 node")

With the VM configured correctly, you can use the following commands to connect to the VM using VM Connect, and at the same time, start the VM.  To boot from the ISO, you'll need to click on the VM and quickly press a key to trigger the boot from the DVD inside the VM.  If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

```powershell
# Open a VM Connect window, and start the VM
vmconnect.exe localhost $nodeName
Start-Sleep -Seconds 5
Start-VM -Name $nodeName
```

![Booting the VM and triggering the boot from DVD](/archive/media/boot_from_dvd.png "Booting the VM and triggering the boot from DVD")

### Complete the Out of Box Experience (OOBE) ###
With the VM running, and the boot process initiated, you should be in a position to start the deployment of the Azure Stack HCI 20H2 OS.

![Initiate setup of the Azure Stack HCI 20H2 OS](/archive/media/azshci_setup.png "Initiate setup of the Azure Stack HCI 20H2 OS")

Proceed through the process, making the following selections:

1. On the initial screen, select your **Language to install**, **Time and currency format**, and **Keyboard or input method**, then press **Next**
2. Click **Install now**
3. On the **Applicable notices and license terms** screen, read the information, **tick I accept the license terms** and click **Next**
4. On the **What type of installation do you want** screen, select **Custom: Install the newer version of Azure Stack only (advanced)** and click **Next**
5. On the **Where do you want to install Azure Stack HCI?** screen, select the **30GB Drive 0** and click **Next**

Installation will then begin, and will take a few minutes, automatically rebooting as part of the process.

![Completed setup of the Azure Stack HCI 20H2 OS](/archive/media/azshci_setup_complete.png "Completed setup of the Azure Stack HCI 20H2 OS")

With the installation complete, you'll be prompted to change the password before logging in.  Enter a password and exit to command line. Once complete, you should be at the **command prompt** on the "Welcome to Azure Stack HCI" screen.  Minimize the VM Connect window.

#### Configure Azure Stack HCI 20H2 node networking using PowerShell Direct ####
With the node up and running, it's time to configure the networking with PowerShell Direct, so it can communicate with the rest of the environment.  Open **PowerShell** as an administrator on the Hyper-V host, and run the following:

```powershell
# Define local credentials
$azsHCILocalCreds = Get-Credential -UserName "Administrator" -Message "Enter the password used when you deployed the Azure Stack HCI 20H2 OS"
# Refer to earlier in the script for $nodeName and $newIP
Invoke-Command -VMName $nodeName -Credential $azsHCILocalCreds -ScriptBlock {
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
# Define domain-join credentials
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
Invoke-Command -VMName $nodeName -Credential $azsHCILocalCreds -ArgumentList $domainCreds -ScriptBlock {
    # Change the name and join domain
    Rename-Computer -NewName $Using:nodeName -LocalCredential $Using:azsHCILocalCreds -Force -Verbose
    Start-Sleep -Seconds 5
    Add-Computer -DomainName "azshci.local" -Credential $Using:domainCreds -Force -Options JoinWithNewName,AccountCreate -Restart -Verbose
}

# Test for the node to be back online and responding
while ((Invoke-Command -VMName $nodeName -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
    Write-Host "Waiting for server to come back online"
}
Write-Verbose "$nodeName is now online. Proceed to the next step...." -Verbose
```

### Enable the Hyper-V role on your Azure Stack HCI 20H2 Node ###
There is an **bug** when running Azure Stack HCI 20H2 within a nested virtualization configuration, specifically, when using Windows Admin Center to enable the Hyper-V role, within a running instance of Azure Stack HCI 20H2, inside a **Generation 2 Hyper-V VM**.  To workaround this, you can run the following PowerShell command **from the Hyper-V host** to fix this issue.

```powershell
# Provide the domain credentials to log into the VM
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
Invoke-Command -VMName $nodeName -Credential $domainCreds -ScriptBlock {
    # Enable the Hyper-V role within the Azure Stack HCI 20H2 OS
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -Verbose
}

Write-Verbose "Rebooting node for changes to take effect" -Verbose
Stop-VM -Name $nodeName
Start-Sleep -Seconds 5
Start-VM -Name $nodeName

# Test for the node to be back online and responding
while ((Invoke-Command -VMName $nodeName -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "$nodeName is now online. Proceeding to install Hyper-V PowerShell...." -Verbose

Invoke-Command -VMName $nodeName -Credential $domainCreds -ScriptBlock {
    # Enable the Hyper-V PowerShell within the Azure Stack HCI 20H2 OS
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -All -NoRestart -Verbose
}

Write-Verbose "Rebooting node for changes to take effect" -Verbose
Stop-VM -Name $nodeName
Start-Sleep -Seconds 5
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
You have now created your first Azure Stack HCI 20H2 node, inside a VM, running nested on Hyper-V.  You need a minimum of 2 nodes for deployment of an Azure Stack HCI 20H2 cluster, so **repeat the creation process** to add at least one additional node, or more, depending on your Hyper-V host resources.  Use AZSHCINODE0x for your node names and increment your IP addresses by 1 for each node you add, so 192.168.0.5, 192.168.0.6 and so on. - you should only have to change the **nodeName** and **newIP** parameters and then rerun the PowerShell commands.

Next Steps
-----------
In this step, you've successfully created your nested Azure Stack HCI 20H2 nodes.  You can now proceed to [create your Azure Stack HCI 20H2 cluster](/archive/steps/4_AzSHCICluster.md "Create your Azure Stack HCI 20H2 cluster")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI, Windows Admin Center, or the Azure Arc integration and experience, let us know! We want to hear from you!

For **Azure Stack HCI**, [Head on over to the Azure Stack HCI 21H2 Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Azure Stack HCI 21H2 Q&A"), where you can share your thoughts and ideas about making the technologies better and raise an issue if you're having trouble with the technology.

Raising issues
-----------
If you notice something is wrong with the evaluation guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If however, you're having a problem with Azure Stack HCI 20H2 **outside** of this evaluation guide, make sure you post to [our Microsoft Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Microsoft Q&A Forum"), where Microsoft experts and valuable members of the community will do their best to help you.

Full Script - Creating your AzSHCI Nodes
-----------
Simply repeat this process for each node.  Change the $nodeName and $newIP, then rerun the rest of the steps.

```powershell
# Define the characteristics of the VM, and create
$nodeName = "AZSHCINODE01"
$newIP = "192.168.0.4"

New-VM `
    -Name $nodeName  `
    -MemoryStartupBytes 24GB `
    -SwitchName "InternalNAT" `
    -Path "C:\VMs\" `
    -NewVHDPath "C:\VMs\$nodeName\Virtual Hard Disks\$nodeName.vhdx" `
    -NewVHDSizeBytes 30GB `
    -Generation 2

# Disable Dynamic Memory
Set-VMMemory -VMName $nodeName -DynamicMemoryEnabled $false
# Add the DVD drive, attach the ISO to DC01 and set the DVD as the first boot device
$DVD = Add-VMDvdDrive -VMName $nodeName -Path C:\ISO\AzSHCI.iso -Passthru
Set-VMFirmware -VMName $nodeName -FirstBootDevice $DVD

# Set the VM processor count for the VM
Set-VM -VMname $nodeName -ProcessorCount 16
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

# Open a VM Connect window, and start the VM
vmconnect.exe localhost $nodeName
Start-Sleep -Seconds 5
Start-VM -Name $nodeName

#############################################################################
##### Follow the steps above for initial configuration of the OS ############
#############################################################################

# Define local credentials
$azsHCILocalCreds = Get-Credential -UserName "Administrator" -Message "Enter the password used when you deployed the Azure Stack HCI 20H2 OS"
# Refer to earlier in the script for $nodeName and $newIP
Invoke-Command -VMName $nodeName -Credential $azsHCILocalCreds -ScriptBlock {
    # Set Static IP
    New-NetIPAddress -IPAddress "$using:newIP" -DefaultGateway "192.168.0.1" -InterfaceAlias "Ethernet" -PrefixLength "24" | Out-Null
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("192.168.0.2")
    $nodeIP = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" | Select-Object IPAddress
    Write-Verbose "The currently assigned IPv4 address for $using:nodeName is $($nodeIP.IPAddress)" -Verbose 
}

# Define domain-join credentials
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
Invoke-Command -VMName $nodeName -Credential $azsHCILocalCreds -ArgumentList $domainCreds -ScriptBlock {
    # Change the name and join domain
    Rename-Computer -NewName $Using:nodeName -LocalCredential $Using:azsHCILocalCreds -Force -Verbose
    Start-Sleep -Seconds 5
    Add-Computer -DomainName "azshci.local" -Credential $Using:domainCreds -Force -Options JoinWithNewName,AccountCreate -Restart -Verbose
}

# Test for the node to be back online and responding
while ((Invoke-Command -VMName $nodeName -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
    Write-Host "Waiting for server to come back online"
}
Write-Verbose "$nodeName is now online. Proceed to the next step...." -Verbose

# Provide the domain credentials to log into the VM
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
Invoke-Command -VMName $nodeName -Credential $domainCreds -ScriptBlock {
    # Enable the Hyper-V role within the Azure Stack HCI 20H2 OS
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -Verbose
}

Write-Verbose "Rebooting node for changes to take effect" -Verbose
Stop-VM -Name $nodeName
Start-Sleep -Seconds 5
Start-VM -Name $nodeName

# Test for the node to be back online and responding
while ((Invoke-Command -VMName $nodeName -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "$nodeName is now online. Proceeding to install Hyper-V PowerShell...." -Verbose

Invoke-Command -VMName $nodeName -Credential $domainCreds -ScriptBlock {
    # Enable the Hyper-V PowerShell within the Azure Stack HCI 20H2 OS
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -All -NoRestart -Verbose
}

Write-Verbose "Rebooting node for changes to take effect" -Verbose
Stop-VM -Name $nodeName
Start-Sleep -Seconds 5
Start-VM -Name $nodeName

# Test for the node to be back online and responding
while ((Invoke-Command -VMName $nodeName -Credential $domainCreds {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {
    Start-Sleep -Seconds 1
}
Write-Verbose "$nodeName is now online. Proceed to the next step...." -Verbose
```