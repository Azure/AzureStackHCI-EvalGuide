Azure Stack HCI - Evaluation Guide
==============

In this guide, we'll walk you through deploying Azure Stack HCI, along with an accompanying management infrastructure, all in an isolated sandbox.  By following this guide, you'll lay down a solid foundation on to which you can explore additional Azure Stack HCI scenarios that will be documented as we move through the public preview program to the first release of Azure Stack HCI.

As with any infrastructure technology, in order to test, validate and evaluate the technology, there's typically a requirement for hardware.  If you're fortunate enough to have multiple server-class pieces of hardware going spare (ideally hardware certified for Windows Server 2019 found on our [Windows Server Catalog](https://azure.com/hci "Azure Stack HCI Catalog")), you can certainly perform a more real-world evaluation of Azure Stack HCI.

For the purpose of this evaluation guide however, we'll be relying on **nested virtualization** to allow us to consolidate a full lab infrastructure, down onto a single Hyper-V host.

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
This guide will walk you through deploying a sandboxed Azure Stack HCI infrastructure.  Many of the steps will be universal, regardless of whether you are deploying in Azure, or deploying on a single physical system.

The general flow will be as follows:

![Evaluation guide workflow](/media/flow_chart.png)

#### Part 1a - Deploy Hyper-V host in Azure ####
In this step, you'll create a suitable VM in Azure using PowerShell or an Azure Resource Manager template.  This VM will run Windows Server 2019 Datacenter, with the full desktop experience.  On this system, you'll enable the Hyper-V role and accompanying management tools, and create a NAT virtual switch to enable network communication between sandbox VMs, and out to the internet.

[Start your deployment into Azure](/steps/1a_NestedInAzure.md "Start your deployment into Azure")

#### Part 1b - Deploy Hyper-V on a physical system ####
In this step, on your existing system, that's running Windows Server 2016/2019 or Windows 10 Pro/Enterprise/Education, you'll enable the Hyper-V role and create a NAT virtual switch to enable network communication between sandbox VMs, and out to the internet.

[Start your deployment on a physical system](/steps/1b_NestedOnPhysical.md "Start your deployment on a physical system")

#### Part 2 - Deploy management infrastructure ####
In this step, you'll use PowerShell to deploy and configure both a Windows Server 2019 domain controller, and a Windows 10 management VM on your Hyper-V host.  Again with PowerShell, you'll create a Windows Server 2019 Active Directory domain, and join the Windows 10 management VM to this domain.  You'll also install the Windows Admin Center ahead of deploying the nested Azure Stack HCI cluster.

[Deploy your management infrastructure](/steps/2_ManagementInfra.md "Deploy your management infrastructure")

#### Part 3 - Deploy nested Azure Stack HCI nodes ####
In this step, you'll use PowerShell to create a number of nested Azure Stack HCI nodes.

[Create your nested Azure Stack HCI nodes](/steps/3_AzSHCINodes.md "Create your nested Azure Stack HCI nodes")

#### Part 4 - Create your nested Azure Stack HCI cluster ####
In this step, you'll use the Windows Admin Center, on the Windows 10 management VM, to create the nested Azure Stack HCI cluster, and perform some post-deployment tasks to validate the configuration.

[Create your nested Azure Stack HCI cluster](/steps/4_AzSHCICluster.md "Create your nested Azure Stack HCI cluster")

#### Part 5 - Explore the management of your Azure Stack HCI environment ####
With your deployment completed, you're now ready to explore many of the management aspects within the Windows Admin Center.  To do so, please refer to our existing documentation, which showcases some of these aspects:

* [Explore Windows Admin Center](https://docs.microsoft.com/en-us/azure-stack/hci/get-started)
* [Manage virtual machines](https://docs.microsoft.com/en-us/azure-stack/hci/manage/vm)
* [Add servers for management](https://docs.microsoft.com/en-us/azure-stack/hci/manage/add-cluster)
* [Manage clusters](https://docs.microsoft.com/en-us/azure-stack/hci/manage/cluster)
* [Create storage volumes](https://docs.microsoft.com/en-us/azure-stack/hci/manage/create-volumes)
* [Monitor with with Azure Monitor](https://docs.microsoft.com/en-us/azure-stack/hci/manage/azure-monitor)
* [Integrate with Azure Site Recovery](https://docs.microsoft.com/en-us/azure-stack/hci/manage/azure-site-recovery)

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

# Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content
in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode),
see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the
[LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation
may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries.
The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks.
Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all other rights, whether under their respective copyrights, patents,
or trademarks, whether by implication, estoppel or otherwise.