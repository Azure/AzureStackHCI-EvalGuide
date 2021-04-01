Create nested Azure Stack HCI 20H2 cluster with Windows Admin Center
==============
Overview
-----------

So far, you've deployed your Azure Stack HCI 20H2 nodes in the nested virtualization sandbox, along with an Active Directory infrastructure with DNS.  Finally, you've deployed the Windows Admin Center, which we'll be using to configure the Azure Stack HCI 20H2 cluster.

Contents
-----------
- [Overview](#overview)
- [Contents](#contents)
- [Architecture](#architecture)
- [Before you begin](#before-you-begin)
- [Creating a (local) cluster](#creating-a-local-cluster)
- [Configuring the cluster witness](#configuring-the-cluster-witness)
- [Connect and Register Azure Stack HCI 20H2 to Azure](#connect-and-register-azure-stack-hci-20h2-to-azure)
- [Next Steps](#next-steps)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)
- [Troubleshooting cluster validation issues](#troubleshooting-cluster-validation-issues)

Architecture
-----------

As shown on the architecture graphic below, in this step, you'll take the nodes that you previously deployed, and be **clustering them into an Azure Stack HCI 20H2 cluster**. You'll be focused on **creating a cluster in a single site**, but in later articles, we'll also cover creating a stretch cluster.

![Architecture diagram for Azure Stack HCI 20H2 nested](/media/nested_virt_nodes_ga.png "Architecture diagram for Azure Stack HCI 20H2 nested")

Before you begin
-----------
With Windows Admin Center, you now have the ability to construct Azure Stack HCI 20H2 clusters from the vanilla nodes.  There are no additional extensions to install, the workflow is built in and ready to go.

Before you start creating the cluster, it's important that we briefly review the steps that we've performed, and map them to the requirements:

1. In the case of physical multi-node deployments, all physical nodes are running on suitable hardware
2. All nodes are running the Azure Stack HCI 20H2 OS
3. Windows Admin Center is installed and operational, on the same AD domain into which you'll deploy the cluster
4. You have an account that's a local admin on each server

As it stands, you should have met those requirements thus far, and should be in good shape to proceed on with cluster creation.

Here are the major steps in the Create Cluster wizard in Windows Admin Center:

* **Get Started** - ensures that each server meets the prerequisites for and features needed for cluster join
* **Networking** - assigns and configures network adapters and creates the virtual switches for each server
* **Clustering** - validates the cluster is set up correctly. For stretched clusters, also sets up up the two sites
* **Storage** - Configures Storage Spaces Direct

### Decide on cluster type ###
Not only does Azure Stack HCI 20H2 support a cluster in a single site (or a **local cluster** as we'll refer to it going forward) consisting of between 2 and 16 nodes, but, also supports a **Stretch Cluster**, where a single cluster can have nodes distrubuted across two sites.

* If you have 2 Azure Stack HCI 20H2 nodes, you will be able to create a **local cluster**
* If you have 4 Azure Stack HCI 20H2 nodes, you will have a choice of creating either a **local cluster** or a **stretch cluster**

In this first release of the guide, we'll be focusing on deploying a **local cluster** but if you're interested in deploying a stretch cluster, you can [check out the official docs](https://docs.microsoft.com/en-us/azure-stack/hci/concepts/stretched-clusters "Stretched clusters overview on Microsoft Docs")

Creating a (local) cluster
-----------
If you have just 2 nodes, or if your preference is for a cluster running in a single site, this section will walk through the key steps for you to set up the Azure Stack HCI 20H2 cluster with the Windows Admin Center

1. Connect to **MGMT01**, and open your **Windows Admin Center** instance.
2. Once logged into Windows Admin Center, under **All connections**, click **Add**
3. On the **Add or create resources popup**, under **Server clusters**, click **Create new** to open the **Cluster Creation wizard**

### Get started ###

![Choose cluster type in the Create Cluster wizard](/media/wac_cluster_type_ga.png "Choose cluster type in the Create Cluster wizard")

1. Ensure you select **Azure Stack HCI**, select **All servers in one site** and cick **Create**
2. On the **Check the prerequisites** page, review the requirements and click **Next**
3. On the **Add Servers** page, supply a **username**, which should be **azshci\labadmin** and **your-domain-admin-password** and then one by one, enter the node names (or IP addresses if names don't resolve) of your Azure Stack HCI 20H2 nodes, clicking **Add** after each one has been located.  Each node will be validated, and given a **Ready** status when fully validated.  This may take a few moments - once you've added all nodes, click **Next**

![Add servers in the Create Cluster wizard](/media/add_nodes_ga.png "Add servers in the Create Cluster wizard")

4. On the **Join a domain** page, details should already be in place, as we joined the domain previously, so click **Next**

![Joined the domain in the Create Cluster wizard](/media/wac_domain_joined_ga.png "Joined the domain in the Create Cluster wizard")

5. On the **Install features** page, Windows Admin Center will query the nodes for currently installed features, and will request you install required features.  Click **Install features**.  This will take a few moments - once complete, click **Next**

![Installing required features in the Create Cluster wizard](/media/wac_installed_features_ga.png "Installing required features in the Create Cluster wizard")

6. On the **Install updates** page, Windows Admin Center will query the nodes for available updates, and will request you install any that are required.  Optionally, click **Install updates**.  This will take a few moments - once complete, click **Next**
7. On the **Install hardware updates** page, in a nested environment it's likely you'll have no updates, so click **Next**
8. On the **Restart servers** page, if required, click **Restart servers**

![Restart nodes in the Create Cluster wizard](/media/wac_restart_ga.png "Restart nodes in the Create Cluster wizard")

### Networking ###
With the servers domain joined, configured with the appropriate features, updated and rebooted, you're ready to configure your network.  You have a number of different choices here, so we'll try to explain why we're making each selection, so you can better apply it to your environment further down the road.

Firstly, Windows Admin Center will verify your networking setup - it'll tell you how many NICs are in each node, along with relevant hardware information, MAC address and status information.  Review for accuracy, and then click **Next**

![Verify network in the Create Cluster wizard](/media/wac_verify_network_ga.png "Verify network in the Create Cluster wizard")

The first key step with setting up the networking with Windows Admin Center, is to choose a management NIC that will be dedicated for management use.  You can choose either a single NIC, or two NICs for redundancy.  This step specifically designates 1 or 2 adapters that will be used by the Windows Admin Center to orchestrate the cluster creation flow.  It's mandatory to select at least one of the adapters for management, and in a physical deployment, the 1GbE NICs are usually good candidates for this.

As it stands, this is the way that the Windows Admin Center approaches the network configuration, however, if you were not using the Windows Admin Center, through PowerShell, there are a number of different ways to configure the network to meet your needs.  We will work through the Windows Admin Center approach in this guide.

#### Network Setup Overview ####
Each of your Azure Stack HCI 20H2 nodes should have 4 NICs.  For this simple evaluation, you'll dedicate the NICs in the following way:

* 1 NIC will be dedicated to management.  It will reside on the 192.168.0.0/24 subnet. No virtual switch will be attached to this NIC.
* 1 NIC will be dedicated to VM traffic.  A virtual switch will be attached to this NIC and the Azure Stack HCI 20H2 host will no longer use this NIC for it's own traffic.
* 2 NICs will be dedicated to storage traffic.  They will reside on 2 separate subnets, 10.10.10.0/24 and 10.10.11.0/24. No virtual switches will be attached to these NICs.

Again, this is just one **example** network configuration for the simple purpose of evaluation.

1. Back in the Windows Admin Center, on the **Select the adapters to use for management** page, ensure you select the **One physical network adapter for management** box

![Select management adapter in the Create Cluster wizard](/media/wac_management_nic_ga.png "Select management adapter in the Create Cluster wizard")

2. Then, for each node, **select the highlighted NIC** that will be dedicated for management.  The reason only one NIC is highlighted, is because this is the only one that has an IP address assigned from a previous step. Once you've finished your selections, scroll to the bottom, then click **Apply and test**

![Select management adapters in the Create Cluster wizard](/media/wac_singlemgmt_ga.png "Select management adapters in the Create Cluster wizard")

3. Windows Admin Center will then apply the configuration to your NIC. When complete and successful, click **Next**
4. On the **Virtual Switch** page, you have a number of options

![Select vSwitch in the Create Cluster wizard](/media/wac_vswitches_ga.png "Select vSwitch in the Create Cluster wizard")

* **Create one virtual switch for compute and storage together** - in this configuration, your Azure Stack HCI 20H2 nodes will create a vSwitch, comprised of multiple NICs, and the bandwidth available across these NICs will be shared by the Azure Stack HCI 20H2 nodes themselves, for storage traffic, and in addition, any VMs you deploy on top of the nodes, will also share this bandwidth.
* **Create one virtual switch for compute only** - in this configuration, you would leave some NICs dedicated to storage traffic, and have a set of NICs attached to a vSwitch, to which your VMs traffic would be dedicated.
* **Create two virtual switches** - in this configuration, you can create separate vSwitches, each attached to different sets of underlying NICs.  This may be useful if you wish to dedicate a set of underlying NICs to VM traffic, and another set to storage traffic, but wish to have vNICs used for storage communication instead of the underlying NICs.
* You also have a check-box for **Skip virtual switch creation** - if you want to define things later, that's fine too

5. Select the **Create one virtual switch for compute only**, and select the **Ethernet 2** NICs on each node, then click **Next**

![Create single vSwitch for Compute in the Create Cluster wizard](/media/wac_compute_vswitch_ga.png "Create single vSwitch for Compute in the Create Cluster wizard")

6. On the **RDMA** page, you're now able to configure the appropriate RDMA settings for your host networks.  If you do choose to tick the box, in a nested environment, you'll be presented with an error, so click **Next**

![Error message when configuring RDMA in a nested environment](/media/wac_enable_rdma.png "Error message when configuring RDMA in a nested environment")

7. On the **Define networks** page, this is where you can define the specific networks, separate subnets, and optionally apply VLANs.  In this **nested environment**, we now have 3 NICs remaining.  Configure your remaining NICs as follows, by clicking on a field in the table and entering the appropriate information.

**NOTE** - we have a simple flat network in this configuration, however assuming Ethernet 1 was configured as your management NIC, and Ethernet 2 as your compute vSwitch, that leaves Ethernet 3 and 4 which can be renamed to Storage 1 and 2.

| Node | Name | IP Address | Subnet Mask
| :-- | :-- | :-- | :-- |
| AZSHCINODE01 | Ethernet 2 | Leave as APIPA | 16
| AZSHCINODE01 | Storage 1 | 10.10.10.1 | 24
| AZSHCINODE01 | Storage 2 | 10.10.11.1 | 24
| AZSHCINODE02 | Ethernet 2 | Leave as APIPA | 16
| AZSHCINODE02 | Storage 1 | 10.10.10.2 | 24
| AZSHCINODE02 | Storage 2 | 10.10.11.2 | 24

When you click **Apply and test**, Windows Admin Center validates network connectivity between the adapters in the same VLAN and subnet, which may take a few moments.  Once complete, your configuration should look similar to this:

![Define networks in the Create Cluster wizard](/media/wac_define_network_ga.png "Define networks in the Create Cluster wizard")

8. Once the networks have been verified, you can optionally review the networking test report, and once complete, click **Next**

9. Once changes have been successfully applied, click **Next: Clustering**

### Clustering ###
With the network configured for the evaluation environment, it's time to construct the local cluster.

1. At the start of the **Cluster** wizard, on the **Validate the cluster** page, click **Validate**.  You *may* be prompted with a **Credential Security Service Provider (CredSSP)** box - read the information, then click **Yes**

![Validate cluster in the Create Cluster wizard](/media/wac_credssp_ga.png "Validate cluster in the Create Cluster wizard")

2. Cluster validation will then start, and will take a few moments to complete - once completed, you should see a successful message.

**NOTE** - Cluster validation is intended to catch hardware or configuration problems before a cluster goes into production. Cluster validation helps to ensure that the Azure Stack HCI 20H2 solution that you're about to deploy is truly dependable. You can also use cluster validation on configured failover clusters as a diagnostic tool. If you're interested in learning more about Cluster Validation, [check out the official docs](https://docs.microsoft.com/en-us/azure-stack/hci/deploy/validate "Cluster validation official documentation").

**NOTE** - if you see an issues when trying to validate the cluster, [see the workarounds here](#troubleshooting-cluster-validation-issues).

![Validation complete in the Create Cluster wizard](/media/wac_validated_ga.png "Validation complete in the Create Cluster wizard")

1. Optionally, if you want to review the validation report, click on **Download report** and open the file in your browser.
2. Back in the **Validate the cluster** screen, click **Next**
3. On the **Create the cluster** page, enter your **cluster name** as **AZSHCICLUS**
4. Under **IP address**, click **Specify one or more static addresses**, and enter **192.168.0.10** (assuming you've deployed less than 10 nodes, otherwise adjust accordingly), and click **Add**
5. Expand **Advanced** and review the settings, then click **Create cluster**

![Finalize cluster creation in the Create Cluster wizard](/media/wac_create_clus_ga.png "Finalize cluster creation in the Create Cluster wizard")

6. With all settings confirmed, click **Create cluster**. This will take a few moments.  Once complete, click **Next: Storage**

![Cluster creation successful in the Create Cluster wizard](/media/wac_cluster_success_ga.png "Cluster creation successful in the Create Cluster wizard")

### Storage ###
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

6. With Storage Spaces Direct enabled, click **Finish**
7. On the **confirmation page**, click on **Go to connections list**

Configuring the cluster witness
-----------
By deploying an Azure Stack HCI 20H2 cluster, you're providing high availability for workloads. These resources are considered highly available if the nodes that host resources are up; however, the cluster generally requires more than half the nodes to be running, which is known as having quorum.

Quorum is designed to prevent split-brain scenarios which can happen when there is a partition in the network and subsets of nodes cannot communicate with each other. This can cause both subsets of nodes to try to own the workload and write to the same disk which can lead to numerous problems. However, this is prevented with Failover Clustering's concept of quorum which forces only one of these groups of nodes to continue running, so only one of these groups will stay online.

In this step, we're going to utilize a **Cloud witness** to help provide quorum.  If you want to learn more about quorum, [check out the official documentation.](https://docs.microsoft.com/en-us/azure-stack/hci/concepts/quorum "Official documentation about Cluster quorum")

As part of this guide, we're going to set up cluster quorum, using **Windows Admin Center**.

1. If you're not already, ensure you're logged into your **Windows Admin Center** instance, and click on your **azshciclus** cluster that you created earlier

![Connect to your cluster with Windows Admin Center](/media/wac_azshciclus_ga.png "Connect to your cluster with Windows Admin Center")

2. You may be prompted for credentials, so log in with your **azshci\labadmin** credentials and tick the **Use these credentials for all connections** box. You should then be connected to your **azshciclus cluster**
3. After a few moments of verification, the **cluster dashboard** will open. 
4. On the **cluster dashboard**, at the very bottom-left of the window, click on **Settings**
5. In the **Settings** window, click on **Witness** and under **Witness type**, use the drop-down to select **Cloud witness**

![Set up cloud witness in Windows Admin Center](/media/wac_cloud_witness_new_ga.png "Set up cloud witness in Windows Admin Center")

6. Open a new tab in your browser, and navigate to **https://portal.azure.com** and login with your Azure credentials
7. You should already have a subscription from an earlier step, but if not, you should [review those steps and create one, then come back here](/nested/steps/1b_NestedInAzure.md#get-an-azure-subscription)
8. Once logged into the Azure portal, click on **Create a Resource**, click **Storage**, then **Storage account**
9. For the **Create storage account** blade, ensure the **correct subscription** is selected, then enter the following:

    * Resource Group: **Create new**, then enter **azshcicloudwitness**, and click **OK**
    * Storage account name: **azshcicloudwitness**
    * Location: **Select your preferred region**
    * Performance: **Only standard is supported**
    * Account kind: **Storage (general purpose v1)** is the best option for cloud witness
    * Replication: **Locally-redundant storage (LRS)** - Failover Clustering uses the blob file as the arbitration point, which requires some consistency guarantees when reading the data. Therefore you must select Locally-redundant storage for Replication type.

![Set up storage account in Azure](/media/azure_cloud_witness_ga.png "Set up storage account in Azure")

10. On the **Networking** and **Data protection** pages, accept the defaults and press **Next**
11. On the **Advanced** page, ensure that **Blob public access** is **disabled**, and **Minimum TLS version** is set to **Version 1.2**
12. When complete, click **Create** and your deployment will begin.  This should take a few moments.
13. Once complete, in the **notification**, click on **Go to resource**
14. On the left-hand navigation, under Settings, click **Access Keys**. When you create a Microsoft Azure Storage Account, it is associated with two Access Keys that are automatically generated - Primary Access key and Secondary Access key. For a first-time creation of Cloud Witness, use the **Primary Access Key**. There is no restriction regarding which key to use for Cloud Witness.
15. Click on **Show keys** and take a copy of the **Storage account name** and **key1**

![Configure Primary Access key in Azure](/media/azure_keys_ga.png "Configure Primary Access key in Azure")

16. On the left-hand navigation, under Settings, click **Properties** and make a note of your **blob service endpoint**.

![Blob Service endpoint in Azure](/media/azure_blob_ga.png "Blob Service endpoint in Azure")

**NOTE** - The required service endpoint is the section of the Blob service URL **after blob.**, i.e. for our configuration, **core.windows.net**

17. With all the information gathered, return to the **Windows Admin Center** and complete the form with your values, then click **Save**

![Providing storage account info in Windows Admin Center](/media/wac_azure_key_ga.png "Providing storage account info in Windows Admin Center")

18. Within a few moments, your witness settings should be successfully applied and you have now completed configuring the quorum settings for the **azshciclus** cluster.

Connect and Register Azure Stack HCI 20H2 to Azure
-----------
Azure Stack HCI 20H2 is delivered as an Azure service and needs to register within 30 days of installation per the Azure Online Services Terms.  With our cluster configured, we'll now register your Azure Stack HCI 20H2 cluster with **Azure Arc** for monitoring, support, billing, and hybrid services. Upon registration, an Azure Resource Manager resource is created to represent each on-premises Azure Stack HCI 20H2 cluster, effectively extending the Azure management plane to Azure Stack HCI 20H2. Information is periodically synced between the Azure resource and the on-premises cluster.  One great aspect of Azure Stack HCI 20H2, is that the Azure Arc registration is a native capability of Azure Stack HCI 20H2, so there is no agent required.

**NOTE** - After registering your Azure Stack HCI 20H2 cluster, the **first 30 days usage will be free**.

### Prerequisites for registration ###
Firstly, **you need an Azure Stack HCI 20H2 cluster**, which we've just created, so you're good there.

Your nodes need to have **internet connectivity** in order to register and communicate with Azure.  If you've been running nested in Azure, you should have this already set up correctly, but if you're running nested on a local physical machine, make any necessary adjustments to your InternalNAT switch to allow internet connections through to your nested Azure Stack HCI 20H2 nodes.

You'll need an **Azure subscription**, but seeing as you've just configured the **cloud witness** earlier, we'll assume that's taken care of.

You'll need appropriate **Azure Active Directory permissions** to complete the registration process. If you don't already have them, you'll need to ask your Azure AD administrator to grant permissions or delegate them to you.  You can learn more about this below.

#### What happens when you register Azure Stack HCI 20H2? ####
When you register your Azure Stack HCI 20H2 cluster, the process creates an Azure Resource Manager (ARM) resource to represent the on-prem cluster. This resource is provisioned by an Azure resource provider (RP) and placed inside a resource group, within your chosen Azure subscription.  If these Azure concepts are new to you, you can check out an [overview of them, and more, here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview "Azure Resource Manager overview").

![ARM architecture for Azure Stack HCI 20H2](/media/azure_arm.png "ARM architecture for Azure Stack HCI 20H2")

In addition to creating an Azure resource in your subscription, registering Azure Stack HCI 20H2 creates an app identity, conceptually similar to a user, in your Azure Active Directory tenant. The app identity inherits the cluster name. This identity acts on behalf on the Azure Stack HCI 20H2 cloud service, as appropriate, within your subscription.

#### Understanding required Azure Active Directory permissions ####
If the user who registers Azure Stack HCI 20H2 is an Azure Active Directory global administrator or has been delegated sufficient permissions, this all happens automatically, and no additional action is required. If not, approval may be needed from your Azure Active Directory global administrator (or someone with appropriate permissions) to complete registration. Your global administrator can either explicitly grant consent to the app, or they can delegate permissions so that you can grant consent to the app.

![Azure Active Directory Permissions](/media/aad_permissions.png "Azure Active Directory Permissions")

The user who runs Register-AzStackHCI needs Azure AD permissions to:

* Create/Get/Set/Remove Azure AD applications (New/Get/Set/Remove-AzureADApplication)
* Create/Get Azure AD service principal (New/Get-New-AzureADServicePrincipal)
* Manage AD application secrets (New/Get/Remove-AzureADApplicationKeyCredential)
* Grant consent to use specific application permissions (New/Get/Remove AzureADServiceAppRoleAssignments)

There are three ways in which this can be accomplished.

#### Option 1: Allow any user to register applications ####

In Azure Active Directory, navigate to User settings > **App registrations**. Under **Users can register applications**, select **Yes**.

This will allow any user to register applications. However, the user will still require the Azure AD admin to grant consent during cluster registration. Note that this is a tenant level setting, so it may not be suitable for large enterprise customers.

#### Option 2: Assign Cloud Application Administration role ####

Assign the built-in "Cloud Application Administration" Azure AD role to the user. This will allow the user to register clusters without the need for additional AD admin consent.

#### Option 3: Create a custom AD role and consent policy ####

The most restrictive option is to create a custom AD role with a custom consent policy that delegates tenant-wide admin consent for required permissions to the Azure Stack HCI Service. When assigned this custom role, users are able to both register and grant consent without the need for additional AD admin consent.

**NOTE** - This option requires an Azure AD Premium license and uses custom AD roles and custom consent policy features which are currently in public preview.

If you choose to perform Option 3, you'll need to follow these steps on **MGMT01**, which we'll demonstrate mainly through PowerShell.

1. Firstly, configure the appropriate AzureAD modules, then **Connect to Azure AD**, and when prompted, **log in with your appropriate credentials**

```powershell
Remove-Module AzureAD -ErrorAction SilentlyContinue -Force
Install-Module AzureADPreview -AllowClobber -Force
Connect-AzureAD
```

2. Create a **custom consent policy**:

```powershell
New-AzureADMSPermissionGrantPolicy -Id "AzSHCI-registration-consent-policy" `
    -DisplayName "Azure Stack HCI registration admin app consent policy" `
    -Description "Azure Stack HCI registration admin app consent policy"
```

3. Add a condition that includes required app permissions for Azure Stack HCI service, which carries the app ID 1322e676-dee7-41ee-a874-ac923822781c. Note that the following permissions are for the GA release of Azure Stack HCI, and will not work with Public Preview unless you have applied the [November 23, 2020 Preview Update (KB4586852)](https://docs.microsoft.com/en-us/azure-stack/hci/release-notes "November 23, 2020 Preview Update (KB4586852)") to every server in your cluster and have downloaded the Az.StackHCI module version 0.4.1 or later.

```powershell
New-AzureADMSPermissionGrantConditionSet -PolicyId "AzSHCI-registration-consent-policy" `
    -ConditionSetType "includes" -PermissionType "application" -ResourceApplication "1322e676-dee7-41ee-a874-ac923822781c" `
    -Permissions "bbe8afc9-f3ba-4955-bb5f-1cfb6960b242", "8fa5445e-80fb-4c71-a3b1-9a16a81a1966", `
    "493bd689-9082-40db-a506-11f40b68128f", "2344a320-6a09-4530-bed7-c90485b5e5e2"
```

4. Grant permissions to allow registering Azure Stack HCI, noting the custom consent policy created in Step 2:

```powershell
$displayName = "Azure Stack HCI Registration Administrator "
$description = "Custom AD role to allow registering Azure Stack HCI "
$templateId = (New-Guid).Guid
$allowedResourceAction =
@(
    "microsoft.directory/applications/createAsOwner",
    "microsoft.directory/applications/delete",
    "microsoft.directory/applications/standard/read",
    "microsoft.directory/applications/credentials/update",
    "microsoft.directory/applications/permissions/update",
    "microsoft.directory/servicePrincipals/appRoleAssignedTo/update",
    "microsoft.directory/servicePrincipals/appRoleAssignedTo/read",
    "microsoft.directory/servicePrincipals/appRoleAssignments/read",
    "microsoft.directory/servicePrincipals/createAsOwner",
    "microsoft.directory/servicePrincipals/credentials/update",
    "microsoft.directory/servicePrincipals/permissions/update",
    "microsoft.directory/servicePrincipals/standard/read",
    "microsoft.directory/servicePrincipals/managePermissionGrantsForAll.AzSHCI-registration-consent-policy"
)
$rolePermissions = @{'allowedResourceActions' = $allowedResourceAction }
```

5. Create the new custom AD role:

```powershell
$customADRole = New-AzureADMSRoleDefinition -RolePermissions $rolePermissions `
    -DisplayName $displayName -Description $description -TemplateId $templateId -IsEnabled $true
```

6. Assign the new custom AD role to the user who will register the Azure Stack HCI cluster with Azure by following [these instructions](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-users-assign-role-azure-portal "Guidance on creating a custom Azure AD role").

### Complete Registration ###
To complete registration, you have 2 options - you can use **Windows Admin Center**, or you can use **PowerShell**.

#### Option 1 - Register using Windows Admin Center ####

1. On **MGMT01**, logged in as **azshci\labadmin**, open the Windows Admin Center, and on the **All connections** page, select your azshciclus
2. When the cluster dashboard has loaded, in the top-right corner, you'll see the **status of the Azure registration/connection**

![Azure registration status in Windows Admin Center](/media/wac_azure_reg_dashboard.png "Azure registration status in Windows Admin Center")

3. Click on **Install PowerShell modules** to trigger Windows Admin Center to download and install the appropriate PowerShell modules to the Azure Stack HCI 20H2 node. This may take a few moments.

![Azure registration status in Windows Admin Center](/media/wac_azure_reg_dashboard_2.png "Azure registration status in Windows Admin Center")

4. Once installed, you can begin the registration process by clicking **Register this cluster**
5. If you haven't already, you'll be prompted to register Windows Admin Center with an Azure tenant.  Follow the instructions to **Copy the code** and then click on the link to configure device login.
6. When prompted for credentials, **enter your Azure credentials** for a tenant you'd like to register the Windows Admin Center
7. Back in Windows Admin Center, you'll notice your tenant information has been added.  You can now click **Connect** to connect Windows Admin Center to Azure

![Connecting Windows Admin Center to Azure](/media/wac_azure_connect.png "Connecting Windows Admin Center to Azure")

8. Click on **Sign in** and when prompted for credentials, **enter your Azure credentials** and you should see a popup that asks for you to accept the permissions, so click **Accept**

![Permissions for Windows Admin Center](/media/wac_azure_permissions.png "Permissions for Windows Admin Center")

9. Back in Windows Admin Center, you may need to refresh the page if your 'Register this cluster' link is not active. Once active, click **Register this cluster** and you should be presented with a window requesting more information.
10. Choose your **Azure subscription** that you'd like to use to register, along with an **Azure resource group** and **region**, then click **Register**.  This will take a few moments.

![Final step for registering Azure Stack HCI with Windows Admin Center](/media/wac_azure_register.png "Final step for registering Azure Stack HCI with Windows Admin Center")

11. Once completed, you should see updated status on the Windows Admin Center dashboard, showing that the cluster has been correctly registered.

![Azure registration status in Windows Admin Center](/media/wac_azure_reg_dashboard_3.png "Azure registration status in Windows Admin Center")

You can now proceed on to [Viewing registration details in the Azure portal](#View-registration-details-in-the-Azure-portal)

#### Option 2 - Register using PowerShell ####
We're going to perform the registration from the **MGMT01** machine, which we've been using with the Windows Admin Center.

1. On **MGMT01**, open **PowerShell as administrator** and run the following code to install the PowerShell Module for Azure Stack HCI 20H2 on that machine.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
Install-Module Az.StackHCI
```

**NOTE** - You may recieve a message that **PowerShellGet requires NuGet Provider...** - read the full message, and then click **Yes** to allow the appropriate dependencies to be installed. You may receive a second prompt to **install the modules from the PSGallery** - click **Yes to All** to proceed.

In addition, in future releases, installing the Azure PowerShell **Az** modules will include **StackHCI**, however today, you have to install this module specifically, using the command **Install-Module Az.StackHCI**

2. With the Az.StackHCI modules installed, it's now time to register your Azure Stack HCI 20H2 cluster to Azure, however first, it's worth exploring how to check existing registration status.  The following code assumes you are still in the remote PowerShell session open from the previous commands.

```powershell
Invoke-Command -ComputerName AZSHCINODE01 -ScriptBlock {
    Get-AzureStackHCI
}
```

![Check the registration status of the Azure Stack HCI 20H2 cluster](/media/reg_check.png "Check the registration status of the Azure Stack HCI 20H2 cluster")

As you can see from the result, the cluster is yet to be registered, and the cluster status identifies as **Clustered**. Azure Stack HCI 20H2 needs to register within 30 days of installation per the Azure Online Services Terms. If not clustered after 30 days, the **ClusterStatus** will show **OutOfPolicy**, and if not registered after 30 days, the **RegistrationStatus** will show **OutOfPolicy**.

3. To register the cluster, you'll first need to get your **Azure subscription ID**.  An easy way to do this is to quickly **log into https://portal.azure.com**, and in the **search box** at the top of the screen, search for **subscriptions** and then click on **Subscriptions**

![Azure Subscriptions](/media/azure_subscriptions_ga.png "Azure Subscriptions")

4. Your **subscription** should be shown in the main window.  If you have more than one subscription listed here, click the correct one, and in the new blade, copy the **Subscription ID**.

**NOTE** - If you don't see your desired subscription, in the top right-corner of the Azure portal, click on your user account, and click **Switch directory**, then select an alternative directory.  Once in the chosen directory, repeat the search for your **Subscription ID** and copy it down.

5. With your **Subscription ID** in hand, you can **register using the following Powershell commands**, from your open PowerShell window.

```powershell
$azshciNodeCreds = Get-Credential -UserName "azshci\labadmin" -Message "Enter the Lab Admin password"
Register-AzStackHCI `
    -SubscriptionId "your-subscription-ID-here" `
    -ResourceName "azshciclus" `
    -ResourceGroupName "AZSHCICLUS_RG" `
    -Region "EastUS" `
    -EnvironmentName "AzureCloud" `
    -ComputerName "AZSHCINODE01.azshci.local" `
    –Credential $azshciNodeCreds
```

Of these commands, many are optional:

* **-ResourceName** - If not declared, the Azure Stack HCI 20H2 cluster name is used
* **-ResourceGroupName** - If not declared, the Azure Stack HCI 20H2 cluster plus the suffix "-rg" is used
* **-Region** - If not declared, "EastUS" will be used.  Additional regions are supported, with the longer term goal to integrate with Azure Arc in all Azure regions.
* **-EnvironmentName** - If not declared, "AzureCloud" will be used, but allowed values will include additional environments in the future
* **-ComputerName** - This is used when running the commands remotely against a cluster.  Just make sure you're using a domain account that has admin privilege on the nodes and cluster
* **-Credential** - This is also used for running the commands remotely against a cluster.

**Register-AzureStackHCI** runs syncronously, with progress reporting, and typically takes 1-2 minutes.  The first time you run it, it may take slightly longer, because it needs to install some dependencies, including additional Azure PowerShell modules.

6. Once dependencies have been installed, you'll receive a popup on **MGMT01** to authenticate to Azure. Provide your **Azure credentials**.

![Login to Azure](/media/azure_login_reg.png "Login to Azure")

7. Once successfully authenticated, the registration process will begin, and will take a few moments. Once complete, you should see a message indicating success, as per below:

![Register Azure Stack HCI 20H2 with PowerShell](/media/register_azshci_ga.png "Register Azure Stack HCI 20H2 with PowerShell")

**NOTE** - if upon registering, you receive an error similar to that below, please **try a different region**.  You can still proceed to [Step 5](#next-steps) and continue with your evaluation, and it won't affect any functionality.  Just make sure you come back and register later!

```
Register-AzStackHCI : Azure Stack HCI 20H2 is not yet available in region <regionName>
```

8. Once the cluster is registered, run the following command on **MGMT01** to check the updated status:

```powershell
Invoke-Command -ComputerName AZSHCINODE01 -ScriptBlock {
    Get-AzureStackHCI
}
```
![Check updated registration status with PowerShell](/media/registration_status.png "Check updated registration status with PowerShell")

You can see the **ConnectionStatus** and **LastConnected** time, which is usually within the last day unless the cluster is temporarily disconnected from the Internet. An Azure Stack HCI 20H2 cluster can operate fully offline for up to 30 consecutive days.

### View registration details in the Azure portal ###
With registration complete, either through Windows Admin Center, or through PowerShell, you should take some time to explore the artifacts that are created in Azure, once registration successfully completes.

1. On **MGMT01**, open the Edge browser and **log into https://portal.azure.com** to check the resources created there. In the **search box** at the top of the screen, search for **Resource groups** and then click on **Resource groups**
2. You should see a new **Resource group** listed, with the name you specified earlier, which in our case, is **AZSHCICLUS_RG**

![Registration resource group in Azure](/media/registration_rg_ga.png "Registration resource group in Azure")

12. Click on the **AZSHCICLUS_RG** resource group, and in the central pane, you'll see that a record with the name **azshciclus** has been created inside the resource group
13. Click on the **azihciclus** record, and you'll be taken to the new Azure Stack HCI Resource Provider, which shows information about all of your clusters, including details on the currently selected cluster

![Overview of the recently registered cluster in the Azure portal](/media/azure_portal_hcicluster.png "Overview of the recently registered cluster in the Azure portal")

14. Next, still in the Azure portal, in the **search box** at the top of the screen, search for **Azure Active Directory** and then click on **Azure Active Directory**
15. Click on **App Registrations**, then (you may need to click on **All applications**) in the box labeled "Start typing a name or Application ID to filter these results", enter **azshciclus** and in the results, click on your application

![Application ID in App Registrations in Azure](/media/azure_ad_app_ga.png "Application ID in App Registrations in Azure")

1.  Within the application, click on **API permissions**.  From there, you can see the **Configured permissions** which have been created as part of the **Register-AzureStackHCI** you ran earlier.  You can see that a number of services that have been granted appropriate permissions for billing and cluster management.

Optionally, you can click on these services to see more information

![Application ID API Permissions for App Registration in Azure](/media/api_permissions_ga.png "Application ID API Permissions for App Registration in Azure")

**NOTE** - If when you ran **Register-AzureStackHCI**, you don't have appropriate permissions in Azure Active Directory, to grant admin consent, you will need to work with your Azure Active Directory administrator to complete registration later. You can exit and leave the registration in status "**pending admin consent**," i.e. partially completed. Once consent has been granted, **simply re-run Register-AzureStackHCI** to complete registration.

### Congratulations! ###
You've now successfully deployed, configured and registered your Azure Stack HCI 20H2 cluster!

Next Steps
-----------
In this step, you've successfully created a nested Azure Stack HCI 20H2 cluster using Windows Admin Center.  With this complete, you can now [Explore the management of your Azure Stack HCI 20H2 environment](/nested/steps/5_ExploreAzSHCI.md "Explore the management of your Azure Stack HCI 20H2 environment")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI 20H2, Windows Admin Center, or the Azure Arc integration and experience, let us know!  We want to hear from you!  [Head on over to our Azure Stack HCI 20H2 UserVoice page](https://feedback.azure.com/forums/929833-azure-stack-hci "Azure Stack HCI 20H2 UserVoice"), where you can share your thoughts and ideas about making the technologies better.  If however, you have an issue that you'd like some help with, read on...

Raising issues
-----------
If you notice something is wrong with the evaluation guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If however, you're having a problem with Azure Stack HCI 20H2 **outside** of this evaluation guide, make sure you post to [our Microsoft Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Microsoft Q&A Forum"), where Microsoft experts and valuable members of the community will do their best to help you.

Troubleshooting cluster validation issues
-----------

#### CredSSP issue ####
During testing, you **may** see an issue initiating cluster validation due to a CredSSP issue.  To workaround this issue, on **MGMT01**, you should run the following command:

```powershell
Disable-WsmanCredSSP -Role Client
```

And for **each of the nested Azure Stack HCI 20H2 nodes**, on your Hyper-V host, run the following 

```powershell
# Provide the domain credentials to log into the VM
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
$nodeName = "AZSHCINODE01"
Invoke-Command -VMName $nodeName -Credential $domainCreds -ScriptBlock {
    Disable-WsmanCredSSP -Role Server
    Test-ComputerSecureChannel -Verbose -Repair
    gpupdate /force
    Restart-Computer -Force
}
```

You should then be able to continue the validation process once all the nodes are back online.

#### WinRM issue ####
If you see a **WinRM** related issue when running validation, on the **MGMT01** OS, run the following in PowerShell:

```powershell
Restart-Service WinRm
Restart-Computer -Force
```

Also for **each of the nested Azure Stack HCI 20H2 nodes**, on your Hyper-V host, run the following 

```powershell
# Provide the domain credentials to log into the VM
$domainName = "azshci.local"
$domainAdmin = "$domainName\labadmin"
$domainCreds = Get-Credential -UserName "$domainAdmin" -Message "Enter the password for the LabAdmin account"
Invoke-Command -VMName $nodeName -Credential $domainCreds -ScriptBlock {
    Restart-Service WinRm
    Restart-Computer -Force
}
```

Then, back on **MGMT01**, access the Windows Admin Center, if you restart the cluster creation wizard, Windows Admin Center should allow you to pick up where you left off previously.

#### Test Report issue ####
If you see an issue with an error relating to **Test report isn't available, try to validate again**, this is likely due to a bug where your Azure Stack HCI 20H2 nodes are in a different locale than the MGMT01/Windows Admin Center machine.  To fix this, on **each of the nested Azure Stack HCI 20H2 nodes**, run the following in PowerShell:

```powershell
Get-WinSystemLocale # If not en-US you will have problems
Set-WinSystemLocale -SystemLocale en-US
Restart-Computer -Force
```

Then run validate again, and it should pass this step.  This bug is being actively worked on, and should be addressed soon.
