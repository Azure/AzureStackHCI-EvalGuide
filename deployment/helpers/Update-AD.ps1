$targetHost = $env:COMPUTERNAME
$AzureStackHCIHosts = Get-VM -Name "*AZSHCINODE*"
$AzureStackHCIClusterName = "AZSHCICLUS"
$ouName = "AzSHCICluster"

$dn = Get-ADOrganizationalUnit -Filter * | Where-Object name -eq $ouName
if (-not ($dn)) {
    $dn = New-ADOrganizationalUnit -Name $ouName -PassThru
}
        
#Get Wac Computer Object
$targetHostObject = Get-ADComputer -Filter * | Where-Object name -eq $targetHost
if (-not ($targetHostObject)) {
    $targetHostObject = New-ADComputer -Name $targetHost -Enabled $false -PassThru
}

# Creates Azure Stack HCI hosts if not exist
if ($AzureStackHCIHosts.Name) {
    $AzureStackHCIHosts.Name | ForEach-Object {
        $comp = Get-ADComputer -Filter * | Where-Object Name -eq $_
        if (-not ($comp)) {
            New-ADComputer -Name $_ -Enabled $false -Path $dn -PrincipalsAllowedToDelegateToAccount $targetHostObject
        }
        else {
            $comp | Set-ADComputer -PrincipalsAllowedToDelegateToAccount $targetHostObject
            $comp | Move-AdObject -TargetPath $dn
        }
    }
}

# Creates Azure Stack HCI Cluster CNO if not exist
$AzureStackHCIClusterObject = Get-ADComputer -Filter * | Where-Object name -eq $AzureStackHCIClusterName
if (-not ($AzureStackHCIClusterObject)) {
    $AzureStackHCIClusterObject = New-ADComputer -Name $AzureStackHCIClusterName -Enabled $false `
        -Path $dn -PrincipalsAllowedToDelegateToAccount $targetHostObject -PassThru
}
else {
    $AzureStackHCIClusterObject | Set-ADComputer -PrincipalsAllowedToDelegateToAccount $targetHostObject
    $AzureStackHCIClusterObject | Move-AdObject -TargetPath $dn
}

#read OU DACL
$acl = Get-Acl -Path "AD:\$dn"

# Set properties to allow Cluster CNO to Full Control on the new OU
$principal = New-Object System.Security.Principal.SecurityIdentifier ($AzureStackHCIClusterObject).SID
$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($principal, `
        [System.DirectoryServices.ActiveDirectoryRights]::GenericAll, [System.Security.AccessControl.AccessControlType]::Allow, `
        [DirectoryServices.ActiveDirectorySecurityInheritance]::All)

#modify DACL
$acl.AddAccessRule($ace)

#Re-apply the modified DACL to the OU
Set-ACL -ACLObject $acl -Path "AD:\$dn"