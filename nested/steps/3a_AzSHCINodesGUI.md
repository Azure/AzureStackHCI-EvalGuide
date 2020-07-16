Deploy nested Azure Stack HCI nodes with the GUI
==============
Overview
-----------

With your Hyper-V host up and running, along with the management infrastructure, it's now time to deploy the Azure Stack HCI nodes into VMs on your Hyper-V host.

Architecture
-----------

As shown on the architecture graphic below, you'll deploy a number of nested Azure Stack HCI nodes. The minimum number for deployment of a local Azure Stack HCI cluster is 2 nodes, however if your Hyper-V host has enough spare capacity, you could deploy additional nodes, and explore more complex scenarios, such as a nested **stretch **cluster****.  For the purpose of this step, we'll focus on deploying 4 nodes, however you should make adjustments based on your environment.

![Architecture diagram for Azure Stack HCI nested](/media/nested_virt_nodes.png "Architecture diagram for Azure Stack HCI nested")

