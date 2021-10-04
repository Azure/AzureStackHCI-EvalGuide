
<#
#  Get the current configuration of the machine
#  This function is called when you do Get-DscConfiguration after the configuration is set.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VhdPath,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $FileDirectory,

        [Parameter()]
        [ValidateSet('ModifiedDate','SHA-1','SHA-256','SHA-512')]
        [System.String]
        $CheckSum = 'ModifiedDate'
    )

    if ( -not (Test-path $VhdPath))
    {
        $item = New-CimInstance -ClassName MSFT_FileDirectoryConfiguration -Property @{DestinationPath = $VhdPath; Ensure = "Absent"} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly

        Return @{
            VhdPath = $VhdPath
            FileDirectory = $item
         }
    }

    # Mount VHD.
    $mountVHD = EnsureVHDState -Mounted -vhdPath $vhdPath

    $itemsFound = foreach($Item in $FileDirectory)
    {
        $item = GetItemToCopy -item $item
        $mountedDrive =  $mountVHD | Get-Disk | Get-Partition | Where-Object -FilterScript {$_.Type -ne 'Recovery'} | Get-Volume
        $letterDrive  = (-join $mountedDrive.DriveLetter) + ":\"

        # show the drive letters.
        Get-PSDrive | Write-Verbose

        $finalPath = Join-Path $letterDrive $item.DestinationPath

        Write-Verbose "Getting the current value at $finalPath ..."

        if (Test-Path $finalPath)
        {
            New-CimInstance -ClassName MSFT_FileDirectoryConfiguration -Property @{DestinationPath = $finalPath; Ensure = "Present"} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
        }
        else
        {
            New-CimInstance -ClassName MSFT_FileDirectoryConfiguration -Property @{DestinationPath = $finalPath ; Ensure = "Absent"} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
        }
   }

    # Dismount VHD.
    EnsureVHDState -Dismounted -vhdPath $VhdPath

    # Return the result.
    Return @{
      VhdPath = $VhdPath
      FileDirectory = $itemsFound
    }
}


# This is a resource method that gets called if the Test-TargetResource returns false.
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VhdPath,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $FileDirectory,

        [Parameter()]
        [ValidateSet('ModifiedDate','SHA-1','SHA-256','SHA-512')]
        [System.String]
        $CheckSum = 'ModifiedDate'
    )

    if (-not (Test-Path $VhdPath)) { throw "Specified destination path $VhdPath does not exist!"}

    # mount the VHD.
    $mountedVHD = EnsureVHDState -Mounted -vhdPath $VhdPath

    try
    {
            # show the drive letters.
            Get-PSDrive | Write-Verbose

            $mountedDrive = $mountedVHD | Get-Disk | Get-Partition | Where-Object -FilterScript {$_.Type -ne 'Recovery'} | Get-Volume

            foreach ($item in $FileDirectory)
            {
                $itemToCopy = GetItemToCopy -item $item
                $letterDrive  = (-join $mountedDrive.DriveLetter) + ":\"
                $finalDestinationPath = $letterDrive
                $finalDestinationPath = Join-Path  $letterDrive  $itemToCopy.DestinationPath

                # if the destination should be removed
                if (-not($itemToCopy.Ensure))
                {
                    if (Test-Path $finalDestinationPath)
                    {
                        SetVHDFile -destinationPath $finalDestinationPath -ensure:$false -recurse:($itemToCopy.Recurse)
                    }
                }
                else
                {
                    # Copy Scenario
                    if ($itemToCopy.SourcePath)
                    {
                        SetVHDFile -sourcePath $itemToCopy.SourcePath  -destinationPath $finalDestinationPath -recurse:($itemToCopy.Recurse) -force:($itemToCopy.Force)
                    }
                    elseif ($itemToCopy.Content)
                    {
                        "Writing a content to a file"

                        # if the type is not specified assume it is a file.
                        if (-not ($itemToCopy.Type))
                        {
                            $itemToCopy.Type = 'File'
                        }

                        # Create file/folder scenario
                        SetVHDFile -destinationPath $finalDestinationPath -type $itemToCopy.Type -force:($itemToCopy.Force)  -content $itemToCopy.Content
                    }

                    # Set Attribute scenario
                    if ($itemToCopy.Attributes)
                    {
                        SetVHDFile -destinationPath $finalDestinationPath -attribute $itemToCopy.Attributes -force:($itemToCopy.Force)
                    }
                }

            }
    }
    finally
    {
        EnsureVHDState -Dismounted -vhdPath $VhdPath
    }
}

