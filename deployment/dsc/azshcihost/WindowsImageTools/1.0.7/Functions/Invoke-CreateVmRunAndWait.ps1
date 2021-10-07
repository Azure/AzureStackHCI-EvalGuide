function Invoke-CreateVmRunAndWait 
{
    <#
            .Synopsis
            Create a temp vm with a random name and wait for it to stop
            .DESCRIPTION
            This Command quickly test changes to a VHD by creating a temporary VM and ataching it to the network. VM is deleted when it enters a stoped state.
            .EXAMPLE
            Invoke-CreateVMRunAndWait -VhdPath c:\test.vhdx -VmGeneration 2 -VmSwitch 'testlab'
            .EXAMPLE
            Invoke-CreateVMRunAndWait -VhdPath c:\test.vhdx -VmGeneration 2 -VmSwitch 'testlab' -vLan 16023 -ProcessorCount 1 -MemorySTartupBytes 512mb
    #>
    [CmdletBinding()]
    param
    (
        # Path to VHD(x)
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string] 
        $VhdPath, 
        
        # VM Generation (1 = BIOS/MBR, 2 = uEFI/GPT)
        [Parameter(Mandatory = $true)]
        [ValidateSet(1, 2)]
        [int] 
        $VmGeneration,

        # name of VM switch to attach to
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string] 
        $VmSwitch, 

        # vLAN to use default = 0 (dont use vLAN)
        [int] 
        $vLan = 0,
        
        # ProcessorCount default = 2
        [int]
        $ProcessorCount = 2,

        # MemoryStartupBytes default = 2Gig
        [long]
        $MemoryStartupBytess = 2GB
    )
    
    $vmName = [System.IO.Path]::GetRandomFileName().split('.')[0]
     
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Creating VM $vmName at $(Get-Date)"  
    $null = New-VM -Name $vmName -MemoryStartupBytes $MemoryStartupBytess -VHDPath $VhdPath -Generation $VmGeneration -SwitchName $VmSwitch -ErrorAction Stop

    If($vLan -ne 0) 
    {
        Get-VMNetworkAdapter -VMName $vmName | Set-VMNetworkAdapterVlan -Access -VlanId $vLan
    }

    Set-VM -Name $vmName -ProcessorCount $ProcessorCount
    Start-VM $vmName

    # Give the VM a moment to start before we start checking for it to stop
    Start-Sleep -Seconds 10

    # Wait for the VM to be stopped for a good solid 5 seconds
    do
    {
        $state1 = (Get-VM | Where-Object -Property name -EQ -Value $vmName).State
        Start-Sleep -Seconds 5
        
        $state2 = (Get-VM | Where-Object -Property name -EQ -Value $vmName).State
        Start-Sleep -Seconds 5
    } 
    until (($state1 -eq 'Off') -and ($state2 -eq 'Off'))

    # Clean up the VM
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : VM $vmName Stoped"
    Remove-VM $vmName -Force
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : VM $vmName Deleted at $(Get-Date)"
}
