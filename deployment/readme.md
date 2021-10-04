Evaluate Azure Stack HCI 20H2 in Azure
==============

As with any infrastructure technology, in order to test, validate and evaluate the technology, there's typically a requirement for hardware.  If you're fortunate enough to have multiple server-class pieces of hardware going spare (ideally hardware validated for Azure Stack HCI 20H2, found on our [Azure Stack HCI 20H2 Catalog](https://aka.ms/azurestackhcicatalog "Azure Stack HCI 20H2 Catalog")), you can certainly perform a more real-world evaluation of Azure Stack HCI 20H2.

For the purpose of this evaluation guide however, we'll be relying on **nested virtualization** to allow us to consolidate a full lab infrastructure, down onto a single Hyper-V host inside an Azure VM.

*************************

### Important Note - Production Deployments ###
The use of nested virtualization in this evaluation guide is aimed at providing flexibility for evaluating Azure Stack HCI 20H2. For **production** use, **Azure Stack HCI 20H2 should be deployed on validated physical hardware**, of which you can find a vast array of choices on the [Azure Stack HCI 20H2 Catalog](https://aka.ms/azurestackhcicatalog "Azure Stack HCI 20H2 Catalog").

*************************

Contents
-----------
- [Contents](#contents)
- [Nested Virtualization](#nested-virtualization)
- [Deployment of Azure Stack HCI 20H2 nested in Azure](#deployment-of-azure-stack-hci-20h2-nested-in-azure)
- [Deployment Workflow](#deployment-workflow)
- [Get started](#get-started)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)

Nested Virtualization
-----------
If you're not familiar with Nested Virtualization, at a high level, it allows a virtualization platform, such as Hyper-V, or VMware ESXi, to run virtual machines that, within those virtual machines, run a virtualization platform. It may be easier to think about this in an architectural view.

![Nested virtualization architecture](/deployment/media/nested_virt.png "Nested virtualization architecture")

As you can see from the graphic, at the base layer, you have your physical hardware, onto which you install a hypervisor. In this case, for our example, we're using Windows Server 2019 with the Hyper-V role enabled.  The hypervisor on the lowest level is considered L0 or the level 0 hypervisor.  On that physical host, you create a virtual machine, and into that virtual machine, you deploy an OS that itself, has a hypervisor enabled.  In this example, that 1st Virtualized Layer is running a **nested** Azure Stack HCI 20H2 operating system. This would be an L1 or level 1 hypervisor.  Finally, in our example, inside the Azure Stack HCI 20H2 OS, you create a virtual machine to run a workload.  This could in fact also contain a hypervisor, which would be known as the L2 or level 2 hypervisor, and so the process continues, with multiple levels of nested virtualization possible.

The use of nested virtualization opens up amazing opportunities for building complex scenarios on significantly reduced hardware footprints, however it shouldn't be seen as a substitute for real-world deployments, performance and scale testing etc.

Deployment of Azure Stack HCI 20H2 nested in Azure
-----------
For those of you who don't have multiple server-class pieces of hardware to test a full hyperconverged solution, this evaluation guide will detail using **nested virtualization** in Azure to evaluate Azure Stack HCI.

![Architecture diagram for Azure Stack HCI 20H2 nested in Azure](/deployment/media/nested_virt_arch_ga.png "Architecture diagram for Azure Stack HCI 20H2 nested in Azure")

In this configuration, you'll take advantage of the nested virtualization support provided within certain Azure VM sizes.  You'll deploy a single Azure VM running Windows Server 2019 to act as your main Hyper-V host - and through PowerShell DSC, this will be automatically configured with the relevant roles and features needed for this guide. It will also download all required binaries, and deploy 2 Azure Stack HCI 20H2 nodes, ready for clustering.

To reiterate, the whole configuration will run **inside the single Azure VM**.

Deployment Workflow
-----------

This guide will walk you through deploying a sandboxed infrastructure - the general flow will be as follows:

**Part 1 - Complete the pre-requisites - deploy your Azure VM**: In this step, you'll create a VM in Azure using an Azure Resource Manager template. This VM will run Windows Server 2019 Datacenter, with the full desktop experience. PowerShell DSC will automatically configure this VM with the appropriate roles and features, download the necessary binaries, and configure 2 Azure Stack HCI 20H2 nodes, ready for clustering.

**Part 2 - Configure your Azure Stack HCI 20H2 Cluster**: In this step, you'll use Windows Admin Center to deploy an Azure Stack HCI 20H2 cluster - along with a Cloud Witness, a Cluster Shared Volume, and finally, you'll register this cluster with Azure.

**Part 3 - Integrate Azure Stack HCI 20H2 with Azure**: In this step, you'll use Windows Admin Center to register your Azure Stack HCI Cluster with Azure and explore what's presented in the portal

**Part 4 - Explore the management of your Azure Stack HCI 20H2 environment**: With your deployment completed, you're now ready to explore many of the management aspects within the Windows Admin Center.

Get started
-----------

* [**Part 1** - Complete the prerequisites - deploy your Azure VM](/steps/1_DeployAzureVM.md "Complete the prerequisites - deploy your Azure VM")
* [**Part 2** - Configure your Azure Stack HCI 20H2 Cluster](/steps/2_DeployAzSHCI.md "Configure your Azure Stack HCI 20H2 Cluster")
* [**Part 3** - Integrate Azure Stack HCI 20H2 with Azure](/steps/3_AzSHCIIntegration.md "Integrate Azure Stack HCI 20H2 with Azure")
* [**Part 4** - Explore Azure Stack HCI Management](/steps/4_ExploreAzSHCI.md "Explore Azure Stack HCI Management")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI 20H2, Windows Admin Center, or the Azure Arc integration and experience, let us know!  We want to hear from you!  [Head on over to our Azure Stack HCI 20H2 UserVoice page](https://feedback.azure.com/forums/929833-azure-stack-hci "Azure Stack HCI 20H2 UserVoice"), where you can share your thoughts and ideas about making the technologies better.  If however, you have an issue that you'd like some help with, read on...

Raising issues
-----------
If you notice something is wrong with the evaluation guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If however, you're having a problem with Azure Stack HCI 20H2 **outside** of this evaluation guide, make sure you post to [our Microsoft Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Microsoft Q&A Forum"), where Microsoft experts and valuable members of the community will do their best to help you.