# This function returns if the current configuration of the machine is the same as the desired configration for this resource.
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VhdPath,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $FileDirectory,

        [Parameter()]
        [ValidateSet('ModifiedDate','SHA-1','SHA-256','SHA-512')]
        [System.String]
        $CheckSum = 'ModifiedDate'
    )

    # If the VHD path does not exist throw an error and stop.
    if ( -not (Test-Path $VhdPath))
    {
        throw "VHD does not exist in the specified path $VhdPath"
    }

    # mount the vhd.
    $mountedVHD = EnsureVHDState -Mounted -vhdPath $VhdPath

    try
    {
        # Show the drive letters after mount
        Get-PSDrive | Write-Verbose

        $mountedDrive = $mountedVHD | Get-Disk | Get-Partition | Where-Object -FilterScript {$_.Type -ne 'Recovery'} | Get-Volume
        $letterDrive  = (-join $mountedDrive.DriveLetter) + ":\"
        Write-Verbose $letterDrive

        # return test result equal to true unless one of the tests in the loop below fails.
        $result = $true

        foreach ($item in $FileDirectory)
        {
            $itemToCopy = GetItemToCopy -item $item
            $destination =  $itemToCopy.DestinationPath
            Write-Verbose ("Testing the file with relative VHD destination $destination")
            $destination =  $itemToCopy.DestinationPath
            $finalDestinationPath = $letterDrive
            $finalDestinationPath = Join-Path $letterDrive $destination

            if (Test-Path $finalDestinationPath)
            {
                  if( -not ($itemToCopy.Ensure))
                  {
                    $result = $false
                    break;
                  }
                  else
                  {
                        $itemToCopyIsFile = Test-Path $itemToCopy.SourcePath -PathType Leaf
                        $destinationIsFolder = Test-Path $finalDestinationPath -PathType Container

                        if ($itemToCopyIsFile -and $destinationIsFolder)
                        {
                            # Verify if the file exist inside the folder
                            $fileName = Split-Path $itemToCopy.SourcePath -Leaf
                            Write-Verbose "Checking if $fileName exist under $finalDestinationPath"
                            $fileExistInDestination = Test-Path (Join-Path $finalDestinationPath $fileName)

                            # Report if the file exist on the destination folder.
                            Write-Verbose "File exist on the destination under $finalDestinationPath :- $fileExistInDestination"
                            $result = $fileExistInDestination
                            $result = $result -and -not(ItemHasChanged -sourcePath $itemToCopy.SourcePath -destinationPath (Join-Path $finalDestinationPath $fileName) -CheckSum $CheckSum)
                        }

                        if (($itemToCopy.Type -eq "Directory") -and ($itemToCopy.Recurse))
                        {
                            $result = $result -and -not(ItemHasChanged -sourcePath $itemToCopy.SourcePath -destinationPath $finalDestinationPath -CheckSum $CheckSum)

                            if (-not ($result))
                            {
                               break;
                            }
                         }
                  }
            }
            else
            {
                # If Ensure is specified as Present or if Ensure is not specified at all.
                if(($itemToCopy.Ensure))
                {
                    $result = $false
                    break;
                }
            }

            # Check the attribute
            if ($itemToCopy.Attributes)
            {
                $currentAttribute = @(Get-ItemProperty -Path $finalDestinationPath | ForEach-Object -MemberName Attributes)
                $result = $currentAttribute.Contains($itemToCopy.Attributes)
            }
          }
    }
    finally
    {
        EnsureVHDState -Dismounted -vhdPath $VhdPath
    }


   Write-Verbose "Test returned $result"
   return $result;
}

# Assert the state of the VHD.
function EnsureVHDState
{
    [CmdletBinding(DefaultParametersetName="Mounted")]
    param(

        [Parameter(ParameterSetName = "Mounted")]
        [switch]$Mounted,
        [Parameter(ParameterSetName = "Dismounted")]
        [switch]$Dismounted,
        [Parameter(Mandatory=$true)]
        $vhdPath
        )

        if ( -not ( Get-Module -ListAvailable Hyper-v))
        {
            throw "Hyper-v-Powershell Windows Feature is required to run this resource. Please install Hyper-v feature and try again"
        }
        if ($PSCmdlet.ParameterSetName -eq 'Mounted')
        {
             # Try mounting the VHD.
            $mountedVHD = Mount-VHD -Path $vhdPath -Passthru -ErrorAction SilentlyContinue -ErrorVariable var

            # If mounting the VHD failed. Dismount the VHD and mount it again.
            if ($var)
            {
                Write-Verbose "Mounting Failed. Attempting to dismount and mount it back"
                Dismount-VHD $vhdPath
                $mountedVHD = Mount-VHD -Path $vhdPath -Passthru -ErrorAction SilentlyContinue

                return $mountedVHD
            }
            else
            {
                return $mountedVHD
            }
        }
        else
        {
            Dismount-VHD $vhdPath -ea SilentlyContinue

        }
}

