function New-BasicUnattendXML
{

[CmdletBinding(DefaultParameterSetName='basic')]

Param (

    [Parameter(Mandatory=$true, ParameterSetName='print')]
    [Parameter(Mandatory=$true, ParameterSetName='basic')]
    [Parameter(Mandatory=$true, ParameterSetName='Join Domain')]
    [String]$ComputerName,

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$true, ParameterSetName='Join Domain')]    
    [String]$Domain,
    
    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$true, ParameterSetName='Join Domain')]
    [String]$Username,

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$true, ParameterSetName='Join Domain')]
    [SecureString]$Password,

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$true, ParameterSetName='basic')]
    [Parameter(Mandatory=$true, ParameterSetName='Join Domain')]
    [SecureString]$LocalAdministratorPassword,
    
    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$true, ParameterSetName='Join Domain')]
    [String]$JoinDomain,
    
    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]    
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [validatescript({(([system.net.ipaddress]($_ -split '/' | Select-Object -First 1)).AddressFamily -match 'InterNetwork') -and (0..32 -contains ([int]($_ -split '/' | Select-Object -Last 1) )) })] 
    [String]$IpCidr,
    
    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [String]$DefaultGateway,
    
    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [String]$DnsServer,

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [String]$NicNameForIPandDNSAssignments,

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$true, ParameterSetName='basic')]
    [Parameter(Mandatory=$true, ParameterSetName='Join Domain')]
    [String]$OutputPath,

    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [Switch]$Force,

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [System.Globalization.CultureInfo]$InputLocale = 'en-us',

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [System.Globalization.CultureInfo]$SystemLocale = 'en-us',

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [System.Globalization.CultureInfo]$UILanguage = 'en-us',

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [System.Globalization.CultureInfo]$UserLocale = 'en-us',

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [bool]$HideEULAPage = $true,

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [ValidateScript({$_ -in (Get-TimeZone -ListAvailable | Select-Object -ExpandProperty standardname)})]
    [String]$TimeZone = 'GMT Standard Time',

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [ValidateRange(0,100)]
    [int]$AutoLogonCount = 0,
    
    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [String]$RegisteredOrganization = 'Azure Stack HCI on Azure VM',
    
    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [String]$RegisteredOwner = 'Azure Stack HCI on Azure VM',
    
    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [String]$PowerShellScriptFullPath,

    [Parameter(Mandatory=$false, ParameterSetName='print')]
    [Parameter(Mandatory=$false, ParameterSetName='basic')]
    [Parameter(Mandatory=$false, ParameterSetName='Join Domain')]
    [Switch]$PrintScreenOnly
)

        $localAdministratorCreds = New-Object pscredential -ArgumentList Administrator, $LocalAdministratorPassword
        $LocalAdministratorPasswordClearText = $localAdministratorCreds.GetNetworkCredential().password
        $encodedAdministratorPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(('{0}AdministratorPassword' -f $LocalAdministratorPasswordClearText)))
        
        if ($JoinDomain)
        {
            $domainJoinerCreds = New-Object pscredential -ArgumentList Administrator, $LocalAdministratorPassword
            $domainJoinerPasswordClearText = $domainJoinerCreds.GetNetworkCredential().password
            $domainJoinXMLString = @"

   <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <Identification>
     <Credentials>
      <Domain>$Domain</Domain>
      <Password>$domainJoinerPasswordClearText</Password>
      <Username>$username</Username>
     </Credentials>
     <JoinDomain>$joinDomain</JoinDomain>
    </Identification>
   </component>
"@
        }
        else
        {
            $domainJoinXMLString = $null
        }

        $PowerShellStartupCmd = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PowerShellScriptFullPath"

        if ($AutoLogonCount -gt 0)
        {
            Write-Warning -Message '-AutoLogonCount places the Administrator password in plain txt'
            $autoLogonXMLString = @"

      <AutoLogon>
        <Password>
          <Value>$LocalAdministratorPasswordClearText</Value>
        </Password>
        <LogonCount>$AutoLogonCount</LogonCount>
        <Username>Administrator</Username>
        <Enabled>true</Enabled>
      </AutoLogon>
"@
        }
        else
        {
            $autoLogonXMLString = $null
        }
        if ($IpCidr){
            $IPAddressXMLString = @"

    <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Interfaces>
        <Interface wcm:action="add">
          <Identifier>$NicNameForIPandDNSAssignments</Identifier>
          <UnicastIPAddresses>
            <IpAddress wcm:action="add" wcm:keyValue="1">$IpCidr</IpAddress>
          </UnicastIPAddresses>
          <Routes>
            <Route wcm:action="add">
              <Identifier>1</Identifier>
              <Prefix>0.0.0.0/0</Prefix>
              <Metric>10</Metric>
              <NextHopAddress>$DefaultGateway</NextHopAddress>
            </Route>
          </Routes>
          <IPv4Settings>
            <DhcpEnabled>false</DhcpEnabled>
          </IPv4Settings>
        </Interface>
      </Interfaces>
    </component>
"@
        }
        else
        {
            $IPAddressXMLString = $null
        }
        if ($DnsServer)
        {
            $DnsAddressXMLString = @"

   <component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <Interfaces>
     <Interface wcm:action="add">
        <Identifier>$NicNameForIPandDNSAssignments</Identifier>
         <DNSServerSearchOrder>
          <IpAddress wcm:action="add" wcm:keyValue="1">$DnsServer</IpAddress>
         </DNSServerSearchOrder>
        <EnableAdapterDomainNameRegistration>true</EnableAdapterDomainNameRegistration>
        <DisableDynamicUpdate>false</DisableDynamicUpdate>
     </Interface>
    </Interfaces>
   </component>
"@
        }
        else
        {
            $DnsAddressXMLString = $null
        }

        if ($PowerShellScriptFullPath)
        {
            $logonScriptXMLString = @"

      <FirstLogonCommands>
        <SynchronousCommand wcm:action="add">
          <Description>PowerShell First logon script</Description>
          <Order>1</Order>
          <CommandLine>$PowerShellStartupCmd</CommandLine>
          <RequiresUserInput>false</RequiresUserInput>
        </SynchronousCommand>
      </FirstLogonCommands>        
"@
        }
        else
        {
            $logonScriptXMLString = $null
        }

        $unattend = @"

