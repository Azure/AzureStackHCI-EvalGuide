Configure your Azure Stack HCI 20H2 Cluster
==============
Overview
-----------

So far, you've deployed your Azure VM, that has all the relevant roles and features enabled, including Hyper-V, AD Domain Services, DNS and DHCP. The VM deployment also orchestrated the download of all required binaries, as well as creating and deploying 2 Azure Stack HCI 20H2 nodes, which you'll be configuring in this step.

Contents
-----------
- [Overview](#overview)
- [Contents](#contents)
- [Architecture](#architecture)
- [Before you begin](#before-you-begin)
- [Creating a (local) cluster](#creating-a-local-cluster)
- [Configuring the cluster witness](#configuring-the-cluster-witness)
- [Create volumes for VMs](#create-volumes-for-vms)
- [Next Steps](#next-steps)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)

Architecture
-----------

As shown on the architecture graphic below, in this step, you'll take the nodes that were previously deployed, and be **clustering them into an Azure Stack HCI 20H2 cluster**. You'll be focused on **creating a cluster in a single site**.

![Architecture diagram for Azure Stack HCI 20H2 nested](/media/nested_virt_nodes_ga.png "Architecture diagram for Azure Stack HCI 20H2 nested")

Before you begin
-----------
With Windows Admin Center, you now have the ability to construct Azure Stack HCI 20H2 clusters from the vanilla nodes.  There are no additional extensions to install, the workflow is built in and ready to go.

Here are the major steps in the Create Cluster wizard in Windows Admin Center:

* **Get Started** - ensures that each server meets the prerequisites for and features needed for cluster join
* **Networking** - assigns and configures network adapters and creates the virtual switches for each server
* **Clustering** - validates the cluster is set up correctly. For stretched clusters, also sets up up the two sites
* **Storage** - Configures Storage Spaces Direct

### Decide on cluster type ###
Not only does Azure Stack HCI 20H2 support a cluster in a single site (or a **local cluster** as we'll refer to it going forward) consisting of between 2 and 16 nodes, but, also supports a **Stretch Cluster**, where a single cluster can have nodes distrubuted across two sites.

* If you have 2 Azure Stack HCI 20H2 nodes, you will be able to create a **local cluster**
* If you have 4 Azure Stack HCI 20H2 nodes, you will have a choice of creating either a **local cluster** or a **stretch cluster**

In this workshop, we'll be focusing on deploying a **local cluster** but if you're interested in deploying a stretch cluster, you can [check out the official docs](https://docs.microsoft.com/en-us/azure-stack/hci/concepts/stretched-clusters "Stretched clusters overview on Microsoft Docs")

Creating a (local) cluster
-----------
This section will walk through the key steps for you to set up the Azure Stack HCI 20H2 cluster with the Windows Admin Center

1. Connect to your **HybridHost001**, and open **Windows Admin Center** using the shortcut on your desktop.
2. Once logged into Windows Admin Center, under **All connections**, click **Add**
3. On the **Add or create resources popup**, under **Server clusters**, click **Create new** to open the **Cluster Creation wizard**

### Get started ###

![Choose cluster type in the Create Cluster wizard](/media/wac_cluster_type_ga.png "Choose cluster type in the Create Cluster wizard")

1. Ensure you select **Azure Stack HCI**, select **All servers in one site** and cick **Create**
2. On the **Check the prerequisites** page, review the requirements and click **Next**
3. On the **Add Servers** page, supply a **username**, which should be **hybrid\azureuser** and **password-you-used-at-VM-deployment-time** and then one by one, enter the node names of your Azure Stack HCI 20H2 nodes (AZSHCINODE01 and AZSHCINODE02), clicking **Add** after each one has been located.  Each node will be validated, and given a **Ready** status when fully validated.  This may take a few moments - once you've added all nodes, click **Next**

![Add servers in the Create Cluster wizard](/media/add_nodes_ga.png "Add servers in the Create Cluster wizard")

4. On the **Join a domain** page, details should already be in place, as these nodes have already been joined to the domain to save time. If this wasn't the case, WAC would be able to configure this for you. Click **Next**

![Joined the domain in the Create Cluster wizard](/media/wac_domain_joined_ga.png "Joined the domain in the Create Cluster wizard")

1. On the **Install features** page, Windows Admin Center will query the nodes for currently installed features, and will typically request you install required features. In this case, all features have been previously installed to save time, as this would take a few moments. Once reviewed, click **Next**

![Installing required features in the Create Cluster wizard](/media/wac_installed_features_ga.png "Installing required features in the Create Cluster wizard")

6. On the **Install updates** page, Windows Admin Center will query the nodes for available updates, and will request you install any that are required. For the purpose of this guide and to save time, we'll ignore this and click **Next**
7. On the **Install hardware updates** page, in a nested environment it's likely you'll have no updates, so click **Next**
8. On the **Restart servers** page, if required, click **Restart servers**

![Restart nodes in the Create Cluster wizard](/media/wac_restart_ga.png "Restart nodes in the Create Cluster wizard")

### Networking ###
With the servers configured with the appropriate features, updated and rebooted, you're ready to configure your network.  You have a number of different choices here, so we'll try to explain why we're making each selection, so you can better apply it to your environment further down the road.

Firstly, Windows Admin Center will verify your networking setup - it'll tell you how many NICs are in each node, along with relevant hardware information, MAC address and status information.  Review for accuracy, and then click **Next**

![Verify network in the Create Cluster wizard](/media/wac_verify_network_ga.png "Verify network in the Create Cluster wizard")

The first key step with setting up the networking with Windows Admin Center, is to choose a management NIC that will be dedicated for management use.  You can choose either a single NIC, or two NICs for redundancy. This step specifically designates 1 or 2 adapters that will be used by the Windows Admin Center to orchestrate the cluster creation flow. It's mandatory to select at least one of the adapters for management, and in a physical deployment, the 1GbE NICs are usually good candidates for this.

As it stands, this is the way that the Windows Admin Center approaches the network configuration, however, if you were not using the Windows Admin Center, through PowerShell, there are a number of different ways to configure the network to meet your needs. We will work through the Windows Admin Center approach in this guide.

#### Network Setup Overview ####
Each of your Azure Stack HCI 20H2 nodes should have 4 NICs.  For this simple evaluation, you'll dedicate the NICs in the following way:

* 1 NIC will be dedicated to management. This NIC will reside on the 192.168.0.0/24 subnet. No virtual switch will be attached to this NIC.
* 1 NIC will be dedicated to VM traffic. A virtual switch will be attached to this NIC and the Azure Stack HCI 20H2 host will no longer use this NIC for it's own traffic.
* 2 NICs will be dedicated to storage traffic. They will reside on 2 separate subnets, 10.10.11.0/24 and 10.10.12.0/24. No virtual switches will be attached to these NICs.

Again, this is just one **example** network configuration for the simple purpose of evaluation.

1. Back in the Windows Admin Center, on the **Select the adapters to use for management** page, ensure you select the **One physical network adapters for management** box

![Select management adapter in the Create Cluster wizard](/media/wac_management_nic_ga.png "Select management adapter in the Create Cluster wizard")

2. Then, for each node, **select the highlighted NIC** that will be dedicated for management.  The reason only one NIC is highlighted, is because this is the only NICs that has an IP address on the same network as the WAC instance. Once you've finished your selections, scroll to the bottom, then click **Apply and test**. This will take a few moments.

![Select management adapters in the Create Cluster wizard](/media/wac_singlemgmt_ga.png "Select management adapters in the Create Cluster wizard")

3. Windows Admin Center will then apply the configuration to your NICs. When complete and successful, click **Next**
4. On the **Virtual Switch** page, you have a number of options

![Select vSwitch in the Create Cluster wizard](/media/wac_vswitches_ga.png "Select vSwitch in the Create Cluster wizard")

* **Create one virtual switch for compute and storage together** - in this configuration, your Azure Stack HCI 20H2 nodes will create a vSwitch, comprised of multiple NICs, and the bandwidth available across these NICs will be shared by the Azure Stack HCI 20H2 nodes themselves, for storage traffic, and in addition, any VMs you deploy on top of the nodes, will also share this bandwidth.
* **Create one virtual switch for compute only** - in this configuration, you would leave some NICs dedicated to storage traffic, and have a set of NICs attached to a vSwitch, to which your VMs traffic would be dedicated.
* **Create two virtual switches** - in this configuration, you can create separate vSwitches, each attached to different sets of underlying NICs.  This may be useful if you wish to dedicate a set of underlying NICs to VM traffic, and another set to storage traffic, but wish to have vNICs used for storage communication instead of the underlying NICs.
* You also have a check-box for **Skip virtual switch creation** - if you want to define things later, that's fine too

1. Select the **Create one virtual switch for compute only**, and select the NIC on each node with the **10.10.13.x IP address**, then click **Next**

![Create single vSwitch for Compute in the Create Cluster wizard](/media/wac_compute_vswitch_ga.png "Create single vSwitch for Compute in the Create Cluster wizard")

6. On the **RDMA** page, you're now able to configure the appropriate RDMA settings for your host networks.  If you do choose to tick the box, in a nested environment, you'll be presented with an error, so click **Next**

![Error message when configuring RDMA in a nested environment](/media/wac_enable_rdma.png "Error message when configuring RDMA in a nested environment")

7. On the **Define networks** page, this is where you can define the specific networks, separate subnets, and optionally apply VLANs.  In this **nested environment**, we now have 3 NICs remaining.  Configure your remaining NICs as follows, by clicking on a field in the table and entering the appropriate information.

**NOTE** - we have a simple flat network in this configuration. One of the NICs have been claimed by the Management NIC, The remaining NICs will be show in the table in WAC, so ensure they align with the information below. WAC won't allow you to proceed unless everything aligns correctly.

| Node | Name | IP Address | Subnet Mask
| :-- | :-- | :-- | :-- |
| AZSHCINODE01 | Storage 1 | 10.10.11.1 | 24
| AZSHCINODE01 | Storage 2 | 10.10.12.1 | 24
| AZSHCINODE01 | VM | 10.10.13.1 | 24
| AZSHCINODE02 | Storage 1 | 10.10.11.2 | 24
| AZSHCINODE02 | Storage 2 | 10.10.12.2 | 24
| AZSHCINODE02 | VM | 10.10.13.2 | 24

When you click **Apply and test**, Windows Admin Center validates network connectivity between the adapters in the same VLAN and subnet, which may take a few moments.  Once complete, your configuration should look similar to this:

![Define networks in the Create Cluster wizard](/media/wac_define_network_ga.png "Define networks in the Create Cluster wizard")

**NOTE**, You *may* be prompted with a **Credential Security Service Provider (CredSSP)** box - read the information, then click **Yes**

![Validate cluster in the Create Cluster wizard](/media/wac_credssp_ga.png "Validate cluster in the Create Cluster wizard")

8. Once the networks have been verified, you can optionally review the networking test report, and once complete, click **Next**

9. Once changes have been successfully applied, click **Next: Clustering**

### Clustering ###
With the network configured for the workshop environment, it's time to construct the local cluster.

1. At the start of the **Cluster** wizard, on the **Validate the cluster** page, click **Validate**.

2. Cluster validation will then start, and will take a few moments to complete - once completed, you should see a successful message.

**NOTE** - Cluster validation is intended to catch hardware or configuration problems before a cluster goes into production. Cluster validation helps to ensure that the Azure Stack HCI 20H2 solution that you're about to deploy is truly dependable. You can also use cluster validation on configured failover clusters as a diagnostic tool. If you're interested in learning more about Cluster Validation, [check out the official docs](https://docs.microsoft.com/en-us/azure-stack/hci/deploy/validate "Cluster validation official documentation").

![Validation complete in the Create Cluster wizard](/media/wac_validated_ga.png "Validation complete in the Create Cluster wizard")

1. Optionally, if you want to review the validation report, click on **Download report** and open the file in your browser.
2. Back in the **Validate the cluster** screen, click **Next**
3. On the **Create the cluster** page, enter your **cluster name** as **AZSHCICLUS** (IMPORTANT - make sure you use AZSHCICLUS as the name of the cluster as we pre-created the AD object in Active Directory to reflect this name)
4. Under **IP address**, click **Assign dynamically using DHCP**
5. Expand **Advanced** and review the settings, then click **Create cluster**

![Finalize cluster creation in the Create Cluster wizard](/media/wac_create_clus_dhcp_ga.png "Finalize cluster creation in the Create Cluster wizard")

6. With all settings confirmed, click **Create cluster**. This will take a few moments.  Once complete, click **Next: Storage**

![Cluster creation successful in the Create Cluster wizard](/media/wac_cluster_success_ga.png "Cluster creation successful in the Create Cluster wizard")


With the cluster successfully created, you're now good to proceed on to configuring your storage.  Whilst less important in a fresh nested environment, it's always good to start from a clean slate, so first, you'll clean the drives before configuring storage.

1. On the storage landing page within the Create Cluster wizard, click **Erase Drives**, and when prompted, with **You're about to erase all existing data**, click **Erase drives**.  Once complete, you should have a successful confirmation message, then click **Next**

![Cleaning drives in the Create Cluster wizard](/media/wac_clean_drives_ga.png "Cleaning drives in the Create Cluster wizard")

2. On the **Check drives** page, validate that all your drives have been detected, and show correctly.  As these are virtual disks in a nested environment, they won't display as SSD or HDD etc. You should have **4 data drives** per node.  Once verified, click **Next**

![Verified drives in the Create Cluster wizard](/media/wac_check_drives_ga.png "Verified drives in the Create Cluster wizard")

3. Storage Spaces Direct validation tests will then automatically run, which will take a few moments.

![Verifying Storage Spaces Direct in the Create Cluster wizard](/media/wac_validate_storage_ga.png "Verifying Storage Spaces Direct in the Create Cluster wizard")

4. Once completed, you should see a successful confirmation.  You can scroll through the brief list of tests, or alternatively, click to **Download report** to view more detailed information, then click **Next**

![Storage verified in the Create Cluster wizard](/media/wac_storage_validated_ga.png "Storage verified in the Create Cluster wizard")

5. The final step with storage, is to **Enable Storage Spaces Direct**, so click **Enable**.  This will take a few moments.

![Storage Spaces Direct enabled in the Create Cluster wizard](/media/wac_s2d_enabled_ga.png "Storage Spaces Direct enabled in the Create Cluster wizard")

6. With Storage Spaces Direct enabled, click **Next:SDN**

### SDN ###

With Storage configured, for the purpose of this lab, we will skip the SDN configuration.

1. On the **Define the Network Controller cluster** page, click **Skip**
2. On the **confirmation page**, click on **Go to connections list**

Configuring the cluster witness
-----------
By deploying an Azure Stack HCI 20H2 cluster, you're providing high availability for workloads. These resources are considered highly available if the nodes that host resources are up; however, the cluster generally requires more than half the nodes to be running, which is known as having quorum.

Quorum is designed to prevent split-brain scenarios which can happen when there is a partition in the network and subsets of nodes cannot communicate with each other. This can cause both subsets of nodes to try to own the workload and write to the same disk which can lead to numerous problems. However, this is prevented with Failover Clustering's concept of quorum which forces only one of these groups of nodes to continue running, so only one of these groups will stay online.

Typically, the recommendation is to utilize a **Cloud Witness**, where an Azure Storage Account is used to help provide quorum, but in the interest of time, we;re going to use a **File Share Witness**.  If you want to learn more about quorum, [check out the official documentation.](https://docs.microsoft.com/en-us/azure-stack/hci/concepts/quorum "Official documentation about Cluster quorum")

As part of this workshop, we're going to set up cluster quorum, using **Windows Admin Center**.

1. Firstly, you're going to create a **shared folder** on **HybridHost001** - open **File Explorer** and navigate to **V:\Witness**
2. **Right-click** on the Witness folder, select **Give access to**, then select **Specific people**
3. In the **Network access** window, use the drop-down to select **Everyone** and set their permissions to **Read/Write** - this setting is for speed and simplicity. In a production environment, your folder would be shared specifically with the Cluster Object from Active Directory.

![Granting folder permissions for the file share witness](/media/grant_folder_permissions.png "Granting folder permissions for the file share witness")

4. Once done, click Share, then click **Done** to close the window.
5. Open your **Windows Admin Center** instance, and click on your **azshciclus** cluster that you created earlier

![Connect to your cluster with Windows Admin Center](/media/wac_azshciclus_ga.png "Connect to your cluster with Windows Admin Center")

6. You may be prompted for credentials, so log in with your **hybrid\azureuser** credentials and tick the **Use these credentials for all connections** box. You should then be connected to your **azshciclus cluster**
7. After a few moments of verification, the **cluster dashboard** will open. 
8. On the **cluster dashboard**, at the very bottom-left of the window, click on **Settings**
9. In the **Settings** window, click on **Witness** and under **Witness type**, use the drop-down to select **File Share Witness**
10. Enter **\\\hybridhost001\witness** for the **File share path** and click **Save**

![Set up file share witness in Windows Admin Center](/media/wac_fs_witness_new_ga.png "Set up file share witness in Windows Admin Center")

11. Within a few moments, your witness settings should be successfully applied and you have now completed configuring the quorum settings for the **azshciclus** cluster.

### Congratulations! ###
You've now successfully deployed and configured your Azure Stack HCI 20H2 cluster!

Next Steps
-----------
In this step, you've successfully created a nested Azure Stack HCI 20H2 cluster using Windows Admin Center. With this complete, you can now [Integrate Azure Stack HCI 20H2 with Azure](/steps/3_AzSHCIIntegration.md "Integrate Azure Stack HCI 20H2 with Azure")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI, AKS on Azure Stack HCI, Windows Admin Center, or the Azure Arc integration and experience, let us know! We want to hear from you!

For **Azure Stack HCI**, [Head on over to the Azure Stack HCI 20H2 Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Azure Stack HCI 20H2 Q&A"), where you can share your thoughts and ideas about making the technologies better and raise an issue if you're having trouble with the technology.

For **AKS on Azure Stack HCI**, [Head on over to our AKS on Azure Stack HCI 20H2 GitHub page](https://github.com/Azure/aks-hci/issues "AKS on Azure Stack HCI GitHub"), where you can share your thoughts and ideas about making the technologies better. If however, you have an issue that you'd like some help with, read on... 

Raising issues
-----------
If you notice something is wrong with this guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If you're having an issue with Azure Stack HCI 20H2 **outside** of this guide, [head on over to the Azure Stack HCI 20H2 Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Azure Stack HCI 20H2 Q&A"), where Microsoft experts and valuable members of the community will do their best to help you.

If you're having a problem with AKS on Azure Stack HCI **outside** of this guide, make sure you post to [our GitHub Issues page](https://github.com/Azure/aks-hci/issues "GitHub Issues"), where Microsoft experts and valuable members of the community will do their best to help you.