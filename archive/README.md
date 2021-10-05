Evaluate Azure Stack HCI 20H2 using Nested Virtualization
==============

Important Note
-----------

***********************
This section of the eval guide has been **archived**. If you're looking to evaluate Azure Stack HCI in an Azure VM, the best approach is to use the latest version of the guidance, which you can find here:

* [**Part 1** - Complete the prerequisites - deploy your Azure VM](/deployment/steps/1_DeployAzureVM.md "Complete the prerequisites - deploy your Azure VM")
* [**Part 2** - Configure your Azure Stack HCI 20H2 Cluster](/deployment/steps/2_DeployAzSHCI.md "Configure your Azure Stack HCI 20H2 Cluster")
* [**Part 3** - Integrate Azure Stack HCI 20H2 with Azure](/deployment/steps/3_AzSHCIIntegration.md "Integrate Azure Stack HCI 20H2 with Azure")
* [**Part 4** - Explore Azure Stack HCI Management](/deployment/steps/4_ExploreAzSHCI.md "Explore Azure Stack HCI Management")

If you wish to evaluate Azure Stack HCI on a **single physical system**, you can use the guidance below.

***********************

As with any infrastructure technology, in order to test, validate and evaluate the technology, there's typically a requirement for hardware.  If you're fortunate enough to have multiple server-class pieces of hardware going spare (ideally hardware validated for Azure Stack HCI 20H2, found on our [Azure Stack HCI 20H2 Catalog](https://aka.ms/azurestackhcicatalog "Azure Stack HCI 20H2 Catalog")), you can certainly perform a more real-world evaluation of Azure Stack HCI 20H2.

For the purpose of this evaluation guide however, we'll be relying on **nested virtualization** to allow us to consolidate a full lab infrastructure, down onto a single Hyper-V host, either on-prem, or in Azure. If you do have spare physical hardware, you should be able to follow along and use your own hardware - you can just skip the nested-specific steps.

### Important Note - Production Deployments ###
The use of nested virtualization in this evaluation guide is aimed at providing flexibility for deploying Azure Stack HCI 20H2 in a lab, or test environment. For **production** use, **Azure Stack HCI 20H2 should be deployed on validated physical hardware**, of which you can find a vast array of choices on the [Azure Stack HCI 20H2 Catalog](https://aka.ms/azurestackhcicatalog "Azure Stack HCI 20H2 Catalog").

Contents
-----------
- [Important Note](#important-note)
- [Contents](#contents)
- [Nested Virtualization](#nested-virtualization)
- [Deployment](#deployment)
- [Deployment Workflow](#deployment-workflow)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)

Nested Virtualization
-----------
If you're not familiar with Nested Virtualization, at a high level, it allows a virtualization platform, such as Hyper-V, or VMware ESXi, to run virtual machines that, within those virtual machines, run a virtualization platform. It may be easier to think about this in an architectural view.

![Nested virtualization architecture](/archive/media_virt.png "Nested virtualization architecture")

As you can see from the graphic, at the base layer, you have your physical hardware, onto which you install a hypervisor. In this case, for our example, we're using Windows Server 2019 with the Hyper-V role enabled.  The hypervisor on the lowest level is considered L0 or the level 0 hypervisor.  On that physical host, you create a virtual machine, and into that virtual machine, you deploy an OS that itself, has a hypervisor enabled.  In this example, that 1st Virtualized Layer is running a **nested** Azure Stack HCI 20H2 operating system. This would be an L1 or level 1 hypervisor.  Finally, in our example, inside the Azure Stack HCI 20H2 OS, you create a virtual machine to run a workload.  This could in fact also contain a hypervisor, which would be known as the L2 or level 2 hypervisor, and so the process continues, with multiple levels of nested virtualization possible.

The use of nested virtualization opens up amazing opportunities for building complex scenarios on significantly reduced hardware footprints, however it shouldn't be seen as a substitute for real-world deployments, performance and scale testing etc.

Deployment
-----------
For those of you who don't have multiple server-class pieces of hardware to test a full hyperconverged solution, this evaluation guide will detail how you can deploy on a single physical system, using **nested virtualization**.

### Deployment of Azure Stack HCI 20H2 nested on a physical system ###

![Architecture diagram for Azure Stack HCI 20H2 nested on a physical system](/archive/media_virt_physical_ga.png "Architecture diagram for Azure Stack HCI 20H2 nested on a physical system")

In this configuration, you'll again take advantage of nested virtualization, but in this case, you'll deploy the whole solution on a single desktop/laptop/server.  On your physical system, you'll run either Windows Server 2016/2019 or Windows 10 Pro/Enterprise/Education, with the Hyper-V role enabled.  On Hyper-V, you'll deploy a sandbox infrastructure, consisting of a Windows Server 2019 domain controller VM, a management VM running Windows 10 Enterprise, and a nested Azure Stack HCI 20H2 cluster.

#### Important note for systems with AMD CPUs ####
For those of you wanting to evaluate Azure Stack HCI 20H2 in a nested configuration, with **AMD-based systems**, the only way this is currently possible is to use **Windows 10 Insider Build 19636 or newer** as your Hyper-V host. Your system should have AMD's 1st generation Ryzen/Epyc or newer CPUs. You can get more information on [nested virtualization on AMD here](https://techcommunity.microsoft.com/t5/virtualization/amd-nested-virtualization-support/ba-p/1434841 "Nested virtualization on AMD-based systems").

If you can't run the Windows 10 Insider builds on your AMD-based system, it may be a better approach to [deploy in Azure instead](/steps/1b_NestedInAzure.md "Deploy in Azure").  We'll be sure to update this guidance as and when new updates to nested virtualization support become available.

Deployment Workflow
-----------
This guide will walk you through deploying a sandboxed Azure Stack HCI 20H2 infrastructure. To accommodate different preferences, we've provided paths for those of you who prefer PowerShell, or GUI (Graphical User Interface, such as Hyper-V Manager, Server Manager etc)-based deployments.

The general flow will be as follows:

![Evaluation guide workflow using nested virtualization](/archive/media/flow_chart_ga.png "Evaluation guide workflow using nested virtualization")

#### Part 1 - Deploy Hyper-V on a physical system ####
In this step, on your existing system, that's running Windows Server 2016/2019 or Windows 10 Pro/Enterprise/Education, you'll enable the Hyper-V role and create a NAT virtual switch to enable network communication between sandbox VMs, and out to the internet.

* [**Part 1a** - Start your deployment on a physical system](/steps/1_NestedOnPhysical.md "Start your deployment on a physical system")

#### Part 2 - Deploy management infrastructure ####
In this step, you'll use **either the GUI, or PowerShell** to deploy and configure both a Windows Server 2019 domain controller, and a Windows 10 management VM on your Hyper-V host.  You'll create a Windows Server 2019 Active Directory domain, and join the Windows 10 management VM to this domain.  You'll also install the Windows Admin Center ahead of deploying the nested Azure Stack HCI 20H2 cluster.

* [**Part 2a** - Deploy your management infrastructure with the GUI](/steps/2a_ManagementInfraGUI.md "Deploy your management infrastructure with the GUI")
* [**Part 2b** - Deploy your management infrastructure with PowerShell](/steps/2b_ManagementInfraPS.md "Deploy your management infrastructure with PowerShell")

#### Part 3 - Deploy nested Azure Stack HCI 20H2 nodes ####
In this step, you'll use **either the GUI or PowerShell** to create a number of nested Azure Stack HCI 20H2 nodes.

* [**Part 3a** - Create your nested Azure Stack HCI 20H2 nodes with the GUI](/steps/3a_AzSHCINodesGUI.md "Create your nested Azure Stack HCI 20H2 nodes with the GUI")
* [**Part 3b** - Create your nested Azure Stack HCI 20H2 nodes with PowerShell](/steps/3b_AzSHCINodesPS.md "Create your nested Azure Stack HCI 20H2 nodes with PowerShell")

#### Part 4 - Create your nested Azure Stack HCI 20H2 cluster ####
In this step, you'll use the Windows Admin Center, on the Windows 10 management VM, to create the nested Azure Stack HCI 20H2 cluster, and perform some post-deployment tasks to validate the configuration.

* [**Part 4** - Create your nested Azure Stack HCI 20H2 cluster](/steps/4_AzSHCICluster.md "Create your nested Azure Stack HCI 20H2 cluster")

#### Part 5 - Explore the management of your Azure Stack HCI 20H2 environment ####
With your deployment completed, you're now ready to explore many of the management aspects within the Windows Admin Center.

* [**Part 5** - Explore the management of your Azure Stack HCI 20H2 environment](/steps/5_ExploreAzSHCI.md "Explore the management of your Azure Stack HCI 20H2 environment")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI 20H2, Windows Admin Center, or the Azure Arc integration and experience, let us know!  We want to hear from you!  [Head on over to our Azure Stack HCI 20H2 UserVoice page](https://feedback.azure.com/forums/929833-azure-stack-hci "Azure Stack HCI 20H2 UserVoice"), where you can share your thoughts and ideas about making the technologies better.  If however, you have an issue that you'd like some help with, read on...

Raising issues
-----------
If you notice something is wrong with the evaluation guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If however, you're having a problem with Azure Stack HCI 20H2 **outside** of this evaluation guide, make sure you post to [our Microsoft Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Microsoft Q&A Forum"), where Microsoft experts and valuable members of the community will do their best to help you.