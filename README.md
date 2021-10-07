Azure Stack HCI 20H2 - Evaluation Guide
==============

Welcome to the Azure Stack HCI 20H2 Evaluation Guide
-----------

In this guide, we'll walk you experiencing a number of the amazing capabilities within [Azure Stack HCI 20H2](https://azure.microsoft.com/en-us/products/azure-stack/hci/ "link to the Azure Stack HCI 20H2 landing page"), and set the foundation for you to explore in your own time.  You'll cover aspects such as:

* Building a hyperconverged Azure Stack HCI cluster using Windows Admin Center
* Configuring a cloud witness
* Registering Azure Stack HCI 20H2 with Azure
* Creating storage volumes and deploying a VM

Contents
-----------
- [Welcome to the Azure Stack HCI 20H2 Evaluation Guide](#welcome-to-the-azure-stack-hci-20h2-evaluation-guide)
- [Contents](#contents)
- [What is Azure Stack HCI 20H2?](#what-is-azure-stack-hci-20h2)
- [Why follow this guide?](#why-follow-this-guide)
- [Interested in AKS on Azure Stack HCI?](#interested-in-aks-on-azure-stack-hci)
- [Evaluating in Azure](#evaluating-in-azure)
- [Nested Virtualization](#nested-virtualization)
- [Deployment of Azure Stack HCI 20H2 nested in Azure](#deployment-of-azure-stack-hci-20h2-nested-in-azure)
- [Deployment Workflow](#deployment-workflow)
- [Get started](#get-started)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)
- [Contributions & Legal](#contributions--legal)

What is Azure Stack HCI 20H2?
-----------

If you've landed on this page, and you're still wondering what Azure Stack HCI 20H2 is, Azure Stack HCI 20H2 is a hyperconverged cluster solution that runs virtualized Windows and Linux workloads in a hybrid on-premises environment. Azure hybrid services enhance the cluster with capabilities such as cloud-based monitoring, site recovery, and backup, as well as a central view of all of your Azure Stack HCI 20H2 deployments in the Azure portal. You can manage the cluster with your existing tools including Windows Admin Center, System Center, and PowerShell.

Initially based on Windows Server 2019, Azure Stack HCI 20H2 is now a specialized OS, running on your hardware, delivered as an Azure service with a subscription-based licensing model and hybrid capabilities built-in. Although Azure Stack HCI 20H2 is based on the same core operating system components as Windows Server, it's an entirely new product line focused on being the best virtualization host.

If you're interested in learning more about what Azure Stack HCI 20H2 is, make sure you [check out the official documentation](https://docs.microsoft.com/en-us/azure-stack/hci/overview "What is Azure Stack HCI 20H2 documentation"), before coming back to continue your evaluation experience.  We'll refer to the docs in various places in the guide, to help you build your knowledge of Azure Stack HCI 20H2.

Why follow this guide?
-----------

This evaluation guide will walk you through standing up a sandboxed, isolated Azure Stack HCI 20H2 environment using **nested virtualization** in a **single Azure VM**. The important takeaway here is, by following this guide, you'll lay down a solid foundation on to which you can explore additional Azure Stack HCI 20H2 scenarios in the future, so keep checking back for additional scenarios over time.

Interested in AKS on Azure Stack HCI?
-----------
If you're interested in evaluating AKS on Azure Stack HCI (AKS-HCI), and you're planning to evaluate all the solutions using nested virtualization in Azure, it's certainly tempting to run AKS-HCI on top of an Azure Stack HCI 20H2 nested cluster in an Azure VM, however we **strongly discourage** this approach due to the performance impact of multiple layers of nested virtualization. The recommended approach to test AKS-HCI in an Azure VM using [the official AKS on Azure Stack HCI eval guide](https://aka.ms/aks-hci-evalonazure "AKS on Azure Stack HCI eval guide").

Evaluating in Azure
-----------

As with any infrastructure technology, in order to test, validate and evaluate the technology, there's typically a requirement for hardware. If you're fortunate enough to have multiple server-class pieces of hardware going spare (ideally hardware validated for Azure Stack HCI 20H2, found on our [Azure Stack HCI 20H2 Catalog](https://aka.ms/azurestackhcicatalog "Azure Stack HCI 20H2 Catalog")), you can certainly perform a more real-world evaluation of Azure Stack HCI 20H2.

For the purpose of this evaluation guide however, we'll be relying on **nested virtualization** to allow us to consolidate a full lab infrastructure, down **onto a single Hyper-V host inside an Azure VM**.

*************************

### Important Note - Production Deployments ###
The use of nested virtualization in this evaluation guide is aimed at providing flexibility for evaluating Azure Stack HCI 20H2. For **production** use, **Azure Stack HCI 20H2 should be deployed on validated physical hardware**, of which you can find a vast array of choices on the [Azure Stack HCI 20H2 Catalog](https://aka.ms/azurestackhcicatalog "Azure Stack HCI 20H2 Catalog").

*************************

Nested Virtualization
-----------
If you're not familiar with Nested Virtualization, at a high level, it allows a virtualization platform, such as Hyper-V, or VMware ESXi, to run virtual machines that, within those virtual machines, run a virtualization platform. It may be easier to think about this in an architectural view.

![Nested virtualization architecture](/deployment/media/nested_virt.png "Nested virtualization architecture")

As you can see from the graphic, at the base layer, you have your physical hardware, onto which you install a hypervisor. In this case, for our example, we're using Windows Server 2019 with the Hyper-V role enabled.  The hypervisor on the lowest level is considered L0 or the level 0 hypervisor.  On that physical host, you create a virtual machine, and into that virtual machine, you deploy an OS that itself, has a hypervisor enabled.  In this example, that 1st Virtualized Layer is running a **nested** Azure Stack HCI 20H2 operating system. This would be an L1 or level 1 hypervisor.  Finally, in our example, inside the Azure Stack HCI 20H2 OS, you create a virtual machine to run a workload.  This could in fact also contain a hypervisor, which would be known as the L2 or level 2 hypervisor, and so the process continues, with multiple levels of nested virtualization possible.

The use of nested virtualization opens up amazing opportunities for building complex scenarios on significantly reduced hardware footprints, however it shouldn't be seen as a substitute for real-world deployments, performance and scale testing etc.

Deployment of Azure Stack HCI 20H2 nested in Azure
-----------
For those of you who don't have multiple server-class pieces of hardware to test a full hyperconverged solution, this evaluation guide will detail using **nested virtualization** in Azure to evaluate Azure Stack HCI.

![Architecture diagram for Azure Stack HCI 20H2 nested in Azure](/deployment/media/nested_virt_arch_ga_oct21.png "Architecture diagram for Azure Stack HCI 20H2 nested in Azure")

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

* [**Part 1** - Complete the prerequisites - deploy your Azure VM](/deployment/steps/1_DeployAzureVM.md "Complete the prerequisites - deploy your Azure VM")
* [**Part 2** - Configure your Azure Stack HCI 20H2 Cluster](/deployment/steps/2_DeployAzSHCI.md "Configure your Azure Stack HCI 20H2 Cluster")
* [**Part 3** - Integrate Azure Stack HCI 20H2 with Azure](/deployment/steps/3_AzSHCIIntegration.md "Integrate Azure Stack HCI 20H2 with Azure")
* [**Part 4** - Explore Azure Stack HCI Management](/deployment/steps/4_ExploreAzSHCI.md "Explore Azure Stack HCI Management")

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI 20H2, Windows Admin Center, or the Azure Arc integration and experience, let us know!  We want to hear from you!  [Head on over to our Azure Stack HCI 20H2 UserVoice page](https://feedback.azure.com/forums/929833-azure-stack-hci "Azure Stack HCI 20H2 UserVoice"), where you can share your thoughts and ideas about making the technologies better.  If however, you have an issue that you'd like some help with, read on... 

Raising issues
-----------
If you notice something is wrong with the evaluation guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If however, you're having a problem with Azure Stack HCI 20H2 **outside** of this evaluation guide, make sure you post to [our Microsoft Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Microsoft Q&A Forum"), where Microsoft experts and valuable members of the community will do their best to help you.

Contributions & Legal
-----------

### Contributing ###
This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

### Legal Notices ###

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all other rights, whether under their respective copyrights, patents, or trademarks, whether by implication, estoppel or otherwise.