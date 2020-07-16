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

