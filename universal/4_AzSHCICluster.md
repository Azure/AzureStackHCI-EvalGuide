Create Azure Stack HCI cluster with Windows Admin Center
==============
Overview
-----------

So far, you've deployed your Azure Stack HCI nodes, either in a nested virtualization sandbox, or on existing physical hardware.  In the case of the sandboxed environment, you've also stood up an Active Directory infrastructure with DNS.  In a physical deployment, it was assumed these kind of dependencies were already in place.  Finally, in both cases, you've deployed the Windows Admin Center, which we'll be using to configure the Azure Stack HCI cluster.

Architecture
-----------


Before you begin
-----------
With Windows Admin Center, you now have the ability to construct Azure Stack HCI clusters from the vanilla nodes.  There are no additional extensions to install, the workflow is built in and ready to go.

Before you start creating the cluster, it's important that we briefly review the steps that we've performed, and map them to the requirements:

1. In the case of physical multi-node deployments, all physical nodes are running on suitable hardware
2. All nodes are running the Azure Stack HCI OS
3. Windows Admin Center is installed and operational, on the same AD domain into which you'll deploy the cluster
4. You have an account that's a local admin on each server

As it stands, you should have met those requirements thus far, and should be in good shape to proceed on with cluster creation.

Here are the major steps in the Create Cluster wizard in Windows Admin Center:

* Get Started - ensures that each server meets the prerequisites for and features needed for cluster join
* Networking - assigns and configures network adapters and creates the virtual switches for each server
* Clustering - validates the cluster is set up correctly. For stretched clusters, also sets up up the two sites
* Storage - Configures Storage Spaces Direct

