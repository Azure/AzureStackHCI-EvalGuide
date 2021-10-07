function Get-FullFilePath
{
    <#
            .Synopsis
            Get Absolute path from relative path
            .DESCRIPTION
            Takes a relative path like .\file.txt and returns the full path.
            Parent folder must exist, but target file does not.
            The target file does not have to exist, but the parent folder must exist
            .EXAMPLE
            $path = Get-AbsoluteFilePath -Path .\file.txt
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Path to file
        [Parameter(Mandatory,HelpMessage = 'Path to file',
                ValueFromPipeline,
        Position = 0)]
        [String]$Path
    )

    if (-not (Test-Path -Path $Path))
    {
        if (Test-Path -Path (Split-Path -Path $Path -Parent ))
        {
            $Parent = Resolve-Path -Path (Split-Path -Path $Path -Parent )
            $Leaf = Split-Path -Path $Path -Leaf
            
            if ($Parent.path[-1] -eq '\') 
            {
                $Path = "$Parent" + "$Leaf"
            }
            else 
            {
                $Path = "$Parent" + "\$Leaf"
            }
        }
        else 
        {
            throw "Parent [$(Split-Path -Path $Path -Parent)] does not exist"
        }
    }
    else 
    {
        $Path = Resolve-Path -Path $Path
    }
    
    return $Path
}

function 
Test-Admin 
{
    <#
            .SYNOPSIS
            Short function to determine whether the logged-on user is an administrator.

            .EXAMPLE
            Do you honestly need one?  There are no parameters!

            .OUTPUTS
            $true if user is admin.
            $false if user is not an admin.
    #>
    [CmdletBinding()]
    param()

    $currentUser = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : is User Admin? [$isAdmin]"

    return $isAdmin
}


function
Run-Executable 
{
    <#
            .SYNOPSIS
            Runs an external executable file, and validates the error level.

            .PARAMETER Executable
            The path to the executable to run and monitor.

            .PARAMETER Arguments
            An array of arguments to pass to the executable when it's executed.

            .PARAMETER SuccessfulErrorCode
            The error code that means the executable ran successfully.
            The default value is 0.  
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory,HelpMessage = 'Path to Executable')]
        [string]
        [ValidateNotNullOrEmpty()]
        $Executable,

        [Parameter(Mandatory,HelpMessage = 'aray of arguments to pass to executable')]
        [string[]]
        [ValidateNotNullOrEmpty()]
        $Arguments,

        [Parameter()]
        [int]
        $SuccessfulErrorCode = 0

    )

    $exeName = Split-Path -Path $Executable -Leaf
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Running [$Executable] [$Arguments]"
    $Params = @{
        'FilePath'             = $Executable
        'ArgumentList'         = $Arguments
        'NoNewWindow'          = $true
        'Wait'                 = $true
        'RedirectStandardOutput' = "$($env:temp)\$($exeName)-StandardOutput.txt"
        'RedirectStandardError' = "$($env:temp)\$($exeName)-StandardError.txt"
        'PassThru'             = $true
    }

    Write-Verbose -Message ($Params | Out-String)
    $ret = Start-Process @Params -ErrorAction SilentlyContinue

    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Return code was [$($ret.ExitCode)]"

    if ($ret.ExitCode -ne $SuccessfulErrorCode) 
    {
        throw "$Executable failed with code $($ret.ExitCode)!"
    }
}

Function Test-IsNetworkLocation 
{
    <#
            .SYNOPSIS
            Determines whether or not a given path is a network location or a local drive.
            
            .DESCRIPTION
            Function to determine whether or not a specified path is a local path, a UNC path,
            or a mapped network drive.

            .PARAMETER Path
            The path that we need to figure stuff out about,
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeLine)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Path
    )

    $result = $false
    
    if ([bool]([URI]$Path).IsUNC) 
    {
        $result = $true
    } 
    else 
    {
        $driveInfo = [IO.DriveInfo]((Resolve-Path -Path $Path).Path)

        if ($driveInfo.DriveType -eq 'Network') 
        {
            $result = $true
        }
    }

    return $result
}

