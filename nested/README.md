Evaluate Azure Stack HCI using Nested Virtualization
==============

As with any infrastructure technology, in order to test, validate and evaluate the technology, there's typically a requirement for hardware.  If you're fortunate enough to have multiple server-class pieces of hardware going spare (ideally hardware certified for Azure Stack HCI, found on our [Azure Stack HCI Catalog](https://aka.ms/azurestackhcicatalog "Azure Stack HCI Catalog")), you can certainly perform a more real-world evaluation of Azure Stack HCI, which is something we'll be guiding you through separately, in the coming days, so stay tuned for that.

For the purpose of this evaluation guide however, we'll be relying on **nested virtualization** to allow us to consolidate a full lab infrastructure, down onto a single Hyper-V host, either on-prem, or in Azure.

### Important Note ###
The use of nested virtualization in this evaluation guide is aimed at providing flexibility for deploying Azure Stack HCI in a lab, or test environment. For **production** use, **Azure Stack HCI should be deployed on certified physical hardware**, of which you can find a vast array of choices on the [Azure Stack HCI Catalog](https://aka.ms/azurestackhcicatalog "Azure Stack HCI Catalog").

Nested Virtualization
-----------
If you're not familiar with Nested Virtualization, at a high level, it allows a virtualization platform, such as Hyper-V, or VMware ESXi, to run virtual machines that, within those virtual machines, run a virtualization platform. It may be easier to think about this in an architectural view.

![Nested virtualization architecture](/media/nested_virt.png "Nested virtualization architecture")

As you can see from the graphic, at the base layer, you have your physical hardware, onto which you install a hypervisor. In this case, for our example, we're using Windows Server 2019 with the Hyper-V role enabled.  The hypervisor on the lowest level is considered L0 or the level 0 hypervisor.  On that physical host, you create a virtual machine, and into that virtual machine, you deploy an OS that itself, has a hypervisor enabled.  In this example, that 1st Virtualized Layer is running a **nested** Azure Stack HCI operating system. This would be an L1 or level 1 hypervisor.  Finally, in our example, inside the Azure Stack HCI OS, you create a virtual machine to run a workload.  This could in fact also contain a hypervisor, which would be known as the L2 or level 2 hypervisor, and so the process continues, with multiple levels of nested virtualization possible.

The use of nested virtualization opens up amazing opportunities for building complex scenarios on significantly reduced hardware footprints, however it shouldn't be seen as a substitute for real-world deployments, performance and scale testing etc.

Deployment Options
-----------
For those of you who don't have multiple server-class pieces of hardware to test a full hyperconverged solution, this evaluation guide will detail 2 configurations, both using **nested virtualization**, that should be of interest.

### Deployment of Azure Stack HCI nested in Azure ###

![Architecture diagram for Azure Stack HCI nested in Azure](/media/nested_virt_arch.png "Architecture diagram for Azure Stack HCI nested in Azure")

In this configuration, you'll take advantage of the nested virtualization support provided within certain Azure VM sizes.  You'll first deploy a single Azure VM running Windows Server 2019.  Inside this VM, you'll enable the Hyper-V role, and deploy a Windows Server 2019 domain controller VM, along with a management VM, running Windows 10 Enterprise. This management VM will also run the Windows Admin Center.  Finally, you'll deploy a nested Azure Stack HCI cluster, with a minimum of 2 nodes, however the number of nodes will be based on the size of your Azure VM.

To reiterate, the whole configuration (Domain Controller VM, Management VM and Azure Stack HCI Nodes) will run inside the single Azure VM.

### Deployment of Azure Stack HCI nested on a physical system ###

![Architecture diagram for Azure Stack HCI nested on a physical system](/media/nested_virt_physical.png "Architecture diagram for Azure Stack HCI nested on a physical system")

In this configuration, you'll again take advantage of nested virtualization, but in this case, you'll deploy the whole solution on a single desktop/laptop/server.  On your physical system, you'll run either Windows Server 2016/2019 or Windows 10 Pro/Enterprise/Education, with the Hyper-V role enabled.  On Hyper-V, you'll deploy a sandbox infrastructure, consisting of a Windows Server 2019 domain controller VM, a management VM running Windows 10 Enterprise, and a nested Azure Stack HCI cluster.

#### Important note for systems with AMD CPUs ####
For those of you wanting to evaluate Azure Stack HCI in a nested configuration, with **AMD-based systems**, the only way this is currently possible is to use **Windows 10 Insider Build 19636 or newer** as your Hyper-V host. Your system should have AMD's 1st generation Ryzen/Epyc or newer CPUs. You can get more information on [nested virtualization on AMD here](https://techcommunity.microsoft.com/t5/virtualization/amd-nested-virtualization-support/ba-p/1434841 "Nested virtualization on AMD-based systems").

If you can't run the Windows 10 Insider builds on your AMD-based system, it may be a better approach to [deploy in Azure instead](/nested/steps/1a_NestedInAzure.md "Deploy in Azure").  We'll be sure to update this guidance as and when new updates to nested virtualization support become available.

Deployment Workflow
-----------
This guide will walk you through deploying a sandboxed Azure Stack HCI infrastructure.  Many of the steps will be universal, regardless of whether you are deploying in Azure, or deploying on a single physical system, however to accommodate different preferences, we've provided paths for those of you who prefer PowerShell, or GUI (Graphical User Interface, such as Hyper-V Manager, Server Manager etc)-based deployments.

The general flow will be as follows:

![Evaluation guide workflow using nested virtualization](/media/flow_chart_paths.png "Evaluation guide workflow using nested virtualization")

#### Part 1a - Deploy Hyper-V host in Azure ####
In this step, you'll create a suitable VM in Azure using PowerShell or an Azure Resource Manager template.  This VM will run Windows Server 2019 Datacenter, with the full desktop experience.  On this system, you'll enable the Hyper-V role and accompanying management tools, and create a NAT virtual switch to enable network communication between sandbox VMs, and out to the internet.

* [**Part 1a** - Start your deployment into Azure](/nested/steps/1a_NestedInAzure.md "Start your deployment into Azure")

#### Part 1b - Deploy Hyper-V on a physical system ####
In this step, on your existing system, that's running Windows Server 2016/2019 or Windows 10 Pro/Enterprise/Education, you'll enable the Hyper-V role and create a NAT virtual switch to enable network communication between sandbox VMs, and out to the internet.

* [**Part 1b** - Start your deployment on a physical system](/nested/steps/1b_NestedOnPhysical.md "Start your deployment on a physical system")

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

* [**Part 4** - Create your nested Azure Stack HCI cluster](/nested/steps/4_AzSHCICluster.md "Create your nested Azure Stack HCI cluster")

#### Part 5 - Explore the management of your Azure Stack HCI environment ####
With your deployment completed, you're now ready to explore many of the management aspects within the Windows Admin Center.

* [**Part 5** - Explore the management of your Azure Stack HCI environment](/nested/steps/5_ExploreAzSHCI.md "Explore the management of your Azure Stack HCI environment")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI, Windows Admin Center, or the Azure Arc integration and experience, let us know!  We want to hear from you!  [Head on over to our Azure Stack HCI UserVoice page](https://feedback.azure.com/forums/929833-azure-stack-hci "Azure Stack HCI UserVoice"), where you can share your thoughts and ideas about making the technologies better.  If however, you have an issue that you'd like some help with, read on...

Raising issues
-----------
If you notice something is wrong withthe evaluation guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If however, you're having a problem with Azure Stack HCI **outside** of this evaluation guide, make sure you post to [our Microsoft Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Microsoft Q&A Forum"), where Microsoft experts and valuable members of the Azure Stack HCI community will do their best to help you.