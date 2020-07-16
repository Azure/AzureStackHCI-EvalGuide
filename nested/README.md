Evaluate Azure Stack HCI using Nested Virtualization
==============

As with any infrastructure technology, in order to test, validate and evaluate the technology, there's typically a requirement for hardware.  If you're fortunate enough to have multiple server-class pieces of hardware going spare (ideally hardware certified for Windows Server 2019 found on our [Azure Stack HCI Catalog](https://azure.com/hci "Azure Stack HCI Catalog")), you can certainly perform a more real-world evaluation of Azure Stack HCI, and you should follow the [guide for deploying on multiple nodes of physical hardware](../physical/README.md)

For the purpose of this evaluation guide however, we'll be relying on **nested virtualization** to allow us to consolidate a full lab infrastructure, down onto a single Hyper-V host.

### Important Note ###
The use of nested virtualization in this evaluation guide is aimed at providing flexibility for deploying Azure Stack HCI in a lab, or test environment. For **production** use, **Azure Stack HCI should be deployed on certified physical hardware**, of which you can find a vast array of choices on the [Azure Stack HCI Catalog](https://azure.com/hci "Azure Stack HCI Catalog").

Nested Virtualization
-----------
If you're not familiar with Nested Virtualization, at a high level, it allows a virtualization platform, such as Hyper-V, or VMware ESXi, to run virtual machines that, within those virtual machines, run a virtualization platform. It may be easier to think about this in an architectural view.

![Nested virtualization architecture](/media/nested_virt.png)

As you can see from the graphic, at the base layer, you have your physical hardware, onto which you install a hypervisor. In this case, for our example, we're using Windows Server 2019 with the Hyper-V role enabled.  The hypervisor on the lowest level is considered L0 or the level 0 hypervisor.  On that physical host, you create a virtual machine, and into that virtual machine, you deploy an OS that itself, has a hypervisor enabled.  In this example, that 1st Virtualized Layer is running an **nested** Azure Stack HCI operating system. This would be an L1 or level 1 hypervisor.  Finally, in our example, inside the Azure Stack HCI OS, you create a virtual machine to run a workload.  This could in fact also contain a hypervisor, which would be known as the L2 or level 2 hypervisor, and so the process continues, with multiple levels of nested virtualization possible.

The use of nested virtualization opens up amazing opportunities for building complex scenarios on significantly reduced hardware footprints, however it shouldn't be seen as a substitute for real-world deployments, performance and scale testing etc.

Deployment Options
-----------
For those of you who don't have multiple server-class pieces of hardware to test a full hyperconverged solution, this evaluation guide will detail 2 configurations, both using **nested virtualization**, that may be of interest.

### Deployment of Azure Stack HCI nested in Azure ###

![Architecture diagram for Azure Stack HCI nested in Azure](/media/nested_virt_arch.png)

In this configuration, you'll take advantage of the nested virtualization support provided within certain Azure VM sizes.  You'll first deploy a single Azure VM running Windows Server 2019.  Inside this VM, you'll enable the Hyper-V role, and deploy a Windows Server 2019 domain controller VM, along with a management VM, running Windows 10 Enterprise. This management VM will also run the Windows Admin Center.  Finally, you'll deploy a nested Azure Stack HCI cluster, with a minimum of 2 nodes, however the number of nodes will be based on the size of your Azure VM.

To reiterate, the whole configuration (Domain Controller VM, Management VM and Azure Stack HCI Nodes) will run inside the single Azure VM.

### Deployment of Azure Stack HCI nested on a physical system ###

![Architecture diagram for Azure Stack HCI nested on a physical system](/media/nested_virt_physical.png)

In this configuration, you'll again take advantage of nested virtualization, but in this case, you'll deploy the whole solution on a single desktop/laptop/server.  On your physical system, you'll run either Windows Server 2016/2019 or Windows 10 Pro/Enterprise/Education, with the Hyper-V role enabled.  On Hyper-V, you'll deploy a sandbox infrastructure, consisting of a Windows Server 2019 domain controller VM, a management VM running Windows 10 Enterprise, and a nested Azure Stack HCI cluster.

Deployment Workflow
-----------
This guide will walk you through deploying a sandboxed Azure Stack HCI infrastructure.  Many of the steps will be universal, regardless of whether you are deploying in Azure, or deploying on a single physical system, however to accommodate different preferences, we've provided paths for those of you who prefer PowerShell, or GUI (Graphical User Interface, such as Hyper-V Manager, Server Manager etc)-based deployments.

The general flow will be as follows:

![Evaluation guide workflow using nested virtualization](/media/flow_chart_paths.png "Evaluation guide workflow using nested virtualization")

#### Part 1a - Deploy Hyper-V host in Azure ####
In this step, you'll create a suitable VM in Azure using PowerShell or an Azure Resource Manager template.  This VM will run Windows Server 2019 Datacenter, with the full desktop experience.  On this system, you'll enable the Hyper-V role and accompanying management tools, and create a NAT virtual switch to enable network communication between sandbox VMs, and out to the internet.

* [Start your deployment into Azure](/nested/steps/1a_NestedInAzure.md "Start your deployment into Azure")

#### Part 1b - Deploy Hyper-V on a physical system ####
In this step, on your existing system, that's running Windows Server 2016/2019 or Windows 10 Pro/Enterprise/Education, you'll enable the Hyper-V role and create a NAT virtual switch to enable network communication between sandbox VMs, and out to the internet.

* [Start your deployment on a physical system](/nested/steps/1b_NestedOnPhysical.md "Start your deployment on a physical system")

#### Part 2 - Deploy management infrastructure ####
In this step, you'll use **either the GUI, or PowerShell** to deploy and configure both a Windows Server 2019 domain controller, and a Windows 10 management VM on your Hyper-V host.  You'll create a Windows Server 2019 Active Directory domain, and join the Windows 10 management VM to this domain.  You'll also install the Windows Admin Center ahead of deploying the nested Azure Stack HCI cluster.


* [**Part 2a** - Deploy your management infrastructure with the GUI](/nested/steps/2a_ManagementInfraGUI.md "Deploy your management infrastructure with the GUI")
* [**Part 2b** - Deploy your management infrastructure with PowerShell](/nested/steps/2b_ManagementInfraPS.md "Deploy your management infrastructure with PowerShell")

#### Part 3 - Deploy nested Azure Stack HCI nodes ####
In this step, you'll use **either the GUI or PowerShell** to create a number of nested Azure Stack HCI nodes.

* [**Part 3a** - Create your nested Azure Stack HCI nodes with the GUI](/nested/steps/3a_AzSHCINodesGUI.md "Create your nested Azure Stack HCI nodes with the GUI")
* [**Part 3b** - Create your nested Azure Stack HCI nodes with PowerShell](/nested/steps/3b_AzSHCINodesPS.md "Create your nested Azure Stack HCI nodes with PowerShell")

#### Part 4 - Create your nested Azure Stack HCI cluster ####
In this step, you'll use the Windows Admin Center, on the Windows 10 management VM, to create the nested Azure Stack HCI cluster, and perform some post-deployment tasks to validate the configuration.

* [Create your nested Azure Stack HCI cluster](/universal/steps/4_AzSHCICluster.md "Create your nested Azure Stack HCI cluster")

#### Part 5 - Explore the management of your Azure Stack HCI environment ####
With your deployment completed, you're now ready to explore many of the management aspects within the Windows Admin Center.  To do so, please refer to our existing documentation, which showcases some of these aspects:

* [Explore Windows Admin Center](https://docs.microsoft.com/en-us/azure-stack/hci/get-started)
* [Manage virtual machines](https://docs.microsoft.com/en-us/azure-stack/hci/manage/vm)
* [Add servers for management](https://docs.microsoft.com/en-us/azure-stack/hci/manage/add-cluster)
* [Manage clusters](https://docs.microsoft.com/en-us/azure-stack/hci/manage/cluster)
* [Create storage volumes](https://docs.microsoft.com/en-us/azure-stack/hci/manage/create-volumes)
* [Monitor with with Azure Monitor](https://docs.microsoft.com/en-us/azure-stack/hci/manage/azure-monitor)
* [Integrate with Azure Site Recovery](https://docs.microsoft.com/en-us/azure-stack/hci/manage/azure-site-recovery)