function New-TemporaryDirectory
{
    <#
            .Synopsis
            Create a new Temporary Directory
            .DESCRIPTION
            Creates a new Directory in the $env:temp and returns the System.IO.DirectoryInfo (dir) 
            .EXAMPLE
            $TempDirPath = NewTemporaryDirectory
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.DirectoryInfo])]
    Param
    (
    )

    #return [System.IO.Directory]::CreateDirectory((Join-Path $env:Temp -Ch ([System.IO.Path]::GetRandomFileName().split('.')[0])))

    Begin
    {
        try
        {
            if($PSCmdlet.ShouldProcess($env:temp))
            {
                $tempDirPath = [System.IO.Directory]::CreateDirectory((Join-Path -Path $env:temp -ChildPath ([System.IO.Path]::GetRandomFileName().split('.')[0])))
            }
        }
        catch
        {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($_.Exception,'NewTemporaryDirectoryWriteError', 'WriteError', $env:temp)
            Write-Error -ErrorRecord $errorRecord
            return
        } 

        if($tempDirPath)
        {
            Get-Item -Path $env:temp\$tempDirPath
        }
    }
}

function MountVHDandRunBlock 
{
    param
    (
        [string]$vhd, 
        [scriptblock]$block,
        [switch]$ReadOnly
    )
     
    # This function mounts a VHD, runs a script block and unmounts the VHD.
    # Drive letter of the mounted VHD is stored in $driveLetter - can be used by script blocks
    if($ReadOnly) 
    {
        $virtualDisk = Mount-VHD -Path $vhd -ReadOnly -Passthru
    }
    else 
    {
        $virtualDisk = Mount-VHD -Path $vhd -Passthru
    }
    # Workarround for new drive letters in script modules                  
    $null = Get-PSDrive
    $driveLetter = ($virtualDisk |
        Get-Disk |
        Get-Partition |
    Get-Volume).DriveLetter
    & $block

    Dismount-VHD -Path $vhd

    # Wait 2 seconds for activity to clean up
    Start-Sleep -Seconds 2
}

Function GetVHDPartitionStyle
{
    param
    (
        [string]$vhd 
    )
    $PartitionStyle = (Mount-VHD -Path $vhd -ReadOnly -Passthru | Get-Disk).PartitionStyle
    Dismount-VHD -Path $vhd
    Start-Sleep -Seconds 2
    return $PartitionStyle
}         

function createRunAndWaitVM 
{
    [CmdletBinding()]
    param
    (
        [string] $vhdPath, 
        [string] $vmGeneration,
        [Hashtable] $configData
    )
    
    $vmName = [System.IO.Path]::GetRandomFileName().split('.')[0]
     
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : Creating VM $vmName at $(Get-Date)"  
    $null = New-VM -Name $vmName -MemoryStartupBytes 2048mb -VHDPath $vhdPath -Generation $vmGeneration -SwitchName $configData.vmSwitch -ErrorAction Stop

    If($configData.vLan -ne 0) 
    {
        Get-VMNetworkAdapter -VMName $vmName | Set-VMNetworkAdapterVlan -Access -VlanId $configData.vLan
    }

    Set-VM -Name $vmName -ProcessorCount 2
    Start-VM -Name $vmName

    # Give the VM a moment to start before we start checking for it to stop
    Start-Sleep -Seconds 10

    # Wait for the VM to be stopped for a good solid 5 seconds
    do
    {
        $state1 = (Get-VM | Where-Object name -EQ -Value $vmName).State
        Start-Sleep -Seconds 5
        
        $state2 = (Get-VM | Where-Object name -EQ -Value $vmName).State
        Start-Sleep -Seconds 5
    } 
    until (($state1 -eq 'Off') -and ($state2 -eq 'Off'))

    # Clean up the VM
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : VM $vmName Stoped"
    Remove-VM -Name $vmName -Force
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] : VM $vmName Deleted at $(Get-Date)"
}

function cleanupFile
{
    param
    (
        [string[]] $file
    )
    
    foreach ($target in $file) 
    { 
        if (Test-Path -Path $target) 
        {
            Remove-Item -Path $target -Recurse -Force
        }
    }
}