# Change the Cim Instance objects in to a hash table containing property value pair.
function GetItemToCopy
{
    param(
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance] $item
        )

    #Initialize Return Object
    $returnValue = @{}

    #Define Default Values

    $DesiredProperties = [ordered]@{
        'SourcePath' = $null
        'DestinationPath' = $null
        'Ensure' = 'Present'
        'Recurse' = 'True'
        'Force' = 'True'
        'Content' = $null
        'Attributes' = $null
        'Type' = 'Directory'
    }

    [string[]]($DesiredProperties.Keys) | Foreach-Object -Process {
        #Get Property Value
        $thisItem = $item.CimInstanceProperties[$_].Value

        if (-not $thisItem -and $_ -in $DefaultValues.Keys)
        {
            #If unset and a default value is defined enter here
            if ($_ -eq 'Type')
            {
                #Special behavior for the Type property based on SourcePath
                #This relies on SourcePath preceeding Type in the list of keys (the reason for using OrderedDictionary)
                if (Test-Path $returnValue.SourcePath -PathType Leaf )
                {
                    #If the sourcepath resolves to a file, set the default to File instad of Directory
                    $DefaultValues.Type = 'File'
                }
            }
            $returnValue[$_] = $DefaultValues[$_]
        }
        else
        {
            #If value present or no default value enter here
            $returnValue[$_] = $item.CimInstanceProperties[$_].Value
        }
    }

    #Relies on default values in the $DesiredProperties object being the $True equivalent values
    $PropertyValuesToBoolean = @(
        'Force',
        'Recurse',
        'Ensure'
    )

    # Convert string values to boolean for ease of programming.
    $PropertyValuesToBoolean | ForEach-Object -Process {
        $returnValue[$_] = $returnValue[$_] -eq $DesiredProperties[$_]
    }


      $returnValue.Keys | ForEach-Object -Process {
        Write-Verbose "$_ => $($returnValue[$_])"
      }

    return $returnValue
}


# This is the main function that gets called after the file is mounted to perform copy, set or new operations on the mounted drive.
function SetVHDFile
{
     [CmdletBinding(DefaultParametersetName="Copy")]
    param(
        [Parameter(Mandatory=$true,ParameterSetName = "Copy")]
        $sourcePath,
        [Parameter()]
        [switch]$recurse,
        [Parameter()]
        [switch]$force,
        [Parameter(ParameterSetName = "New")]
        $type,
        [Parameter(ParameterSetName = "New")]
        $content,
        [Parameter(Mandatory=$true)]
        $destinationPath,
        [Parameter(Mandatory=$true,ParameterSetName = "Set")]
        $attribute,
        [Parameter(Mandatory=$true,ParameterSetName = "Delete")]
        [switch]$ensure
        )

    Write-Verbose "Setting the VHD file $($PSCmdlet.ParameterSetName)"
    if ($PSCmdlet.ParameterSetName -eq 'Copy')
    {
        New-Item -Path (Split-Path $destinationPath) -ItemType Directory -ErrorAction SilentlyContinue
        Copy-Item -Path $sourcePath -Destination $destinationPath -Force:$force -Recurse:$recurse -ErrorAction SilentlyContinue
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'New')
    {
        If ($type -eq 'Directory')
        {
            New-Item -Path $destinationPath -ItemType $type
        }
        else
        {
            New-Item -Path $destinationPath -ItemType $type
            $content | Out-File $destinationPath
        }

    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Set')
    {
        Write-Verbose "Attempting to change the attribute of the file $destinationPath to value $attribute"
        Set-ItemProperty -Path $destinationPath -Name Attributes -Value $attribute
    }
    elseif (!($ensure))
    {
        Remove-Item -Path $destinationPath -Force:$force -Recurse:$recurse
    }
}

# Detect if the item to be copied is modified version of the orginal.
function ItemHasChanged
{
    param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    $sourcePath,
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    $destinationPath,
    [Parameter()]
    [ValidateSet('ModifiedDate','SHA-1','SHA-256','SHA-512')]
    $CheckSum = 'ModifiedDate'
    )

    $itemIsFolder = Test-Path $sourcePath -Type Container
    $sourceItems = $null;
    $destinationItems = $null;

    if ($itemIsFolder)
    {
        $sourceItems = Get-ChildItem "$sourcePath\*.*" -Recurse
        $destinationItems = Get-ChildItem "$destinationPath\*.*" -Recurse

    }
    else
    {
        $sourceItems = Get-ChildItem $sourcePath
        $destinationItems = Get-ChildItem $destinationPath

    }

    if ( -not ($destinationItems))
    {
        return $true;
    }

    # Compute the difference using the algorithem specified.
    $difference = $null

    switch ($CheckSum)
    {
        'ModifiedDate'
        {
            $difference = Compare-Object -ReferenceObject $sourceItems -DifferenceObject $destinationItems -Property LastWriteTime
        }
        'SHA-1'
        {
            $difference = Compare-Object -ReferenceObject ($sourceItems | Get-FileHash -Algorithm SHA1) -DifferenceObject ($destinationItems | Get-FileHash -Algorithm SHA1) -Property Hash
        }
        'SHA-256'
        {
            $difference = Compare-Object -ReferenceObject ($sourceItems | Get-FileHash -Algorithm SHA256) -DifferenceObject ($destinationItems | Get-FileHash -Algorithm SHA256) -Property Hash
        }
        'SHA-512'
        {
            $difference = Compare-Object -ReferenceObject ($sourceItems | Get-FileHash -Algorithm SHA512) -DifferenceObject ($destinationItems | Get-FileHash -Algorithm SHA512) -Property Hash
        }
    }
    # If there are object difference between the item at the source and Items at the distenation.
    return ($null -ne $difference)

}

Export-ModuleMember -Function *-TargetResource

