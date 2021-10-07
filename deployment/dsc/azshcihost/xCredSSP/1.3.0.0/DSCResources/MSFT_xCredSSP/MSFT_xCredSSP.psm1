function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Server","Client")]
        [System.String]
        $Role
    )

    #Check if GPO policy has been set
    switch($Role)
    {
        "Server"
        {
            $RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service"
        }
        "Client"
        {
            $RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client"
        }
    }
    $RegValueName = "AllowCredSSP"

    if (Test-RegistryValue -Path $RegKey -Name $RegValueName)
    {
        Write-Verbose -Message "CredSSP is configured via Group Policies"
    }
    else
    {
        # Check regular values
        switch($Role)
        {
            "Server"
            {
                $RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Service"
            }
            "Client"
            {
                $RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client"
            }
        }
        $RegValueName = "auth_credssp"
    }

    if(Test-RegistryValue -Path $RegKey -Name $RegValueName)
    {
        $Setting = (Get-ItemProperty -Path $RegKey -Name $RegValueName).$RegValueName
    }
    else
    {
        $Setting = 0
    }

    switch($Role)
    {
        "Server"
        {
            switch($Setting)
            {
                1
                {
                    $returnValue = @{
                        Ensure = "Present";
                        Role = "Server"
                    }
                }
                0
                {
                    $returnValue = @{
                        Ensure = "Absent";
                        Role = "Server"
                    }
                }
            }
        }
        "Client"
        {
            switch($Setting)
            {
                1
                {   
                    $key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials"

                    $DelegateComputers = @()


                    Get-Item -Path $key -ErrorAction SilentlyContinue |
                        Select-Object -ExpandProperty Property | 
                        ForEach-Object {
                            $DelegateComputer = ((Get-ItemProperty -Path $key -Name $_).$_).Split("/")[1]
                            $DelegateComputers += $DelegateComputer
                        }
                    $DelegateComputers = $DelegateComputers | Sort-Object -Unique

                    $returnValue = @{
                        Ensure = "Present";
                        Role = "Client";
                        DelegateComputers = @($DelegateComputers)
                    }
                }
                0
                {
                    $returnValue = @{
                        Ensure = "Absent";
                        Role = "Client"
                    }
                }
            }
        }
    }

    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateSet("Server","Client")]
        [System.String]
        $Role,

        [System.String[]]
        $DelegateComputers,

        [System.Boolean]
        $SuppressReboot = $false        
    )

    if ($Role -eq "Server" -and ($DelegateComputers)) 
    {
        throw ("Cannot use the Role=Server parameter together with " + `
               "the DelegateComputers parameter")
    }
    
    #Check if policy has been set
    switch($Role)
    {
        "Server"
        {
            $RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service"
        }
        "Client"
        {
            $RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client"
        }
    }
    $RegValueName = "AllowCredSSP"

    if (Test-RegistryValue -Path $RegKey -Name $RegValueName)
    {
        Throw "Cannot configure CredSSP. CredSSP is configured via Group Policies"
    }

    switch($Role)
    {
        "Server"
        {
            switch($Ensure)
            {
                "Present"
                {
                    Enable-WSManCredSSP -Role Server -Force | Out-Null
                    if ($SuppressReboot -eq $false)
                    {
                        $global:DSCMachineStatus = 1
                    }
                }
                "Absent"
                {
                    Disable-WSManCredSSP -Role Server | Out-Null
                }
            }
        }
        "Client"
        {
            switch($Ensure)
            {
                "Present"
                {
                    if($DelegateComputers)
                    {
                        $key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials"

                        if (!(test-path $key))
                        {
                            New-Item $key -Force | out-null
                        }

                        $CurrentDelegateComputers = @()

                        Get-Item -Path $key |
                            Select-Object -ExpandProperty Property | 
                            ForEach-Object {
                                $CurrentDelegateComputer = ((Get-ItemProperty -Path $key -Name $_).$_).Split("/")[1]
                                $CurrentDelegateComputers += $CurrentDelegateComputer
                            }
                        $CurrentDelegateComputers = $CurrentDelegateComputers | Sort-Object -Unique

                        foreach($DelegateComputer in $DelegateComputers)
                        {
                            if(($CurrentDelegateComputers -eq $NULL) -or (!$CurrentDelegateComputers.Contains($DelegateComputer)))
                            {
                                Enable-WSManCredSSP -Role Client -DelegateComputer $DelegateComputer -Force | Out-Null
                                if ($SuppressReboot -eq $false)
                                {
                                   $global:DSCMachineStatus = 1
                                }
                            }
                        }
                    }
                    else
                    {
                        Throw "DelegateComputers is required!"
                    }
                }
                "Absent"
                {
                    Disable-WSManCredSSP -Role Client | Out-Null
                }
            }
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateSet("Server","Client")]
        [System.String]
        $Role,

        [System.String[]]
        $DelegateComputers,

        [System.Boolean]
        $SuppressReboot = $false    
    )

    if ($Role -eq "Server" -and $PSBoundParameters.ContainsKey("DelegateComputers")) 
    {
        Write-Verbose -Message ("Cannot use the Role=Server parameter together with " + `
                                "the DelegateComputers parameter")
    }

    $CredSSP = Get-TargetResource -Role $Role

    switch($Role)
    {
        "Server"
        {
            return ($CredSSP.Ensure -eq $Ensure)
        }
        "Client"
        {
            switch($Ensure)
            {
                "Present"
                {
                    $CorrectDelegateComputers = $true
                    if($DelegateComputers)
                    {
                        foreach($DelegateComputer in $DelegateComputers)
                        {
                            if(!($CredSSP.DelegateComputers | Where-Object {$_ -eq $DelegateComputer}))
                            {
                                $CorrectDelegateComputers = $false
                            }
                        }
                    }
                    $result = (($CredSSP.Ensure -eq $Ensure) -and $CorrectDelegateComputers)
                }
                "Absent"
                {
                    $result = ($CredSSP.Ensure -eq $Ensure)
                }
            }
        }
    }

    return $result
}


Export-ModuleMember -Function *-TargetResource


function Test-RegistryValue
{
    param (
        [Parameter(Mandatory = $true)]
        [String]$Path
        ,
        [Parameter(Mandatory = $true)]
        [String]$Name
    )
    
    if ($null -eq $Path)
    {
        return $false
    }

    $itemProperties = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
    return ($null -ne $itemProperties -and $null -ne $itemProperties.$Name)
}
