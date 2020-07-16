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

1. Create the AzsHCINode01 VM using Hyper-V Manager
2. Complete the Out of Box Experience (OOBE)
3. Join the domain using SConfig

### Create the AzSHCINode01 VM using Hyper-V Manager ###
In this step, you'll be using Hyper-V Manager to deploy an Azure Stack HCI node.

1. On your Hyper-V host, **open Hyper-V Manager**.
2. In the top right-corner, under **Actions**, click **New**, then **Virtual Machine**. The **New Virtual Machine Wizard** should open.
3. On the **Before you begin** page, click **Next**
4. On the **Specify Name and Location** page, enter **AzSHCINode01**
5. Tick the box for **Store the virtual machine in a different location** and click **Browse**
6. In the **Select Folder** window, click on **This **PC****, navigate to **C:**, click on **New Folder**, name it **VMs** then click **Select Folder** and click **Next**

![Specify VM name and location](/media/new_vm_name.png)

7. On the **Specify Generation** page, select **Generation 2** and click **Next**
8. On the **Assign Memory** page, assign 4GB memory by entering **4096** for Startup memory and leave the the **Use Dynamic Memory for this virtual machine** empty, then click **Next**

![Assign VM memory](/media/new_vm_dynamicmem.png)

**NOTE** If you have additional capacity, feel free to allocate higher levels of memory to your AzSHCINode01 VM.

9. On the **Configure Networking** page, select **InternalNAT** and click **Next**
10. On the **Connect Virtual Hard Disk** page, change **size** to **30** and click **Next**

![Connect Virtual Hard Disk](/media/new_vm_vhd.png)

11. On the **Installation Options** page, select **Install an operating system from a bootable image file**, and click **Browse**
12. Navigate to **C:\ISO** and select your **AzSHCI.iso** file, and click **Open**.  Then click **Next**
13. On the **Completing the New Virtual Machine Wizard** page, review the information and click **Finish**

Your new AzSHCINode01 virtual machine will now be created.  Once created, we need to make a few final modifications.

#### Dynamic Memory and Runtime Memory Resize ####
When Hyper-V is running inside a virtual machine, the virtual machine must be turned off to adjust its memory. This means that even if dynamic memory is enabled, **the amount of memory will not fluctuate**. For virtual machines without dynamic memory enabled, any attempt to adjust the amount of memory while it's on will fail.  Note that simply enabling nested virtualization will have no effect on dynamic memory or runtime memory resize. The incompatibility only occurs while Hyper-V is running in the VM.

Before starting the VM, in order to enable Hyper-V to function inside the AzSHCINode01 virtual machine, we need to run a quick PowerShell command to facilitate this.  Open **PowerShell as administrator** and run the following:

```powershell
Set-VMProcessor -VMName AzSHCINode01 -ExposeVirtualizationExtensions $true
```

With the VM configured correctly, in **Hyper-V Manager**, double-click the AzSHCINode01 VM.  This should open the VM Connect window.

![Starting up AzSHCINode01](/media/startvm.png)

In the center of the window, there is a message explaining the VM is currently switched off.  Click on **Start** and then quickly **press any key** inside the VM to boot from the ISO file. If you miss the prompt to press a key to boot from CD or DVD, simply reset the VM and try again.

![Booting the VM and triggering the boot from DVD](/media/boot_from_dvd.png)