After the wizard completes, you set up the cluster witness, optionally register with Azure (to integrate additional services, like Azure Backup, Azure Monitor etc), and then create volumes (which also sets up replication between sites if you're creating a stretched cluster).

### Decide on cluster type ###
Not only does Azure Stack HCI support a cluster in a single site (or a **local cluster** as i'll refer to it going forward) consisting of between 2 and 16 nodes, but, also supports a **Stretch Cluster**, where a single cluster can have nodes distrubuted across two sites.

* If you have 2 Azure Stack HCI nodes, you will be able to create a **local cluster**
* If you have 4 Azure Stack HCI nodes, you will have a choice of creating either a **local cluster** or a **stretch cluster**

In this first release of the guide, we'll be focusing on deploying a **local cluster** but guidance for stretch clustering will be added soon, so check back later!

Creating a (local) cluster
-----------
If you have just 2 nodes, or if your preference is for a cluster running in a single site, this section will walk through the key steps for you to set up the Azure Stack HCI cluster with the Windows Admin Center

1. Connect to **MGMT01**, and open your **Windows Admin Center** instance.
2. Once logged into Windows Admin Center, under **All connections**, click **Add**
3. On the **Add resources popup**, under **Windows Server cluster**, click **Create new** to open the **Cluster Creation wizard**

### Get started ###

![Choose cluster type in the Create Cluster wizard](/media/wac_cluster_type.png)

1. Ensure you select **Azure Stack HCI**, select **All servers in one site** and cick **Create**
2. On the **Check the prerequisites** page, review the requirements and click **Next**
3. On the **Add Servers** page, supply a **username**, which should be **azshci\labadmin** and **your-domain-admin-password** and then one by one, enter the node names (or IP addresses if names don't resolve) of your Azure Stack HCI nodes, clicking **Add** twice after each one.  Each node will be validated, and given a **Ready** status when fully validated.

![Add servers in the Create Cluster wizard](/media/add_nodes.png)

4. On the **Join a domain** page, details should already be in place, as we joined domain previously, so click **Next**
5. 

![Joined the domain in the Create Cluster wizard](/media/wac_domain_joined.png)

6. On the **Install features** page, Windows Admin Center will query the nodes for currently installed features, and will request you install required features.  Click **Install features**.  This will take a few moments - once complete, click **Next**

![Installing required features in the Create Cluster wizard](/media/wac_installed_features.png)

7. On the **Install updates** page, Windows Admin Center will query the nodes for available updates, and will request you install any that are required.  Click **Install updates**.  This will take a few moments - once complete, click **Next**
8. On the **Solution updates** page, install any appropriate extensions (only for the physical path in this evaluation guide) and then click **Next**
9. On the **Restart servers** page, click **Restart servers**

![Restart nodes in the Create Cluster wizard](/media/wac_restart.png)

### Networking ###
With the servers domain joined, configured with the appropriate features, updated and rebooted, you're ready to configure your network.  You have a number of different choices here, so we'll try to explain why we're making each selection, so you can better apply it to your environment further down the road.

Firstly, Windows Admin Center will verify your networking setup - it'll tell you how many NICs are in each node, along with relevant hardware information, MAC address and status information.  Review for accuracy, and then click **Next**

![Verify network in the Create Cluster wizard](/media/wac_verify_network.png)

The first key step with setting up the networking with Windows Admin Center, is to choose a management NIC that will be dedicated for management use.  You can choose either a single NIC, or two NICs for redundancy.  This step specifically designates 1 or 2 adapters that will be used by the Windows Admin Center to orchestrate the cluster creation flow.  It's mandatory to select at least one of the adapters for management, and in a physical deployment, the 1GbE NICs are usually good candidates for this.

As it stands, this is the way that the Windows Admin Center approaches the network configuration, however, if you were not using the Windows Admin Center, through PowerShell, there are a number of different ways to configure the network adapters to meet your needs.  We will work through the Windows Admin Center approach in this guide.

#### Network Setup Overview ####
As part of the **nested path in this evaluation guide**, each of your Azure Stack HCI nodes should have 4 NICs.  For this simple evaluation, you'll dedicate the NICs in the following way:

* 1 NIC will be dedicated to management.  It will reside on the 192.168.0.0/24 subnet. No virtual switch will be attached to this NIC.
* 1 NIC will be dedicated to VM traffic.  A virtual switch will be attached to this NIC and the Azure Stack HCI host will no longer use this NIC for it's own traffic.
* 2 NICs will be dedicated to storage traffic.  They will reside on 2 separate subnets, 10.10.10.0/24 and 10.10.11.0/24. No virtual switches will be attached to these NICs.

Again, this is just one **example** network configuration for the purpose of evaluation.

1. Back in the Windows Admin Center, on the **Select the adapters to use for management** page, select the number of NICs you wish to dedicate for management using the boxes at the top of the page

![Select management adapter in the Create Cluster wizard](/media/wac_singlemgmt_nic.png)

2. Select 1 or 2 adapters, depending on how management management adapters you chose to use, then scroll down the page, and click **Apply and test**

![Select management adapters in the Create Cluster wizard](/media/wac_nic_selection.png)

3. Windows Admin Center will then apply the configuration to your NIC(s) and when complete, click **Next**
4. On the **Define networks** page, this is where you can define the specific networks, separate subnets, and apply VLANs.

![Define networks in the Create Cluster wizard](/media/wac_define_networks.png)

If you have DHCP setup in your environment, which you do if you followed the **nested path in this evaluation guide**, you'll see IP address and subnet information already populated, and no VLANs in use.  When you click **Apply and test**, Windows Admin Center validates network connectivity between the adapters in the same VLAN and subnet, which may take a few moments.

If you are following the **physical path in this evaluation guide, apply your VLANs as appropriate at this point**

For the purpose of this evaluation, if you're following the **nested path**, you should be able to leave the default DHCP supplied values, then click **Apply and test**.  If you're following the physical path, apply appropriate IP addresses, subnet masks and VLANs to match your environment, and click **Apply and test**.

Whilst having a simple, flat network across management, compute and storage isn't recommended for production, for the purposes of evaluation, this configuration is fine.

1. Once the networks have been verified, click **Next**
2. On the **Virtual Switch** page, you have a number of options

![Select vSwitch in the Create Cluster wizard](/media/wac_vSwitch.png)

* **Create one virtual switch for compute and storage together** - in this configuration, your Azure Stack HCI nodes will create a vSwitch, comprised of multiple NICs, and the bandwidth available across these NICs will be shared by the Azure Stack HCI nodes themselves, for storage traffic, and in addition, any VMs you deploy on top, will also share this bandwidth.
* **Create one virtual switch for compute only** - in this configuration, you would leave some NICs dedicated to storage traffic, and have a set of NICs attached to a vSwitch, to which your VMs traffic would be dedicated.
* **Create two virtual switches** - in this configuration, you can create separate vSwitches, each attached to different sets of underlying NICs.  This may be useful if you wish to dedicate a set of underlying NICs to VM traffic, and another set to storage traffic, but wish to have vNICs used for storage communication instead of the underlying NICs.
* **Skip virtual switch creation** - if you want to define things later, that's fine too

7. Select the appropriate switch configuration for your environment - for the **nested path**, with 2 remaining NICs available, you could choose to just create a single vSwitch with 1 underlying NIC, and use the other dedicated NIC for storage, or alternatively, you could create a single vSwitch comprised of the 2 remaining NICs, and use vNICs to separate traffic.  For the physical path, your choices are largely determined by your physical hardware configuration.  For nested, we'll go with creating a single vSwitch for compute and storage together, then click **Apply and test**
8. 