Deploy nested Azure Stack HCI nodes with PowerShell
==============
Overview
-----------

With your Hyper-V host up and running, along with the management infrastructure, it's now time to deploy the Azure Stack HCI nodes into VMs on your Hyper-V host.  For this, you'll be using a simple PowerShell script to automate much of the creation experience.

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
# Add the DVD drive, attach the ISO to DC01 and set the DVD as the first boot device
$DVD = Add-VMDvdDrive -VMName $nodeName -Path C:\ISO\AzSHCI.iso -Passthru
Set-VMFirmware -VMName $nodeName -FirstBootDevice $DVD
```

Finally, you need to add some additional network adapters, set the vCPU count, enable nested virtualization, and add data hard drives.

```powershell
# Set the VM processor count for the VM
Set-VM -VMname $nodeName -ProcessorCount 4
# Add the virtual network adapters to the VM
1..3 | ForEach-Object { Add-VMNetworkAdapter -VMName $nodeName -SwitchName InternalNAT }
# Create the DATA virtual hard disks and attach them
$dataDrives = 1..4 | ForEach-Object { New-VHD -Path "C:\VMs\$nodeName\Virtual Hard Disks\DATA0$_.vhdx" -Dynamic -Size 100GB }
$dataDrives | ForEach-Object {
    Add-VMHardDiskDrive -Path $_.path -VMName $nodeName
}
# Enable nested virtualization
Set-VMProcessor -VMName $nodeName -ExposeVirtualizationExtensions $true -Verbose
```
![Finished settings for the AZSHCINODE01 node](/media/azshci_settings_ps.png)

With the VM configured correctly, you can use the following commands to connect to the VM using VM Connect, and at the same time, start the VM.  To boot from the ISO, you'll need to click on the VM and quickly press a key to trigger the boot from the DVD inside the VM.  If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

```powershell
# Open a VM Connect window, and start the VM
vmconnect.exe localhost $nodeName
Start-VM -Name $nodeName
```

![Booting the VM and triggering the boot from DVD](/media/boot_from_dvd.png)

### Complete the Out of Box Experience (OOBE) ###
With the VM running, and the boot process initiated, you should be in a position to start the deployment of the Azure Stack HCI OS.

![Initiate setup of the Azure Stack HCI OS](/media/azshci_setup.png)

Proceed through the process, making the following selections:

1. On the initial screen, select your **Language to install**, **Time and currency format**, and **Keyboard or input method**, then press **Next**
2. Click **Install now**
3. On the **Applicable notices and license terms** screen, read the information, **tick I accept the license terms** and click **Next**
4. On the **What type of installation do you want** screen, select **Custom: Install the newer version of Azure Stack HCI only (advanced)** and click **Next**
5. On the **Where do you want to install Azure Stack HCI?** screen, select the **30GB Drive 0** and click **Next**

Installation will then begin, and will take a few minutes, automatically rebooting as part of the process.

![Completed setup of the Azure Stack HCI OS](/media/azshci_setup_complete.png)

With the installation complete, you'll be prompted to change the password before logging in.  Enter a password, and once complete, you should be at the **C:\Users\Administrator** screen.  If you enter **ipconfig** at the command prompt, you should find that all 4 of your network adapters have been assigned an IP from your DHCP Server.

![Showing network IP addresses on AZSHCINODE01](/media/node_ipconfig.png)

One additional step is to rename the AZSHCINODE01 OS, so still within the **cmd prompt**, type **PowerShell** to open the local PowerShell instance, and then run:

```powershell
Rename-Computer -NewName "AZSHCINODE01" -Restart
```

The machine will reboot automatically and within a few moments, will be back online.

### Join the domain using PowerShell Direct ###
Need to validate if this step is required

Repeat creation process
-----------
You have now created your first Azure Stack HCI node, inside a VM, running nested on Hyper-V.  You need a minimum of 2 nodes for deployment of an Azure Stack HCI cluster, so **repeat the creation process** to add at least one additional node, or more, depending on your Hyper-V host resources.  Use AZSHCINODE0x for your node names - you should only have to change the **$nodeName** and then rerun the PowerShell commands.

Next Steps
-----------
In this step, you've successfully created your nested Azure Stack HCI nodes.  You can now proceed to [create your Azure Stack HCI cluster](/universal/4_AzSHCICluster.md "Create your Azure Stack HCI cluster")