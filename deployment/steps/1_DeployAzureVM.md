Deploy your Azure VM (Prerequisites)
==============
Overview
-----------
With the introduction of [nested virtualization support in Azure](https://azure.microsoft.com/en-us/blog/nested-virtualization-in-azure/ "Nested virtualization announcement blog post") back in 2017, Microsoft opened the door to a number of new and interesting scenarios.  Nested virtualization in Azure is particularly useful for validating configurations that would require additional hardware in your environment, such as running Hyper-V hosts and clusters.

In this guide, you'll walk through the steps to stand up an Azure Stack HCI 20H2 and AKS on Azure Stack HCI infrastructure. At a high level, this will consist of the following:

* Deploy an Azure VM, running Windows Server 2019, to act as your main Hyper-V host - this will be automatically configured with the relevant roles and features needed for your workshop. It will also download all required binaries, and deploy 2 Azure Stack HCI 20H2 nodes, ready for clustering.
* Deploy the AKS on Azure Stack HCI management cluster
* Deploy the AKS on Azure Stack HCI target clusters, for running workloads

Contents
-----------
- [Overview](#overview)
- [Contents](#contents)
- [Architecture](#architecture)
- [Important Note](#important-note)
- [Get an Azure subscription](#get-an-azure-subscription)
- [Azure VM Size Considerations](#azure-vm-size-considerations)
- [Deploying the Azure VM](#deploying-the-azure-vm)
- [Access your Azure VM](#access-your-azure-vm)
- [Please Read - Finish Setup](#please-read---finish-setup)
- [Next Steps](#next-steps)
- [Troubleshooting](#troubleshooting)
- [Product improvements](#product-improvements)
- [Raising issues](#raising-issues)

Architecture
-----------

From an architecture perspective, the following graphic showcases the different layers and interconnections between the different components:

![Architecture diagram for AKS on Azure Stack HCI in Azure](/media/nested_virt_arch_ga.png "Architecture diagram for AKS on Azure Stack HCI in Azure")

The outer box represents the Azure Resource Group, which will contain all of the artifacts deployed in Azure, including the virtual machine itself, and accompaying network adapter, storage and so on. You'll deploy an Azure VM running Windows Server 2019 Datacenter. On top of this, you'll run the following:

* A **2-node Azure Stack HCI 20H2 cluster**.
* An **AKS-HCI infrastructure**, which includes a management cluster (kubernetes virtual appliance) and a target cluster, which is where you ultimately run your applications.

These will de deployed as 2 separate environments within the same Azure VM. In a production environment, you would run AKS-HCI **on top of** Azure Stack HCI, but in this nested environment, the performance of the multiple levels of nesting can have a negative impact, so in this case, they will be deployed side by side for evaluation.

If you're interested in learning more about the building blocks of the Kubernetes infrastructure, you can [read more here](https://docs.microsoft.com/en-us/azure-stack/aks-hci/kubernetes-concepts "Kubernetes core concepts for Azure Kubernetes Service on Azure Stack HCI").

Important Note
-----------
The steps outlined in this guide are **specific to running inside an Azure VM**, running on a single Windows Server 2019 OS. If you plan to use these steps in an alternative environment, such as one nested/physical on-premises, the steps may differ and certain procedures may not work. If that is the case, please refer to the official documentation.

Get an Azure subscription
-----------
To evaluate Azure Stack HCI 20H2 and AKS on Azure Stack HCI in Azure, you'll need an Azure subscription.  If you already have one provided by your company, you can skip this step, but if not, you have a couple of options.

The first option would apply to Visual Studio subscribers, where you can use Azure at no extra charge. With your monthly Azure DevTest individual credit, Azure is your personal sandbox for dev/test. You can provision virtual machines, cloud services, and other Azure resources. Credit amounts vary by subscription level, but if you manage your Hybrid Host VM run-time efficiently, you can test the scenario well within your subscription limits.

The second option would be to sign up for a [free trial](https://azure.microsoft.com/en-us/free/ "Azure free trial link"), which gives you $200 credit for the first 30 days, and 12 months of popular services for free. The credit for the first 30 days will give you plenty of headroom to validate AKS on Azure Stack HCI.

You can also use this same Azure subscription to integrate with Azure Arc, once the deployment is completed.

Azure VM Size Considerations
-----------

Now, before you deploy the VM in Azure, it's important to choose a **size** that's appropriate for your needs for this workshop, along with a preferred region. It's highly recommended to choose a VM size that has **at least 64GB memory**. This deployment, by default, recommends using a **Standard_E16s_v4**, which is a memory-optimized VM size, with 16 vCPUs, 128 GiB memory, and no temporary SSD storage. The OS drive will be the default 127 GiB in size and the Azure VM deployment will add an additional 8 data disks (32 GiB each by default), so you'll have around 256GiB to deploy Azure Stack HCI 20H2 and AKS on Azure Stack HCI. You can also make this larger after deployment, if you wish.

This is just one VM size that we recommend - you can adjust accordingly to suit your needs, even after deployment. The point here is, think about how large an Azure Stack HCI 20H2 and AKS on Azure Stack HCI infrastructure you'd like to deploy inside this Azure VM, and select an Azure VM size from there. Some potential examples would be:

**D-series VMs (General purpose) with at least 64GB memory**

| Size | vCPU | Memory: GiB | Temp storage (SSD): GiB | Premium Storage |
|:--|---|---|---|---|
| Standard_D16s_v3  | 16  | 64 | 128 | Yes |
| Standard_D16_v4  | 16  | 64 | 0 | No |
| **Standard_D16s_v4**  | **16**  | **64**  | **0**  | **Yes** |
| Standard_D16d_v4 | 16 | 64  | 600 | No |
| Standard_D16ds_v4 | 16 | 64 | 600 | Yes |

For reference, the Standard_D16s_v4 VM size costs approximately US $0.77 per hour based on East US region, under a Visual Studio subscription.

**E-series VMs (Memory optimized - Recommended for this Hybrid Workshop) with at least 64GB memory**

| Size | vCPU | Memory: GiB | Temp storage (SSD): GiB | Premium Storage |
|:--|---|---|---|---|
| Standard_E8s_v3  | 8  | 64  | 128  | Yes  |
| Standard_E8_v4  | 8  | 64  | 0  | No |
| **Standard_E8s_v4**  | **8**  | **64**  | **0**  | **Yes** |
| Standard_E8d_v4 | 8 | 64  | 300  | No |
| Standard_E8ds_v4 | 8 | 64 | 300  | Yes |
| Standard_E16s_v3  | 16  | 128 | 256 | Yes |
| **Standard_E16s_v4**  | **16**  | **128**  | **0**  | **Yes** |
| Standard_E16d_v4 | 16 | 128  | 600 | No |
| Standard_E16ds_v4 | 16 | 128 | 600 | Yes |

For reference, the Standard_E8s_v4 VM size costs approximately US $0.50 per hour based on East US region, under a Visual Studio subscription.

**NOTE 1** - A number of these VM sizes include temp storage, which offers high performance, but is not persistent through reboots, Azure host migrations and more. It's therefore advisable, that if you are going to be running the Azure VM for a period of time, but shutting down frequently, that you choose a VM size with no temp storage, and ensure your nested VMs are placed on the persistent data drive within the OS.

**NOTE 2** - It's strongly recommended that you choose a VM size that supports **premium storage** - when running nested virtual machines, increasing the number of available IOPS can have a significant impact on performance, hence choosing **premium storage** over Standard HDD or Standard SSD, is strongly advised. Refer to the table above to make the most appropriate selection.

**NOTE 3** - Please ensure that whichever VM size you choose, it [supports nested virtualization](https://docs.microsoft.com/en-us/azure/virtual-machines/acu "Nested virtualization support") and is [available in your chosen region](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=virtual-machines "Virtual machines available by region").

Deploying the Azure VM
-----------
The guidance below provides a simple template-based option for deploying the Azure VM. The template deployment will be automated to the point of which you can proceed immediately to start creating your Azure Stack HCI 20H2 cluster, and progress through your workshop.

### Deployment detail ###
As part of the deployment, the following steps will be **automated for you**:

1. A Windows Server 2019 Datacenter VM will be deployed in Azure
2. 8 x 32GiB (by default) Azure Managed Disks will be attached and provisioned with a Simple Storage Space for optimal nested VM performance
3. The Hyper-V role and management tools will be installed and configured
4. An Internal vSwitch will be created and NAT configured to enable outbound networking
5. The DNS role and accompanying management tools will be installed and DNS fully configured
6. The DHCP role and accompanying management tools will be installed and DHCP fully configured. DHCP Scope will be **enabled**
7. Windows Admin Center will be installed and pre-installed extensions updated
8. The Microsoft Edge browser will be installed
9. The Azure Stack HCI 20H2 binaries will be downloaded
10. 2 x Azure Stack HCI 20H2 nodes will be created and deployed, ready to start cluster creation

This automated deployment **should take around 50 minutes**, due to the image creation of the Azure Stack HCI 20H2 nodes - these are created, **offline patched** and deployed, which takes time.

### Creating the VM with an Azure Resource Manager JSON Template ###
To keep things simple, and graphical, we'll show you how to deploy your VM via an Azure Resource Manager template.  To simplify things further, we'll use the following buttons.

Firstly, the **Visualize** button will launch the ARMVIZ designer view, where you will see a graphic representing the core components of the deployment, including the VM, NIC, disk and more. If you want to open this in a new tab, **hold CTRL** when you click the button.

[![Visualize your template deployment](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmattmcspirit%2Fhybridworkshop%2Fmain%2Fjson%2Fhybridhost.json "Visualize your template deployment")

Secondly, the **Deploy to Azure** button, when clicked, will take you directly to the Azure portal, and upon login, provide you with a form to complete. If you want to open this in a new tab, **hold CTRL** when you click the button.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmattmcspirit%2Fhybridworkshop%2Fmain%2Fjson%2Fhybridhost.json "Deploy to Azure")

Upon clicking the **Deploy to Azure** button, enter the details, which should look something similar to those shown below, and click **Purchase**.

![Custom template deployment in Azure](/media/azure_vm_custom_template_new.png "Custom template deployment in Azure")

**NOTE** - For customers with Software Assurance, Azure Hybrid Benefit for Windows Server allows you to use your on-premises Windows Server licenses and run Windows virtual machines on Azure at a reduced cost. By selecting **Yes** for the "Already have a Windows Server License", **you confirm I have an eligible Windows Server license with Software Assurance or Windows Server subscription to apply this Azure Hybrid Benefit** and have reviewed the [Azure hybrid benefit compliance](http://go.microsoft.com/fwlink/?LinkId=859786 "Azure hybrid benefit compliance document")

The custom template will be validated, and if all of your entries are correct, you can click **Create**. Within a few minutes, your VM will be created.

![Custom template deployment in Azure completed](/media/azure_vm_custom_template_completed.png "Custom template deployment in Azure completed")

If you chose to **enable** the auto-shutdown for the VM, and supplied a time, and time zone, but want to also add a notification alert, simply click on the **Go to resource group** button and then perform the following steps:

1. In the **Resource group** overview blade, click the **HybridHost001** virtual machine
2. Once on the overview blade for your VM, **scroll down on the left-hand navigation**, and click on **Auto-shutdown**
3. Ensure the Enabled slider is still set to **On** and that your **time** and **time zone** information is correct
4. Click **Yes** to enable notifications, and enter a Webhook URL, or Email address
5. Click **Save**

You'll now be notified when the VM has been successfully shut down as the requested time.

With that completed, skip on to [connecting to your Azure VM](#connect-to-your-azure-vm)

#### Deployment errors ####
If your Azure VM fails to deploy successfully, and the error relates to the **HybridHost001/ConfigureHybridHost** PowerShell DSC extension, please refer to the [troubleshooting steps below](#troubleshooting).

Access your Azure VM
-----------

With your Azure VM (HybridHost001) successfully deployed and configured, you're ready to connect to the VM to start the deployment of the Azure Stack HCI 20H2 and AKS on Azure Stack HCI infrastructure.

### Connect to your Azure VM ###
Firstly, you'll need to connect into the VM, with the easiest approach being via Remote Desktop.  If you're not already logged into the Azure portal, visit https://portal.azure.com/, and login with the same credentials used earlier.  Once logged in, using the search box on the dashboard, enter "**hybridhost**" and once the results are returned, **click on your HybridHost001 virtual machine**.

![Virtual machine located in Azure](/media/azure_vm_search.png "Virtual machine located in Azure")

Once you're on the Overview blade for your VM, along the top of the blade, click on **Connect** and from the drop-down options.

![Connect to a virtual machine in Azure](/media/connect_to_vm.png "Connect to a virtual machine in Azure")

Select **RDP**. On the newly opened Connect blade, ensure the **Public IP** is selected. Ensure the RDP port matches what you provided at deployment time. By default, this should be **3389**. Then click **Download RDP File** and select a suitable folder to store the .rdp file.

![Configure RDP settings for Azure VM](/media/connect_to_vm_properties.png "Configure RDP settings for Azure VM")

Once downloaded, locate the .rdp file on your local machine, and double-click to open it. Click **connect** and when prompted, enter the credentials you supplied when creating the VM earlier.  **NOTE**, this should be a **domain account**, which by default, is **hybrid\azureuser**.

**Username:** hybrid\azureuser
**Password:** password-you-used-at-VM-deployment-time

Accept any certificate prompts, and within a few moments, you should be successfully logged into the Windows Server 2019 VM.

Please Read - Finish Setup
-----------
Once the Azure VM deployment process has completed, your Azure Stack HCI 20H2 nodes are still processing changes, including adding roles and features inside the nested hosts. Please allow ~5 minutes for this process to complete and stabilize.

You can then optionally shut down your Azure VM, should you wish to continue your evaluation on another day.

Next Steps
-----------
In this step, you've successfully created and automatically configured your Azure VM, which will serve as the host for your Azure Stack HCI 20H2 and AKS on Azure Stack HCI infrastructure. You're now ready to move on to the next step.

* [**Part 2** - Configure your Azure Stack HCI 20H2 Cluster](/steps/2_DeployAzSHCI.md "Configure your Azure Stack HCI 20H2 Cluster")

Troubleshooting
-----------
From time to time, a transient, random deployment error may cause the Azure VM to show a failed deployment. This is typically caused by reboots and timeouts within the VM as part of the PowerShell DSC configuration process, in particular, when the Hyper-V role is enabled and the system reboots multiple times in quick succession. We've also seen instances where changes with Chocolatey Package Manager cause deployment issues.

![Azure VM deployment error](/media/vm_deployment_error.png "Azure VM deployment error")

If the error is related to the **HybridHost001/ConfigureHybridHost**, most likely the installation did complete successfully in the end, but to double-check, you can perform these steps:

1. Follow the steps above to [connect to your Azure VM](#connect-to-your-azure-vm)
2. Once successfully connected, open a **PowerShell console as administrator** and run the following command to confirm the status of the last run:

```powershell
# Check for last run
Get-DscConfigurationStatus
```
![Result of Get-DscConfigurationStatus](/media/get-dscconfigurationstatus.png "Result of Get-DscConfigurationStatus")

3. As you can see, in this particular case, the PowerShell DSC configuration **status appears to have been successful**, however your results may show a different result. Just for good measure, you can re-apply the configuration by **running the following commands**:

```powershell
cd "C:\Packages\Plugins\Microsoft.Powershell.DSC\*\DSCWork\hybridhost.0\HybridHost"
Start-DscConfiguration -Path . -Wait -Force -Verbose
```

4. If all goes well, you should see the DSC configuration reapplied without issues. If you then re-run the following PowerShell command, you should see success:

```powershell
# Check for last run
Get-DscConfigurationStatus
```

![Result of Get-DscConfigurationStatus](/media/get-dscconfigurationstatus2.png "Result of Get-DscConfigurationStatus")

**NOTE** - If this doesn't fix your issue, consider redeploying your Azure VM. If the issue persists, please **raise an issue!**

Product improvements
-----------
If, while you work through this guide, you have an idea to make the product better, whether it's something in Azure Stack HCI, AKS on Azure Stack HCI, Windows Admin Center, or the Azure Arc integration and experience, let us know! We want to hear from you!

For **Azure Stack HCI**, [Head on over to the Azure Stack HCI 20H2 Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Azure Stack HCI 20H2 Q&A"), where you can share your thoughts and ideas about making the technologies better and raise an issue if you're having trouble with the technology.

For **AKS on Azure Stack HCI**, [Head on over to our AKS on Azure Stack HCI 20H2 GitHub page](https://github.com/Azure/aks-hci/issues "AKS on Azure Stack HCI GitHub"), where you can share your thoughts and ideas about making the technologies better. If however, you have an issue that you'd like some help with, read on... 

Raising issues
-----------
If you notice something is wrong with this guide, such as a step isn't working, or something just doesn't make sense - help us to make this guide better!  Raise an issue in GitHub, and we'll be sure to fix this as quickly as possible!

If you're having an issue with Azure Stack HCI 20H2 **outside** of this guide, [head on over to the Azure Stack HCI 20H2 Q&A forum](https://docs.microsoft.com/en-us/answers/topics/azure-stack-hci.html "Azure Stack HCI 20H2 Q&A"), where Microsoft experts and valuable members of the community will do their best to help you.

If you're having a problem with AKS on Azure Stack HCI **outside** of this guide, make sure you post to [our GitHub Issues page](https://github.com/Azure/aks-hci/issues "GitHub Issues"), where Microsoft experts and valuable members of the community will do their best to help you.
