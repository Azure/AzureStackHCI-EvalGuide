#cWaitForVMGuestIntegration#
This DSC resource is especially helpful when a VM resource configuration requires that the VM integration components are up and running. You can use this resource to wait for the guest integration components. For example, to be able to inject an IP address (using cVMIPAddress DSC resource) into a newly created Windows VM, the VM should have integration components installed and running. In such a configuration scenario, you can use this resource to wait until the integration components change into running state. 

![](http://i.imgur.com/rtiyk4B.png)

The *Id* property is an instance identifier and key property in the resource configuration. This does not identify any VM property instead provides a way to wait for the integration components of that VM multiple times in a single configuration document.

The *VMName* property identifies the virtual machine in which the guest integration components should be in running state. This is a mandatory property.

The *RetryCount* property identifies how many times the resource should try to test for guest integration component state. Default value is 5. This is an optional property.

The *RetryIntervalSec* property identifies interval (in seconds) between retries. Default Value is 10 seconds. This is an optional property.

Here are some examples that demonstrates how to use this resource.

##Wait For VM IC with default retry values##
Configuration WaitForIC
    {
        Import-DscResource -Name cWaitForVMGuestIntegration -ModuleName cHyper-V
    
        cWaitForVMGuestIntegration VM01
        {
            Id = 'VM01-IC01'
            VMName = 'VM01'
        }
    }

##Wait for VM IC with custom retry values##
    Configuration WaitForIC
    {
        Import-DscResource -Name cWaitForVMGuestIntegration -ModuleName cHyper-V
    
        cWaitForVMGuestIntegration VM01
        {
            Id = 'VM01-IC01'
            VMName = 'VM01'
            RetryIntervalSec = 20
            RetryCount = 10
        }
    }
    
    