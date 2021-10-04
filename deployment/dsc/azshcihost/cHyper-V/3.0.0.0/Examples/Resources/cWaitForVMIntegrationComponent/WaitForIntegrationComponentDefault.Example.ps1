Configuration WaitForIC
{
    Import-DscResource -Name cWaitForVMGuestIntegration -ModuleName cHyper-V

    cWaitForVMGuestIntegration VM01
    {
        Id = 'VM01-IC01'
        VMName = 'VM01'
    }
}
