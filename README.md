Azure Stack HCI - Evaluation Guide
==============

**Welcome to the Azure Stack HCI Evaluation Guide**

In this guide, we'll walk you through evaluating Azure Stack HCI.

As part of the guide, there will be 2 main paths for evaluation that you can choose from.

* The first path makes an assumption that you have **at least 2 suitable physical servers** that you could use for the evaluation, and that you have an Active Directory domain already in place.  If that's not the case, and you'd prefer to test, validate and evaluate Azure Stack HCI in an isolated sandbox, the second path may be for you.
* The second path guides you through standing up a sandboxed, isolated environment using **nested virtualization**, and can run on a **single physical system**, such as a workstation, laptop, or server of you have one, or alternatively, you can run the whole configuration in Azure.  We'll go into more details for these paths, shortly.

Regardless of which path you choose, by following this guide, you'll lay down a solid foundation on to which you can explore additional Azure Stack HCI scenarios that will be documented as we move through the public preview program to the first release of Azure Stack HCI.

Choose your path
-----------
As mentioned above, there are 2 paths to choose from, for this evaluation guide.  At a high level, one of these paths will require 2 or more physical servers for the configuration, along with an Active Directory domain. The second path, uses nested virtualization, and can be deployed more flexibly, either on-premises or in Azure.

| Evaluate Azure Stack HCI on 2+ physical servers | Evaluate Azure Stack HCI using Nested Virtualization |
|---|---|
| ![Physical path image](/media/physical.png "Physical path image")  | ![Nested path image](/media/nested.png "Physical path image")   |
| Physical | Nested |



### Important Note ###
The use of nested virtualization in this evaluation guide is aimed at providing flexibility for deploying Azure Stack HCI in a lab, or test environment. For **production** use, **Azure Stack HCI should be deployed on certified physical hardware**, of which you can find a vast array of choices on the [Azure Stack HCI Catalog](https://azure.com/hci "Azure Stack HCI Catalog").



### Contributing ###

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

### Legal Notices ###

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