<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="specialize">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    </component>
    <component name="Microsoft-Windows-Deployment" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <ComputerName>$computerName</ComputerName>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <ComputerName>$computerName</ComputerName>
    </component>$IPAddressXMLString$DnsAddressXMLString$domainJoinXMLString
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>$InputLocale</InputLocale>
      <SystemLocale>$SystemLocale</SystemLocale>
      <UILanguage>$UILanguage</UILanguage>
      <UserLocale>$UserLocale</UserLocale>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>$InputLocale</InputLocale>
      <SystemLocale>$SystemLocale</SystemLocale>
      <UILanguage>$UILanguage</UILanguage>
      <UserLocale>$UserLocale</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <OOBE>
        <HideEULAPage>$HideEULAPage</HideEULAPage>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
        <SkipUserOOBE>true</SkipUserOOBE>
        <SkipMachineOOBE>true</SkipMachineOOBE>
      </OOBE>
      <TimeZone>$TimeZone</TimeZone>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$encodedAdministratorPassword</Value>
          <PlainText>false</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <RegisteredOrganization>$RegisteredOrganization</RegisteredOrganization>
      <RegisteredOwner>$RegisteredOrganization</RegisteredOwner>$autoLogonXMLString$logonScriptXMLString
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <OOBE>
        <HideEULAPage>$HideEULAPage</HideEULAPage>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
        <SkipUserOOBE>true</SkipUserOOBE>
        <SkipMachineOOBE>true</SkipMachineOOBE>
      </OOBE>
      <TimeZone>$TimeZone</TimeZone>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$encodedAdministratorPassword</Value>
          <PlainText>false</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <RegisteredOrganization>$RegisteredOrganization</RegisteredOrganization>
      <RegisteredOwner>$RegisteredOrganization</RegisteredOwner>$autoLogonXMLString$logonScriptXMLString
    </component>
  </settings>
</unattend>
"@


    try
    {
        $path = Resolve-Path -Path $OutputPath -ErrorAction Stop
        $file = (Join-Path -Path $path -ChildPath 'Unattend.xml')
    
        $fileExist = Test-Path -Path $file
        if ($fileExist -and $Force)
        {
            Write-Verbose -Message "Overwriting $file, Force switch was enabled."
            $confirm = $false
            $operation = 'Overridden'
        }
        elseif ($fileExist)
        {
            Write-Verbose -Message "$file deletion will be prompted."
            $confirm = $true
            $operation = 'Overridden'
        }
        else
        {
            Write-Verbose -Message "Creating Unattend.xml file in $OutputPath"
            $confirm = $false
            $operation = 'created'
        }
        if ($PrintScreenOnly)
        {
            return $unattend
        }
            Remove-Item -Path $file -Confirm:$confirm -ErrorAction SilentlyContinue
            Set-Content -Path $file -Value $unattend
            Write-Output "File $($operation): $file"
    }
    finally
    {
        Remove-Variable -Name unattend, LocalAdministratorPasswordClearText, encodedAdministratorPassword, domainJoinerPasswordClearText -ErrorAction SilentlyContinue
    }

}
Export-ModuleMember -Function New-BasicUnattendXML