Deploy nested Azure Stack HCI nodes with the GUI
==============
Overview
-----------

With your Hyper-V host up and running, along with the management infrastructure, it's now time to deploy the Azure Stack HCI nodes into VMs on your Hyper-V host.

Architecture
-----------

As shown on the architecture graphic below, in this step, **you'll deploy a number of nested Azure Stack HCI nodes**. The minimum number for deployment of a local Azure Stack HCI cluster is **2 nodes**, however if your Hyper-V host has enough spare capacity, you could deploy additional nested nodes, and explore more complex scenarios, such as a nested **stretch cluster**.  For the purpose of this step, we'll focus on deploying 4 nodes, however you should make adjustments based on your environment.

![Architecture diagram for Azure Stack HCI nested](/media/nested_virt_nodes.png "Architecture diagram for Azure Stack HCI nested")

Create your first nested Azure Stack HCI node
-----------
There are 3 main steps to create the virtualized Azure Stack HCI node on our Hyper-V host:

1. Create the AZSHCINODE01 VM using Hyper-V Manager
2. Complete the Out of Box Experience (OOBE)
3. Join the domain using SConfig

### Create the AZSHCINODE01 VM using Hyper-V Manager ###
In this step, you'll be using Hyper-V Manager to deploy an Azure Stack HCI node.

1. On your Hyper-V host, **open Hyper-V Manager**.
2. In the top right-corner, under **Actions**, click **New**, then **Virtual Machine**. The **New Virtual Machine Wizard** should open.
3. On the **Before you begin** page, click **Next**
4. On the **Specify Name and Location** page, enter **AZSHCINODE01**
5. Tick the box for **Store the virtual machine in a different location** and click **Browse**
6. In the **Select Folder** window, click on **This **PC****, navigate to **C:**, click on the **VMs** folder, click **Select Folder** and then click **Next**

![Specify VM name and location](/media/new_vm_node.png)

7. On the **Specify Generation** page, select **Generation 2** and click **Next**
8. On the **Assign Memory** page, assign 4GB memory by entering **4096** for Startup memory and leave the the **Use Dynamic Memory for this virtual machine** empty, then click **Next**

![Assign VM memory](/media/new_vm_node_memory.png)

#### Dynamic Memory and Runtime Memory Resize ####
When Hyper-V is running inside a virtual machine, the virtual machine must be turned off to adjust its memory. This means that even if dynamic memory is enabled, **the amount of memory will not fluctuate**. For virtual machines without dynamic memory enabled, any attempt to adjust the amount of memory while it's on will fail.  Note that simply enabling nested virtualization will have no effect on dynamic memory or runtime memory resize. The incompatibility only occurs while Hyper-V is running in the VM.

**NOTE** If you have additional capacity, feel free to allocate higher levels of memory to your AZSHCINODE01 VM.

9. On the **Configure Networking** page, select **InternalNAT** and click **Next**
10. On the **Connect Virtual Hard Disk** page, change **size** to **30** and click **Next**

![Connect Virtual Hard Disk](/media/new_vm_node_vhd.png)

11. On the **Installation Options** page, select **Install an operating system from a bootable image file**, and click **Browse**
12. Navigate to **C:\ISO** and select your **AzSHCI.iso** file, and click **Open**.  Then click **Next**
13. On the **Completing the New Virtual Machine Wizard** page, review the information and click **Finish**

Your new AZSHCINODE01 virtual machine will now be created.  Once created, we need to make a few final modifications.

1. In **Hyper-V Manager**, right-click **AZSHCINODE01** and click **Settings**
2. Select **Add Hardware**, select **Network Adapter** and click **Add**
3. In the **Network Adapter** window, under **Virtual Switch**, use the drop down to select **InternalNAT**, then click **Apply**
4. Repeat **Steps 2-3** to create an **additional** 2 network adapters all attached to **InternalNAT**
5. Once you have **4 network adapters**, click on **Processor**
6. For **Number of virtual processors**, choose a number appropriate to your underlying hardware. In this case, we'll choose **4** but we can adjust this later, then click **Apply**

![Configuring the vm settings](/media/new_vm_node_settings.png)

You now need to add additional hard drives to support the Azure Stack HCI nodes and cluster.  You need to add a minimum of 2 data disks, but we will add 4 data disks to each node.

7. Still within **AZSHCINODE01 settings**, click on **SCSI Controller**, then **Hard Drive** and click **Add**
8. In the **Hard Drive** window, click **New**.  The **New Virtual Hard Disk** wizard opens, then click **Next**
9. On the **Choose Disk Type** page, ensure **Dynamically expanding** is selected, then click **Next**
10. On the **Specify Name and Location** page, enter **DATA01.vhdx**, and change the location to **C:\VMs\AZSHCINODE01\Virtual Hard Disks**, then click **Next**

![Adding additional hard drives to AzSHCINode01](/media/azshci_data_disk.png)

11. On the **Configure Disk** page, ensure **Create a blank virtual hard disk** is selected, set size to **100**, then click **Next**
12. On the **Completing the New Virtual Hard Disk Wizard** page, review your settings and click **Finish**
13. Back in the **AZSHCINODE01 settings**, click **Apply**
14. **Repeat steps 7-13** to add **at least 3 more data disks**

![Finished adding additional hard drives to AzSHCINode01](/media/azshci_disks_added.png)

Before starting the VM, in order to enable Hyper-V to function inside the AZSHCINODE01 virtual machine, we need to run a quick PowerShell command to facilitate this.  Open **PowerShell as administrator** and run the following:

```powershell
Set-VMProcessor -VMName AZSHCINODE01 -ExposeVirtualizationExtensions $true -Verbose
```

![Enabling nested virtualization on AZSHCINODE01](/media/enable_nested.png)

With the VM configured correctly, in **Hyper-V Manager**, double-click the AZSHCINODE01 VM.  This should open the VM Connect window.

![Starting up AZSHCINODE01](/media/node_turned_off.png)

In the center of the window, there is a message explaining the VM is currently switched off.  Click on **Start** and then quickly **press any key** inside the VM to boot from the ISO file. If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

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

### Join the domain using SConfig ###
Need to validate if this step is required

Repeat creation process
-----------
You have now created your first Azure Stack HCI node, inside a VM, running nested on Hyper-V.  You need a minimum of 2 nodes for deployment of an Azure Stack HCI cluster, so **repeat the creation process** to add at least one additional node, or more, depending on your Hyper-V host resources.  Use AZSHCINODE0x for your node names.

Next Steps
-----------
In this step, you've successfully created your nested Azure Stack HCI nodes.  You can now proceed to [create your Azure Stack HCI cluster](/universal/4_AzSHCICluster.md "Create your Azure Stack HCI cluster")