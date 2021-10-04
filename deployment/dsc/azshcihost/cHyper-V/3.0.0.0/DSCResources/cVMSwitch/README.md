#cVMSwitch PowerShell DSC Resource#
This resource module is a fork from Microsoft's xHyper-V resource module. I have added the capability to manage bandwidth settings of the VM switch and to deploy Switch Embedded teaming in Windows Server 2016.

![](http://i.imgur.com/odgNbD3.png)

When using this DSC resource, the *Name* and *Type* are mandatory properties where *Name* is the unique key properties.

The *AllowManagementOS* property can be used to add a VM network adapter attached to the VM switch we are creating in the management OS.

The *EnableIoV* property lets us enable SR-IOV capability on the VM switch.

The *MinimumBandwidthMode* and *EnableIoV* properties are mutually exclusive. We cannot configure both at the same time.

The *MinimumBandwidthMode* property can be used to configure a converged network switch on Hyper-V.

The *NetAdapterName* parameter is used when creating a VM switch of *External* type. If you pass multiple adapter names to this parameter, a switch embedded team will be provisioned. You can specify a comma-separated list of physical network adapters. Although, it is technically possible to create a SET team with just one adapter, from a design point of view, I simplified this by putting a constraint on at least two adapters to create a SET team.

The *LoadBalancingAlgorigthm* specifies the LB mode for the SET team. At the time of writing this resource module, SET supports only *SwitchIndepedent* load balancing algorithm. This applies only when multiple network adapters are specified.

The *TeamingMode* can be set of either *HyperVPort* or *Dynamic*. The default is *Dynamic*. This applies only when multiple network adapters are specified.

The following examples demonstrate how to use this resource module.
### Create a simple VM Switch from a native network team on the Hyper-V host ###
    Configuration SimpleHostTeamvSwitch
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMSwitch HostSwitch {
    	   Name = 'HostSwitch'
    	   Type = 'External'
    	   AllowManagementOS = $true
    	   MinimumBandwidthMode = 'Weight'
    	   NetAdapterName = 'HostTeam'
    	   Ensure = 'Present'
        }
    }

## Create a simple VM Switch using a network adapter on the Hyper-V host ##
    Configuration SimpleNetAdaptervSwitch
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMSwitch HostSwitch {
    	   Name = 'HostSwitch'
    	   Type = 'External'
    	   AllowManagementOS = $true
    	   NetAdapterName = 'NIC1'
    	   Ensure = 'Present'
        }
    }

## Create a Switch Embedded Team switch using four network adapters on the Hyper-V host ##
    Configuration SETTeamSwitch
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMSwitch HostSwitch {
    	    Name = 'HostSwitch'
    	    Type = 'External'
    	    AllowManagementOS = $true
            MinimumBandwidthMode = 'Weight'
            TeamingMode = 'SwitchIndependent'
            LoadBalancingAlgorithm = 'HyperVPort'
    	    NetAdapterName = 'NIC1','NIC2','NIC3','NIC4'
    	    Ensure = 'Present'
        }
    }

## Create a private VM switch on the Hyper-V host ##
    Configuration PrivateSwitch
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMSwitch HostSwitch {
    	    Name = 'HostSwitch'
    	    Type = 'Private'
    	    Ensure = 'Present'
        }
    }

## Create a internal VM switch on the Hyper-V host ##
    Configuration InternalSwitch
    {
        Import-DscResource -ModuleName cHyper-V -Name cVMSwitch
        Import-DscResource -ModuleName PSDesiredStateConfiguration
    
        cVMSwitch HostSwitch {
    	    Name = 'HostSwitch'
    	    Type = 'Internal'
    	    Ensure = 'Present'
        }
    }
 
To remove any of these switches, you can simply switch the *Ensure* property to *Absent*.