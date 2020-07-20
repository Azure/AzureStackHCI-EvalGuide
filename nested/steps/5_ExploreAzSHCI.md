
Explore the management of your Azure Stack HCI environment
==============
Overview
-----------
With all key components deployed, including a management infrastructure, along with clustered Azure Stack HCI nodes, you can now begin to explore some of the additional capabilities within Azure Stack HCI and the Windows Admin Center.  We'll cover a few recommended activities below, to expose you to some of the key elements of the Windows Admin Center, but for the rest, we'll [direct you over to the official documentation](https://docs.microsoft.com/en-us/azure-stack/hci/ "Azure Stack HCI documentation").

Contents
-----------
[Create volumes for VMs](#create-volumes-for-vms)
[Deploy a virtual machine](#deploy-a-virtual-machine)
[Shutting down the environment](#shutting-down-the-environment)
[Next steps](#next-steps)

Create volumes for VMs
-----------
In this step, you'll create some volumes on an Azure Stack HCI cluster by using Windows Admin Center, and enable data deduplication and compression on volumes.

### Create a three-way mirror volume ###
You should be over on **MGMT01**, but if you're not, log into MGMT01, and open the **Windows Admin Center**.  You'll spend your time here for the remainder of the steps documented below.

1. Once logged into the **Windows Admin Center** on **MGMT01**, click on your previously deployed cluster, **azshciclus.azshci.local**
2. On the left hand navigation, under **Storage** select **Volumes**.  The central **Volumes** page shows you should have a single volume currently
3. On the Volumes page, select the **Inventory** tab, and then select **Create**
4. In the **Create volume** pane, enter **VMSTORAGE** for the volume name, and leave **Resiliency** as **Three-way mirror**
5. In Size on HDD, specify **20GB** for the size of the volume, then click **Create**.

![Create a volume on Azure Stack HCI](/media/wac_vm_storage.png "Create a volume on Azure Stack HCI")

6. Creating the volume can take a few minutes. Notifications in the upper-right will let you know when the volume is created. The new volume appears in the Inventory list

![Volume created on Azure Stack HCI](/media/wac_vm_storage_completed.png "Volume created on Azure Stack HCI")

### Create a mirror-accelerated parity volume ###
Mirror-accelerated parity reduces the footprint of the volume on the HDD. For example, a three-way mirror volume would mean that for every 10 terabytes of size, you will need 30 terabytes as footprint. To reduce the overhead in footprint, create a volume with mirror-accelerated parity. This reduces the footprint from 30 terabytes to just 22 terabytes, even with only 4 servers, by mirroring the most active 20 percent of data, and using parity, which is more space efficient, to store the rest. You can adjust this ratio of parity and mirror to make the performance versus capacity tradeoff that's right for your workload. For example, 90 percent parity and 10 percent mirror yields less performance but streamlines the footprint even further.

1. Still in **Windows Admin Center** on **MGMT01**, on the Volumes page, select the **Inventory** tab, and then select **Create**
2. In the **Create volume** pane, enter **VMSTORAGE_PAR** for the volume name, and set **Resiliency** as **Mirror-accelerated parity**
3. In **Parity percentage**, set the percentage of parity to **80% parity, 20% mirror**
4. In Size on HDD, specify **20GB** for the size of the volume, then click **Create**.

For more information on planning volumes with Azure Stack HCI, you should [refer to the official docs](https://docs.microsoft.com/en-us/azure-stack/hci/concepts/plan-volumes "Planning volumes for Azure Stack HCI").

### Turn on deduplication and compression ###
You may have seen, during the **Create volume** wizard, you could have enabled deduplication and compression at creation time, however we wanted to make sure you were fully aware of how to enable it for existing volumes.

1. Still in **Windows Admin Center** on **MGMT01**, on the Volumes page, select the **Inventory** tab, and then select your **VMSTORAGE** volume
2. On the Volume VMSTORAGE pane, you'll see a simple rocker switch to enable **Deduplication and compression**.  Click to enable it, and click **Start**

![Enable deduplication on volume](/media/wac_enable_dedup.png "Enable deduplication on volume")

3. In the **Enable deduplication** pane, use the drop-down to select **Hyper-V** then click **Enable Deduplication**. This should be enabled quickly, as there's no files on the volume.

**NOTE** - You'll notice there there are 3 options; default, Hyper-V and Backup.  If you're interested in learning more about Deduplication in Azure Stack HCI, you should [refer to our documentation](https://docs.microsoft.com/en-us/windows-server/storage/data-deduplication/overview "Deduplication overview")

You now have a couple of volumes created and ready to accept workloads.  Whilst we deployed the volumes using the Windows Admin Center, you can also do the same through PowerShell.  If you're interested in taking that approach, [check out the official docs that walk you through that process](https://docs.microsoft.com/en-us/azure-stack/hci/manage/create-volumes "Official documentation for creating volumes")

Deploy a virtual machine
-----------
In this step, you'll deploy a VM onto your new volume, using Windows Admin Center.

### Create the virtual machine ###
You should still be over on **MGMT01**, but if you're not, log into MGMT01, and open the **Windows Admin Center**.

1. Once logged into the **Windows Admin Center** on **MGMT01**, click on your previously deployed cluster, **azshciclus.azshci.local**
2. On the left hand navigation, under **Compute** select **Virtual machines**.  The central **Virtual machines** page shows you no virtual machines deployed currently
3. On the **Virtual machines** page, select the **Inventory** tab, and then select **New**
4. In the **New virtual machine** pane, enter **VM001** for the name, and enter the following pieces of information, then click **Create**

    * Generation: **Generation 2 (Recommended)**
    * Host: **Leave as recommended**
    * Path: **C:\ClusterStorage\VMSTORAGE**
    * Virtual processors: **1**
    * Startup memory (GB): **0.5**
    * Network: **ComputeSwitch**
    * Storage: **Add, then Create an empty virtual hard disk** and set size to **5GB**
    * Operating System: **Install an operating system later**

5. The creation process will take a few moments, and once complete, **VM001** should show within the **Virtual machines view**
6. Click on the **VM** and then click **Start** - within moments, the VM should be running

![VM001 up and running](/media/wac_vm001.png "VM001 up and running")

7. Click on **VM001** to view the properties and status for this running VM
8. Click on **Connect** - you may get a **VM Connect** prompt:

![Connect to VM001](/media/vm_connect.png "Connect to VM001")

9. Click on **Go to Settings** and in the **Remote Desktop** pane, click on **Allow remote connections to this computer**, then **Save**
10. Click the **Back** button in your browser to return to the VM001 view, then click **Connect**, and when prompted with the certificate prompt, click **Connect** and enter appropriate credentials
11. There's no operating system installed here, so it should show a UEFI boot summary, but the VM is running successfully
12. Click **Disconnect**

You've successfully create a VM using the Windows Admin Center!

### Live migrate the virtual machine ###
The final step we'll cover is using Windows Admin Center to live migrate VM001 from it's current node, to an alternate node in the cluster.

1. Still within the **Windows Admin Center** on **MGMT01**, under **Compute**, click on **Virtual machines**
2. On the **Virtual machines** page, select the **Inventory** tab
3. Under **Host server**, make a note of the node that VM001 is currently running on.  You may need to expand the column width to see the name
4. Next to **VM001**, click the tick box next to VM001, then click **More**. then click **Move**

![Start Live Migration using Windows Admin Center](/media/wac_move.png "Start Live Migration using Windows Admin Center")

5. In the **Move Virtual Machine** pane, ensure **Failover Cluster** is selected, and leave the default **Best available cluster node** to allow Windows Admin Center to pick where to migrate the VM to, then click **Move**
6. The live migration will then begin, and within a few seconds, the VM should be running on a different node.
7. On the left hand navigation, under **Compute** select **Virtual machines** to return to the VM dashboard view, which aggregates information across your cluster, for all of your VMs.

Shutting down the environment
-----------
If you're running the environment in Azure, to save costs, you may wish to shut down your nested VMs, and Hyper-V host.  In order to do so, it's advisable to run the following commands, from the Hyper-V host, to cleanly power down the different components, before powering down the Azure VM itself.

1. On your Hyper-V host, open **PowerShell as administrator**
2. First, using PowerShell Direct, you'll log into one of the Azure Stack HCI nodes to shutdown the cluster, then you'll power down the VMs running on your Hyper-V host

```powershell
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
# Define node name
$nodeName = "AZSHCINODE01"
Invoke-Command -VMName "$nodeName" -Credential $domainCreds -ScriptBlock {
    # Get any running VMs and turn them off
    Get-ClusterResource | Where-Object {$_.ResourceType -eq "Virtual Machine"} | Stop-ClusterResource
    # Stop the cluster
    Stop-Cluster -Force
}
# Power down VMs on your Hyper-V host
Get-VM | Stop-VM -Force
```

3. Once all the VMs are switched off, you can then shut down your Hyper-V host.  If you're running this environment on physical gear on-prem, you're all done, but if you deployed in Azure, visit https://portal.azure.com/, and login with your Azure credentials.  Once logged in, using the search box on the dashboard, enter "azshci" and once the results are returned, click on your AzSHCIHost virtual machine.

![Virtual machine located in Azure](/media/azure_vm_search.png "Virtual machine located in Azure")

4. Once on the overview blade for your VM, along the **top navigation**, click **Stop**, and then click **OK**.  Your VM will then be deallocated and **compute charges** will cease.

Congratulations!
-----------
You've reached the end of the evaluation guide.  In this guide you have:

* Deployed/Configured a Hyper-V host, either on-prem or in Azure, to run your nested sandbox environment
* Deployed a management infrastructure including a Windows Server 2019 Active Directory and Windows 10 management server
* Installed and configured the Windows Admin Center
* Created, deployed and configured a number of Azure Stack HCI nodes, in nested virtual machines
* Created an Azure Stack HCI cluster, integrated with a cloud witness in Azure, and registered with Azure for billing
* Used the Windows Admin Center to create and modify volumes, then deploy and migrate a virtual machine.

Great work!

Next steps
-----------
This part of the guide covers only a handful of key topics and capabilities that Azure Stack HCI can provide.  We'll be adding more shortly, but in the meantime, we'd strongly advise you to check out some of the key areas below:

* [Explore Windows Admin Center](https://docs.microsoft.com/en-us/azure-stack/hci/get-started "Explore Windows Admin Center")
* [Manage virtual machines](https://docs.microsoft.com/en-us/azure-stack/hci/manage/vm "Manage virtual machines")
* [Add additional servers for management](https://docs.microsoft.com/en-us/azure-stack/hci/manage/add-cluster "Add additional servers for management")
* [Manage clusters](https://docs.microsoft.com/en-us/azure-stack/hci/manage/cluster "Manage clusters")
* [Create and manage storage volumes](https://docs.microsoft.com/en-us/azure-stack/hci/manage/create-volumes "Create and manage storage volumes")
* [Integrate Windows Admin Center with Azure](https://docs.microsoft.com/en-us/azure-stack/hci/manage/register-windows-admin-center "Integrate Windows Admin Center with Azure")
* [Monitor with with Azure Monitor](https://docs.microsoft.com/en-us/azure-stack/hci/manage/azure-monitor "Monitor with with Azure Monitor")
* [Integrate with Azure Site Recovery](https://docs.microsoft.com/en-us/azure-stack/hci/manage/azure-site-recovery "Integrate with Azure Site Recovery")