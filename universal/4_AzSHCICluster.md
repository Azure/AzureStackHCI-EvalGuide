Create Azure Stack HCI cluster with Windows Admin Center
==============
Overview
-----------

So far, you've deployed your Azure Stack HCI nodes, either in a nested virtualization sandbox, or on existing physical hardware.  In the case of the sandboxed environment, you've also stood up an Active Directory infrastructure with DNS and DHCP services running.  In a physical deployment, it was assumed these kind of dependencies were already in place.  Finally, in both cases, you've deployed the Windows Admin Center, which we'll be using to configure the Azure Stack HCI cluster.

Architecture
-----------


Create the Azure Stack HCI cluster
-----------
With Windows Admin Center, you now have the ability to construct Azure Stack HCI clusters from the vanilla nodes.  There are no additional extensions to install, the workflow is built in and ready to go.

1. Access your **Windows Admin Center** instance.  Those of you running on the **nested** path, you'll need to open **MGMT01** and access Windows Admin Center from there.
2. 