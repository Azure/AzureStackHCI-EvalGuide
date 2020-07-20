Azure Stack HCI - Evaluation Guide
==============

## Welcome to the Azure Stack HCI Evaluation Guide ##

In this guide, we'll walk you experiencing a number of the amazing capabilities within Azure Stack HCI, and set the foundation for you to explore in your own time.  If you've landed on this page, and you're still wondering what Azure Stack HCI is, Azure Stack HCI is a hyperconverged cluster solution that runs virtualized Windows and Linux workloads in a hybrid on-premises environment. Azure hybrid services enhance the cluster with capabilities such as cloud-based monitoring, site recovery, and backup, as well as a central view of all of your Azure Stack HCI deployments in the Azure portal. You can manage the cluster with your existing tools including Windows Admin Center, System Center, and PowerShell.

Initially based on Windows Server 2019, Azure Stack HCI is now a specialized OS, running on your hardware, delivered as an Azure service with a subscription-based licensing model and hybrid capabilities built-in. Although Azure Stack HCI is based on the same core operating system components as Windows Server, it's an entirely new product line focused on being the best virtualization host.

If you're interested in learning more about what Azure Stack HCI is, make sure you [check out the official documentation](https://docs.microsoft.com/en-us/azure-stack/hci/overview "What is Azure Stack HCI documentation"), before coming back to continue your evaluation experience.  We'll refer to the docs in various places in the guide, to help you build your knowledge of Azure Stack HCI.

This evaluation guide will walk you through standing up a sandboxed, isolated Azure Stack HCI environment using **nested virtualization**, and can run on a **single physical system**, such as a workstation, laptop, or server of you have one, or alternatively, you can run the whole configuration in Azure.  We'll go into more details for these paths, shortly.

The important takeaway here is, by following this guide, you'll lay down a solid foundation on to which you can explore additional Azure Stack HCI scenarios that will be documented as we move through the public preview program to the first release of Azure Stack HCI, so keep checking back for additional scenarios over time.

Evaluate Azure Stack HCI using Nested Virtualization
-----------

If you have a single physical system, which could be a laptop, desktop, or server, or you have no spare hardware at all, using **nested virtualization** would be a great approach to experiencing Azure Stack HCI.  You can get more details at the start of the path

![Nested path image](/media/nested.png "Nested virtualization path image")

[**Evaluate Azure Stack HCI using Nested Virtualization**](/nested/README.md "valuate Azure Stack HCI using Nested Virtualization")

### Important Note ###
The use of nested virtualization in this evaluation guide is aimed at providing flexibility for deploying Azure Stack HCI in a lab, or test environment. For **production** use, **Azure Stack HCI should be deployed on certified physical hardware**, of which you can find a vast array of choices on the [Azure Stack HCI Catalog](https://azure.com/hci "Azure Stack HCI Catalog").

### Contributing ###

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

### Issues ###
If you notice something is wrong, a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

### Legal Notices ###

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at http://go.microsoft.com/fwlink/?LinkID=254653.

Privacy information can be found at https://privacy.microsoft.com/en-us/

Microsoft and any contributors reserve all other rights, whether under their respective copyrights, patents, or trademarks, whether by implication, estoppel or otherwise.