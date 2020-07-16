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

![Choose cluster type in the Create Cluster wizard](/media/wac_cluster_type.png)

4. Ensure you select **Azure Stack HCI**, select **All servers in one site** and cick **Create**
5. On the **Check the prerequisites** page, review the requirements and click **Next**
6. On the **Add Servers** page, supply a **username**, which should be **administrator** and **password** and then one by one, enter the node names (or IP addresses if names don't resolve) of your Azure Stack HCI nodes, clicking **Add** after each one.  Each node will be validated, and given a **Ready** status when fully validated.

![Add servers in the Create Cluster wizard](/media/add_servers.png)

7. On the **Join a domain** page, enter your domain (azshci.local from the nested evaluation guide path) and your **LabAdmin credentials**, then click **Apply changes** to join these machines to the domain.
8. Windows Admin Center will then join the nodes to the domain, ready for the next step.

