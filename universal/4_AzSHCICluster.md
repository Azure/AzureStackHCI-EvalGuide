Create Azure Stack HCI cluster with Windows Admin Center
==============
Overview
-----------

So far, you've deployed your Azure Stack HCI nodes, either in a nested virtualization sandbox, or on existing physical hardware.  In the case of the sandboxed environment, you've also stood up an Active Directory infrastructure with DNS and DHCP services running.  In a physical deployment, it was assumed these kind of dependencies were already in place.  Finally, in both cases, you've deployed the Windows Admin Center, which we'll be using to configure the Azure Stack HCI cluster.

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
Not only does Azure Stack HCI support a local cluster, consisting of between 2 and 16 nodes, but, also supports a **Stretch Cluster**, where a single cluster can have nodes distrubuted across two sites.

* If you have 2 Azure Stack HCI nodes, you will be able to create a **local cluster**
* If you have 4 Azure Stack HCI nodes, you will have a choice of creating either a **local cluster** or a **stretch cluster**

The steps below will be separated for creating a local cluster, and creating a stretched cluster. Choose which cluster type is most appropriate for your needs and proceed.

Creating a (local) cluster
-----------
If you have just 2 nodes, or if your preference is for a cluster running in a single site, this section will walk through the key steps for you to set up the Azure Stack HCI cluster with the Windows Admin Center

1. Access your **Windows Admin Center** instance.  Those of you running on the **nested** path, you'll need to open **MGMT01** and access Windows Admin Center from there.
2. Once logged into Windows Admin Center, under **All connections**, click **Add**
3. On the **Add resources popup**, under **Windows Server cluster**, click **Create new** to open the **Cluster Creation wizard**

### Get started ###

![Choose cluster type in the Create Cluster wizard](/media/wac_cluster_type.png)

1. Ensure you select **Azure Stack HCI**, select **All servers in one site** and cick **Create**
2. On the **Check the prerequisites** page, review the requirements and click **Next**
3. On the **Add Servers** page, supply a **username**, which should be **administrator** and **password** and then one by one, enter the node names (or IP addresses if names don't resolve) of your Azure Stack HCI nodes, clicking **Add** after each one.  Each node will be validated, and given a **Ready** status when fully validated.

![Add servers in the Create Cluster wizard](/media/add_servers.png)

4. On the **Join a domain** page, enter your domain (azshci.local from the nested path of this evaluation guide) and your **LabAdmin credentials**, then click **Apply changes** to join these machines to the domain.
5. Windows Admin Center will then join the nodes to the domain, ready for the next step.  Once complete, click **Next**

![Joined the domain in the Create Cluster wizard](/media/wac_domain_joined.png)

6. On the **Install features** page, Windows Admin Center will query the nodes for currently installed features, and will request you install required features.  Click **Install features**.  This will take a few moments - once complete, click **Next**

![Installing required features in the Create Cluster wizard](/media/wac_installed_features.png)

7. On the **Install updates** page, Windows Admin Center will query the nodes for available updates, and will request you install any that are required.  Click **Install updates**.  This will take a few moments - once complete, click **Next**
8. On the **Solution updates** page, install any appropriate extensions (only for the physical path in this evaluation guide) and then click **Next**
9. On the **Restart servers** page, click **Restart servers**

![Restart nodes in the Create Cluster wizard](/media/wac_restart.png)

### Networking ###
With the servers domain joined, configured with the appropriate features, updated and rebooted, you're ready to configure your network.  You have a number of different choices here, so we'll try to explain why we're making each selection, so you can better apply it to your environment further down the road.

1. Firstly, Windows Admin Center will verify your networking setup - it'll tell you how many NICs are in each node, along with relevant hardware information, MAC address and status information.  Review for accuracy, and then click **Next**

![Verify network in the Create Cluster wizard](/media/wac_verify network.png)

The first key step with setting up the networking with Windows Admin Center, is to choose a management NIC that will be dedicated for management use.  You can choose either a single NIC, or two NICs for redundancy.

As it stands, this is the way that the Windows Admin Center approaches the network configuration, however, if you were not using the Windows Admin Center, through PowerShell, there are a number of different ways to configure the network adapters to meet your needs.  We will work through the Windows Admin Center approach in this guide.

* If you are following the **Nested path in this evaluation guide**, you should have 4 NICs listed as available.  You should choose **Two physical network adapters teamed for management**
* If you are following the **Physical path in this evaluation guide**, you should have at least 2 NICs listed as available.  If you have exactly 2 NICs, you will need to choose **One physical network adapter for management**, however if you have 4 or more NICs, you can choose **Two physical network adapters teamed for management**

1. On the **Select the adapters to use for management** page, select the number of NICs you wish to dedicate for magamenet using the boxes at the top of the page




