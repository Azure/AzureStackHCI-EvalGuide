Configure your Azure Stack HCI 21H2 Cluster
==============
Overview
-----------

So far, you've deployed your Azure VM, that has all the relevant roles and features enabled, including Hyper-V, AD Domain Services, DNS and DHCP. The VM deployment also orchestrated the download of all required binaries, as well as creating and deploying 2 Azure Stack HCI 21H2 nodes, which you'll be configuring in this step.

Contents
-----------
- [Overview](#overview)
- [Contents](#contents)
- [Architecture](#architecture)
- [Before you begin](#before-you-begin)
- [Allow popups in Edge browser](#allow-popups-in-edge-browser)
- [Creating a (local) cluster](#creating-a-local-cluster)
- [Configuring the cluster witness](#configuring-the-cluster-witness)
- [Next Steps](#next-steps)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)

Architecture
-----------

As shown on the architecture graphic below, in this step, you'll take the nodes that were previously deployed, and be **clustering them into an Azure Stack HCI 21H2 cluster**. You'll be focused on **creating a cluster in a single site**.

![Architecture diagram for Azure Stack HCI 21H2 nested](/deployment/media/nested_virt_arch_ga_oct21.png "Architecture diagram for Azure Stack HCI 21H2 nested")

Before you begin
-----------
With Windows Admin Center, you now have the ability to construct Azure Stack HCI 21H2 clusters from the vanilla nodes.  There are no additional extensions to install, the workflow is built in and ready to go, however, it's worth checking to ensure that your Cluster Creation extension is fully up to date and making a few changes to the Edge browser.

### Set Microsoft Edge as default browser ###

To streamline things later, we'll set Microsoft Edge as the default browser over Internet Explorer.

1. Inside your **AzSHCIHost001 VM**, click on Start, then type "**default browser**" (without quotes) and then under **Best match**, select **Choose a default web browser**

![Set the default browser](/deployment/media/default_browser.png "Set the default browser")

2. In the **Default apps** settings view, under **Web browser**, click on **Internet Explorer**
3. In the **Choose an app** popup, select **Microsoft Edge** then **close the Settings window**

Allow popups in Edge browser
-----------
To give the optimal experience with Windows Admin Center, you should enable **Microsoft Edge** to allow popups for Windows Admin Center.

1. Still inside your **AzSHCIHost001 VM**, double-click the **Microsoft Edge icon** on your desktop
2. Navigate to **edge://settings/content/popups**
3. Click the slider button to **disable** pop-up blocking
4. Close the **settings tab**.

### Configure Windows Admin Center ###

Your Azure VM deployment automatically installed the latest version of Windows Admin Center, however there are some additional configuration steps that must be performed before you can use it to deploy Azure Stack HCI.

1. **Double-click the Windows Admin Center** shortcut on the desktop.
2. Once Windows Admin Center is open, you may receive notifications in the top-right corner, indicating that some extensions are updating automatically. **Let these finish updating before proceeding**. Windows Admin Center may refresh automatically during this process.
3. Once complete, navigate to **Settings**, then **Extensions**
4. Click on **Installed extensions** and you should see **Cluster Creation** listed as installed

![Installed extensions in Windows Admin Center](/deployment/media/installed_extensions_cluster.png "Installed extensions in Windows Admin Center")

____________

**NOTE** - Ensure that your Cluster Creation extension is the **latest available version**. If the **Status** is **Installed**, you have the latest version. If the **Status** shows **Update available (1.#.#)**, ensure you apply this update and refresh before proceeding.

_____________

You're now ready to begin deployment of your Azure Stack HCI cluster with Windows Admin Center. Here are the major steps in the Create Cluster wizard in Windows Admin Center:

* **Get Started** - ensures that each server meets the prerequisites for and features needed for cluster join
* **Networking** - assigns and configures network adapters and creates the virtual switches for each server
* **Clustering** - validates the cluster is set up correctly. For stretched clusters, also sets up up the two sites
* **Storage** - Configures Storage Spaces Direct

### Decide on cluster type ###
Not only does Azure Stack HCI 21H2 support a cluster in a single site (or a **local cluster** as we'll refer to it going forward) consisting of between 2 and 16 nodes, but, also supports a **Stretch Cluster**, where a single cluster can have nodes distrubuted across two sites.

* If you have 2 Azure Stack HCI 21H2 nodes, you will be able to create a **local cluster**
* If you have 4 Azure Stack HCI 21H2 nodes, you will have a choice of creating either a **local cluster** or a **stretch cluster**

In this workshop, we'll be focusing on deploying a **local cluster** but if you're interested in deploying a stretch cluster, you can [check out the official docs](https://docs.microsoft.com/en-us/azure-stack/hci/concepts/stretched-clusters "Stretched clusters overview on Microsoft Docs")

Creating a (local) cluster
-----------
This section will walk through the key steps for you to set up the Azure Stack HCI 21H2 cluster with the Windows Admin Center

1. Connect to your **AzSHCIHost001**, and open **Windows Admin Center** using the shortcut on your desktop.
2. Once logged into Windows Admin Center, under **All connections**, click **Add**
3. On the **Add or create resources popup**, under **Server clusters**, click **Create new** to open the **Cluster Creation wizard**

### Get started ###

![Choose cluster type in the Create Cluster wizard](/deployment/media/wac_cluster_type_ga.png "Choose cluster type in the Create Cluster wizard")

1. Ensure you select **Azure Stack HCI**, select **All servers in one site** and cick **Create**
2. On the **Check the prerequisites** page, review the requirements and click **Next**
3. On the **Add Servers** page, supply a **username**, which should be **azshci\azureuser** and **password-you-used-at-VM-deployment-time** and then one by one, enter the node names of your Azure Stack HCI 21H2 nodes (AZSHCINODE01 and AZSHCINODE02), clicking **Add** after each one has been located.  Each node will be validated, and given a **Ready** status when fully validated.  This may take a few moments - once you've added all nodes, click **Next**

![Add servers in the Create Cluster wizard](/deployment/media/add_nodes_ga.png "Add servers in the Create Cluster wizard")

4. On the **Join a domain** page, details should already be in place, as these nodes have already been joined to the domain to save time. If this wasn't the case, WAC would be able to configure this for you. Click **Next**

![Joined the domain in the Create Cluster wizard](/deployment/media/wac_domain_joined_ga.png "Joined the domain in the Create Cluster wizard")

1. On the **Install features** page, Windows Admin Center will query the nodes for currently installed features, and will typically request you install required features. In this case, all features have been previously installed to save time, as this would take a few moments. Once reviewed, click **Next**

![Installing required features in the Create Cluster wizard](/deployment/media/wac_installed_features_ga.png "Installing required features in the Create Cluster wizard")

6. On the **Install updates** page, Windows Admin Center will query the nodes for available updates, and will request you install any that are required. For the purpose of this guide and to save time, we'll ignore this and click **Next**
7. On the **Install hardware updates** page, in a nested environment this doesn't apply, so click **Next**
8. On the **Restart servers** page, if required, click **Restart servers**, otherwise, click **Next: Networking**

![Restart nodes in the Create Cluster wizard](/deployment/media/wac_restart_ga.png "Restart nodes in the Create Cluster wizard")

### Networking ###
With the servers configured with the appropriate features, updated and rebooted, you're ready to configure your network.  You have a number of different choices here, so we'll try to explain why we're making each selection, so you can better apply it to your environment further down the road.

Firstly, Windows Admin Center will verify your networking setup - it'll tell you how many NICs are in each node, along with relevant hardware information, MAC address and status information.  Review for accuracy, and then click **Next**

![Verify network in the Create Cluster wizard](/deployment/media/wac_verify_network_ga.png "Verify network in the Create Cluster wizard")

The first key step with setting up the networking with Windows Admin Center, is to choose a management NIC that will be dedicated for management use.  You can choose either a single NIC, or two NICs for redundancy. This step specifically designates 1 or 2 adapters that will be used by the Windows Admin Center to orchestrate the cluster creation flow. It's mandatory to select at least one of the adapters for management, and in a physical deployment, the 1GbE NICs are usually good candidates for this.

As it stands, this is the way that the Windows Admin Center approaches the network configuration, however, if you were not using the Windows Admin Center, through PowerShell, there are a number of different ways to configure the network to meet your needs. We will work through the Windows Admin Center approach in this guide.

#### Network Setup Overview ####
Each of your Azure Stack HCI 21H2 nodes should have 4 NICs.  For this simple evaluation, you'll dedicate the NICs in the following way:

* 1 NIC will be dedicated to management. This NIC will reside on the 192.168.0.0/16 subnet. No virtual switch will be attached to this NIC.
* 1 NIC will be dedicated to VM traffic. A virtual switch will be attached to this NIC and the Azure Stack HCI 21H2 host will no longer use this NIC for it's own traffic.
* 2 NICs will be dedicated to storage traffic. They will reside on 2 separate subnets, 10.10.11.0/24 and 10.10.12.0/24. No virtual switches will be attached to these NICs.

Again, this is just one **example** network configuration for the simple purpose of evaluation.

1. Back in the Windows Admin Center, on the **Select the adapters to use for management** page, ensure you select the **One physical network adapters for management** box

![Select management adapter in the Create Cluster wizard](/deployment/media/wac_management_nic_ga.png "Select management adapter in the Create Cluster wizard")

2. Then, for each node, **select the highlighted NIC** that will be dedicated for management.  The reason only one NIC is highlighted, is because this is the only NICs that has an IP address on the same network as the WAC instance. Once you've finished your selections, scroll to the bottom, then click **Apply and test**. This will take a few moments.

![Select management adapters in the Create Cluster wizard](/deployment/media/wac_singlemgmt_ga.png "Select management adapters in the Create Cluster wizard")

3. Windows Admin Center will then apply the configuration to your NICs. When complete and successful, click **Next**
4. On the **Virtual Switch** page, you have a number of options

![Select vSwitch in the Create Cluster wizard](/deployment/media/wac_vswitches_ga.png "Select vSwitch in the Create Cluster wizard")

* **Create one virtual switch for compute and storage together** - in this configuration, your Azure Stack HCI 21H2 nodes will create a vSwitch, comprised of multiple NICs, and the bandwidth available across these NICs will be shared by the Azure Stack HCI 21H2 nodes themselves, for storage traffic, and in addition, any VMs you deploy on top of the nodes, will also share this bandwidth.
* **Create one virtual switch for compute only** - in this configuration, you would leave some NICs dedicated to storage traffic, and have a set of NICs attached to a vSwitch, to which your VMs traffic would be dedicated.
* **Create two virtual switches** - in this configuration, you can create separate vSwitches, each attached to different sets of underlying NICs.  This may be useful if you wish to dedicate a set of underlying NICs to VM traffic, and another set to storage traffic, but wish to have vNICs used for storage communication instead of the underlying NICs.
* You also have a check-box for **Skip virtual switch creation** - if you want to define things later, that's fine too

1. Select the **Create one virtual switch for compute only**, and select the NIC on each node with the **10.10.13.x IP address**, then click **Next**

![Create single vSwitch for Compute in the Create Cluster wizard](/deployment/media/wac_compute_vswitch_ga.png "Create single vSwitch for Compute in the Create Cluster wizard")

6. On the **RDMA** page, you're now able to configure the appropriate RDMA settings for your host networks.  If you do choose to tick the box, in a nested environment, you'll be presented with an error, so click **Next**

![Error message when configuring RDMA in a nested environment](/deployment/media/wac_enable_rdma.png "Error message when configuring RDMA in a nested environment")

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

![Define networks in the Create Cluster wizard](/deployment/media/wac_define_network_ga.png "Define networks in the Create Cluster wizard")

**NOTE**, You *may* be prompted with a **Credential Security Service Provider (CredSSP)** box - read the information, then click **Yes**

![Validate cluster in the Create Cluster wizard](/deployment/media/wac_credssp_ga.png "Validate cluster in the Create Cluster wizard")

8. Once the networks have been verified, you can optionally review the networking test report, and once complete, click **Next**

9. Once changes have been successfully applied, click **Next: Clustering**

### Clustering ###
With the network configured for the workshop environment, it's time to construct the local cluster.

1. At the start of the **Cluster** wizard, on the **Validate the cluster** page, click **Validate**.

2. Cluster validation will then start, and will take a few moments to complete - once completed, you should see a successful message.

**NOTE** - Cluster validation is intended to catch hardware or configuration problems before a cluster goes into production. Cluster validation helps to ensure that the Azure Stack HCI 21H2 solution that you're about to deploy is truly dependable. You can also use cluster validation on configured failover clusters as a diagnostic tool. If you're interested in learning more about Cluster Validation, [check out the official docs](https://docs.microsoft.com/en-us/azure-stack/hci/deploy/validate "Cluster validation official documentation").

![Validation complete in the Create Cluster wizard](/deployment/media/wac_validated_ga.png "Validation complete in the Create Cluster wizard")

1. Optionally, if you want to review the validation report, click on **Download report** and open the file in your browser.
2. Back in the **Validate the cluster** screen, click **Next**
3. On the **Create the cluster** page, enter your **cluster name** as **AZSHCICLUS** (IMPORTANT - make sure you use AZSHCICLUS as the name of the cluster as we pre-created the AD object in Active Directory to reflect this name)
4. Under **IP address**, click **Specify one or more static addresses**, and enter **192.168.0.4**
5. Expand **Advanced** and review the settings, then click **Create cluster**

![Finalize cluster creation in the Create Cluster wizard](/deployment/media/wac_create_clus_static_ga.png "Finalize cluster creation in the Create Cluster wizard")

6. With all settings confirmed, click **Create cluster**. This will take a few moments.  Once complete, click **Next: Storage**

![Cluster creation successful in the Create Cluster wizard](/deployment/media/wac_cluster_success_ga.png "Cluster creation successful in the Create Cluster wizard")


With the cluster successfully created, you're now good to proceed on to configuring your storage.  Whilst less important in a fresh nested environment, it's always good to start from a clean slate, so first, you'll clean the drives before configuring storage.

1. On the storage landing page within the Create Cluster wizard, click **Erase Drives**, and when prompted, with **You're about to erase all existing data**, click **Erase drives**.  Once complete, you should have a successful confirmation message, then click **Next**

![Cleaning drives in the Create Cluster wizard](/deployment/media/wac_clean_drives_ga.png "Cleaning drives in the Create Cluster wizard")

2. On the **Check drives** page, validate that all your drives have been detected, and show correctly.  As these are virtual disks in a nested environment, they won't display as SSD or HDD etc. You should have **4 data drives** per node.  Once verified, click **Next**

![Verified drives in the Create Cluster wizard](/deployment/media/wac_check_drives_ga.png "Verified drives in the Create Cluster wizard")

3. Storage Spaces Direct validation tests will then automatically run, which will take a few moments.

![Verifying Storage Spaces Direct in the Create Cluster wizard](/deployment/media/wac_validate_storage_ga.png "Verifying Storage Spaces Direct in the Create Cluster wizard")

4. Once completed, you should see a successful confirmation.  You can scroll through the brief list of tests, or alternatively, click to **Download report** to view more detailed information, then click **Next**

![Storage verified in the Create Cluster wizard](/deployment/media/wac_storage_validated_ga.png "Storage verified in the Create Cluster wizard")

5. The final step with storage, is to **Enable Storage Spaces Direct**, so click **Enable**.  This will take a few moments.

![Storage Spaces Direct enabled in the Create Cluster wizard](/deployment/media/wac_s2d_enabled_ga.png "Storage Spaces Direct enabled in the Create Cluster wizard")

6. With Storage Spaces Direct enabled, click **Next:SDN**

### SDN ###

With Storage configured, for the purpose of this lab, we will skip the SDN configuration.

1. On the **Define the Network Controller cluster** page, click **Skip**
2. On the **confirmation page**, click on **Go to connections list**

Configuring the cluster witness
-----------
By deploying an Azure Stack HCI 21H2 cluster, you're providing high availability for workloads. These resources are considered highly available if the nodes that host resources are up; however, the cluster generally requires more than half the nodes to be running, which is known as having quorum.

Quorum is designed to prevent split-brain scenarios which can happen when there is a partition in the network and subsets of nodes cannot communicate with each other. This can cause both subsets of nodes to try to own the workload and write to the same disk which can lead to numerous problems. However, this is prevented with Failover Clustering's concept of quorum which forces only one of these groups of nodes to continue running, so only one of these groups will stay online.

In this step, we're going to utilize a **Cloud witness** to help provide quorum.  If you want to learn more about quorum, [check out the official documentation.](https://docs.microsoft.com/en-us/azure-stack/hci/concepts/quorum "Official documentation about Cluster quorum")

As part of this guide, we're going to set up cluster quorum, using **Windows Admin Center**.

1. If you're not already, ensure you're logged into your **Windows Admin Center** instance, and click on your **azshciclus** cluster that you created earlier

![Connect to your cluster with Windows Admin Center](/deployment/media/wac_azshciclus_ga.png "Connect to your cluster with Windows Admin Center")

2. You may be prompted for credentials, so log in with your **azshci\azureuser** credentials and tick the **Use these credentials for all connections** box. You should then be connected to your **azshciclus cluster**
3. After a few moments of verification, the **cluster dashboard** will open. 
4. On the **cluster dashboard**, at the very bottom-left of the window, click on **Settings**
5. In the **Settings** window, click on **Witness** and under **Witness type**, use the drop-down to select **Cloud witness**

![Set up cloud witness in Windows Admin Center](/deployment/media/wac_cloud_witness_new_ga.png "Set up cloud witness in Windows Admin Center")

6. Open a new tab in your browser, and navigate to **https://portal.azure.com** and login with your Azure credentials
7. You should already have a subscription from an earlier step, but if not, you should [review those steps and create one, then come back here](/deployment/steps/1_DeployAzureVM.md#get-an-azure-subscription)
8. Once logged into the Azure portal, click on **Create a Resource**, click **Storage**, then **Storage account**
9. For the **Create storage account** blade, ensure the **correct subscription** is selected, then enter the following:

    * Resource Group: **Create new**, then enter **azshcicloudwitness**, and click **OK**
    * Storage account name: **azshcicloudwitness**
    * Region: **Select your preferred region**
    * Performance: **Only standard is supported**
    * Redundancy: **Locally-redundant storage (LRS)** - Failover Clustering uses the blob file as the arbitration point, which requires some consistency guarantees when reading the data. Therefore you must select Locally-redundant storage for Replication type.

![Set up storage account in Azure](/deployment/media/azure_cloud_witness_ga.png "Set up storage account in Azure")

1.  On the **Advanced** page, ensure that **Enable blob public access** is **unchecked**, and **Minimum TLS version** is set to **Version 1.2**
2.  On the **Networking**, **Data protection** and **Tags** pages, accept the defaults and press **Next**
3.  When complete, click **Create** and your deployment will begin.  This should take a few moments.
4.  Once complete, in the **notification**, click on **Go to resource**
5.  On the left-hand navigation, under Settings, click **Access Keys**. When you create a Microsoft Azure Storage Account, it is associated with two Access Keys that are automatically generated - Primary Access key and Secondary Access key. For a first-time creation of Cloud Witness, use the **Primary Access Key**. There is no restriction regarding which key to use for Cloud Witness.
6.  Click on **Show keys** and take a copy of the **Storage account name** and **key1**

![Configure Primary Access key in Azure](/deployment/media/azure_keys_ga.png "Configure Primary Access key in Azure")

16. On the left-hand navigation, under Settings, click **Properties** and make a note of your **blob service endpoint**.

![Blob Service endpoint in Azure](/deployment/media/azure_blob_ga.png "Blob Service endpoint in Azure")

**NOTE** - The required service endpoint is the section of the Blob service URL **after blob.**, i.e. for our configuration, **core.windows.net**

17. With all the information gathered, return to the **Windows Admin Center** and complete the form with your values, then click **Save**

![Providing storage account info in Windows Admin Center](/deployment/media/wac_azure_key_ga.png "Providing storage account info in Windows Admin Center")

18. Within a few moments, your witness settings should be successfully applied and you have now completed configuring the quorum settings for the **azshciclus** cluster.

### Congratulations! ###
You've now successfully deployed and configured your Azure Stack HCI 21H2 cluster!

Next Steps
-----------
In this step, you've successfully created a nested Azure Stack HCI 21H2 cluster using Windows Admin Center. With this complete, you can now [Integrate Azure Stack HCI 21H2 with Azure](/deployment/steps/3_AzSHCIIntegration.md "Integrate Azure Stack HCI 21H2 with Azure")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI, Windows Admin Center, or the Azure Arc integration and experience, let us know! We want to hear from you!

For **Azure Stack HCI**, [Head on over to the Azure Stack HCI 21H2 Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Azure Stack HCI 21H2 Q&A"), where you can share your thoughts and ideas about making the technologies better and raise an issue if you're having trouble with the technology.

Raising issues
-----------
If you notice something is wrong with this guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If you're having an issue with Azure Stack HCI 21H2 **outside** of this guide, [head on over to the Azure Stack HCI 21H2 Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Azure Stack HCI 21H2 Q&A"), where Microsoft experts and valuable members of the community will do their best to help you.