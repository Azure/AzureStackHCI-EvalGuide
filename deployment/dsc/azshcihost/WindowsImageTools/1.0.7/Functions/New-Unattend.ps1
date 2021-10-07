function New-UnattendXml
{
    <#
            .Synopsis
            Create a new Unattend.xml 
            .DESCRIPTION
            This Command Creates a new Unattend.xml that skips any prompts, and sets the administrator password
            Has options for: Adding user accounts
            Auto logon a set number of times
            Set the Computer Name
            First Boot or First Logon powersrhell script
            Product Key
            TimeZone
            Input, System and User Locals
            UI Language
            Registered Owner and Orginization
            First Boot, First Logon and Every Logon Commands
            Enable Administrator account without autologon (client OS)

            If no Path is provided a the file will be created in a temp folder and the path returned.
            .EXAMPLE
            New-UnattendXml -AdminPassword 'P@ssword' -logonCount 1
            .EXAMPLE
            New-UnattendXml -Path c:\temp\Unattent.xml -AdminPassword 'P@ssword' -logonCount 100 -FirstLogonScriptPath c:\pstemp\firstrun.ps1
    #>
    [CmdletBinding(DefaultParameterSetName = 'Basic_FirstLogonScript',
    SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    Param
    (
        # The password to have unattnd.xml set the local Administrator to (minimum lenght 8)
        [Parameter(Mandatory = $true, 
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true, 
        Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('AdminPassword')] 
        [PSCredential]
        $AdminCredential,

        # User account/password to create and add to Administators group
        [PSCredential[]]
        $UserAccount,

        # Output Path 
        [Alias('FilePath', 'FullName', 'pspath', 'outfile')]
        [string]
        $Path = "$(New-TemporaryDirectory)\unattend.xml",

        # Number of times that the local Administrator account should automaticaly login (default 0)        
        [ValidateRange(0,1000)] 
        [int]
        $LogonCount,

        # ComputerName (default = *)
        [ValidateLength(1,15)]
        [string]
        $ComputerName = '*',

        # PowerShell Script to run on FirstLogon (ie. %SystemDrive%\PSTemp\FirstRun.ps1 )
        [Parameter(ParameterSetName = 'Basic_FirstLogonScript')]
        [string]
        $FirstLogonScriptPath,

        # PowerShell Script to run on FirstBoot (ie.: %SystemDrive%\PSTemp\FirstRun.ps1 ) Executed in system context dureing specialize phase
        [Parameter(ParameterSetName = 'Basic_FirstBootScript')]
        [string]
        $FirstBootScriptPath,

        # The product key to use for the unattended installation.
        [ValidatePattern('^[A-Z0-9]{5,5}-[A-Z0-9]{5,5}-[A-Z0-9]{5,5}-[A-Z0-9]{5,5}-[A-Z0-9]{5,5}$')]
        [string]
        $ProductKey,

        # Timezone (default: Central Standard Time) 
        [ValidateSet('Dateline Standard Time', 
                'UTC-11', 
                'Hawaiian Standard Time', 
                'Alaskan Standard Time', 
                'Pacific Standard Time (Mexico)', 
                'Pacific Standard Time', 
                'US Mountain Standard Time', 
                'Mountain Standard Time (Mexico)', 
                'Mountain Standard Time', 
                'Central America Standard Time', 
                'Central Standard Time', 
                'Central Standard Time (Mexico)', 
                'Canada Central Standard Time', 
                'SA Pacific Standard Time', 
                'Eastern Standard Time (Mexico)', 
                'Eastern Standard Time', 
                'US Eastern Standard Time', 
                'Venezuela Standard Time', 
                'Paraguay Standard Time', 
                'Atlantic Standard Time', 
                'Central Brazilian Standard Time', 
                'SA Western Standard Time', 
                'Newfoundland Standard Time', 
                'E. South America Standard Time', 
                'SA Eastern Standard Time', 
                'Argentina Standard Time', 
                'Greenland Standard Time', 
                'Montevideo Standard Time', 
                'Bahia Standard Time', 
                'Pacific SA Standard Time', 
                'UTC-02', 
                'Mid-Atlantic Standard Time', 
                'Azores Standard Time', 
                'Cape Verde Standard Time', 
                'Morocco Standard Time', 
                'UTC', 
                'GMT Standard Time', 
                'Greenwich Standard Time', 
                'W. Europe Standard Time', 
                'Central Europe Standard Time', 
                'Romance Standard Time', 
                'Central European Standard Time', 
                'W. Central Africa Standard Time', 
                'Namibia Standard Time', 
                'Jordan Standard Time', 
                'GTB Standard Time', 
                'Middle East Standard Time', 
                'Egypt Standard Time', 
                'Syria Standard Time', 
                'E. Europe Standard Time', 
                'South Africa Standard Time', 
                'FLE Standard Time', 
                'Turkey Standard Time', 
                'Israel Standard Time', 
                'Kaliningrad Standard Time', 
                'Libya Standard Time', 
                'Arabic Standard Time', 
                'Arab Standard Time', 
                'Belarus Standard Time', 
                'Russian Standard Time', 
                'E. Africa Standard Time', 
                'Iran Standard Time', 
                'Arabian Standard Time', 
                'Azerbaijan Standard Time', 
                'Russia Time Zone 3', 
                'Mauritius Standard Time', 
                'Georgian Standard Time', 
                'Caucasus Standard Time', 
                'Afghanistan Standard Time', 
                'West Asia Standard Time', 
                'Ekaterinburg Standard Time', 
                'Pakistan Standard Time', 
                'India Standard Time', 
                'Sri Lanka Standard Time', 
                'Nepal Standard Time', 
                'Central Asia Standard Time', 
                'Bangladesh Standard Time', 
                'N. Central Asia Standard Time', 
                'Myanmar Standard Time', 
                'SE Asia Standard Time', 
                'North Asia Standard Time', 
                'China Standard Time', 
                'North Asia East Standard Time', 
                'Singapore Standard Time', 
                'W. Australia Standard Time', 
                'Taipei Standard Time', 
                'Ulaanbaatar Standard Time', 
                'North Korea Standard Time', 
                'Tokyo Standard Time', 
                'Korea Standard Time', 
                'Yakutsk Standard Time', 
                'Cen. Australia Standard Time', 
                'AUS Central Standard Time', 
                'E. Australia Standard Time', 
                'AUS Eastern Standard Time', 
                'West Pacific Standard Time', 
                'Tasmania Standard Time', 
                'Magadan Standard Time', 
                'Vladivostok Standard Time', 
                'Russia Time Zone 10', 
                'Central Pacific Standard Time', 
                'Russia Time Zone 11', 
                'New Zealand Standard Time', 
                'UTC+12', 
                'Fiji Standard Time', 
                'Kamchatka Standard Time', 
                'Tonga Standard Time', 
                'Samoa Standard Time', 
        'Line Islands Standard Time')]
        [string]
        $TimeZone,

        # Specifies the system input locale and the keyboard layout (default: en-US)
        [Parameter(ValueFromPipelineByPropertyName)] 
        [ValidateSet('en-US',
                'nl-NL',
                'fr-FR',
                'de-DE',
                'it-IT',
                'ja-JP',
                'es-ES',
                'ar-SA',
                'zh-CN',
                'zh-HK',
                'zh-TW',
                'cs-CZ',
                'da-DK',
                'fi-FI',
                'el-GR',
                'he-IL',
                'hu-HU',
                'ko-KR',
                'nb-NO',
                'pl-PL',
                'pt-BR',
                'pt-PT',
                'ru-RU',
                'sv-SE',
                'tr-TR',
                'bg-BG',
                'hr-HR',
                'et-EE',
                'lv-LV',
                'lt-LT',
                'ro-RO',
                'sr-Latn-CS',
                'sk-SK',
                'sl-SI',
                'th-TH',
                'uk-UA',
                'af-ZA',
                'sq-AL',
                'am-ET',
                'hy-AM',
                'as-IN',
                'az-Latn-AZ',
                'eu-ES',
                'be-BY',
                'bn-BD',
                'bn-IN',
                'bs-Cyrl-BA',
                'bs-Latn-BA',
                'ca-ES',
                'fil-PH',
                'gl-ES',
                'ka-GE',
                'gu-IN',
                'ha-Latn-NG',
                'hi-IN',
                'is-IS',
                'ig-NG',
                'id-ID',
                'iu-Latn-CA',
                'ga-IE',
                'xh-ZA',
                'zu-ZA',
                'kn-IN',
                'kk-KZ',
                'km-KH',
                'rw-RW',
                'sw-KE',
                'kok-IN',
                'ky-KG',
                'lo-LA',
                'lb-LU',
                'mk-MK',
                'ms-BN',
                'ms-MY',
                'ml-IN',
                'mt-MT',
                'mi-NZ',
                'mr-IN',
                'ne-NP',
                'nn-NO',
                'or-IN',
                'ps-AF',
                'fa-IR',
                'pa-IN',
                'quz-PE',
                'sr-Cyrl-CS',
                'nso-ZA',
                'tn-ZA',
                'si-LK',
                'ta-IN',
                'tt-RU',
                'te-IN',
                'ur-PK',
                'uz-Latn-UZ',
                'vi-VN',
                'cy-GB',
                'wo-SN',
        'yo-NG')]
        [Alias('keyboardlayout')]
        [String] 
        $InputLocale,

        # Specifies the language for non-Unicode programs (default: en-US)
        [ValidateSet('en-US',
                'nl-NL',
                'fr-FR',
                'de-DE',
                'it-IT',
                'ja-JP',
                'es-ES',
                'ar-SA',
                'zh-CN',
                'zh-HK',
                'zh-TW',
                'cs-CZ',
                'da-DK',
                'fi-FI',
                'el-GR',
                'he-IL',
                'hu-HU',
                'ko-KR',
                'nb-NO',
                'pl-PL',
                'pt-BR',
                'pt-PT',
                'ru-RU',
                'sv-SE',
                'tr-TR',
                'bg-BG',
                'hr-HR',
                'et-EE',
                'lv-LV',
                'lt-LT',
                'ro-RO',
                'sr-Latn-CS',
                'sk-SK',
                'sl-SI',
                'th-TH',
                'uk-UA',
                'af-ZA',
                'sq-AL',
                'am-ET',
                'hy-AM',
                'as-IN',
                'az-Latn-AZ',
                'eu-ES',
                'be-BY',
                'bn-BD',
                'bn-IN',
                'bs-Cyrl-BA',
                'bs-Latn-BA',
                'ca-ES',
                'fil-PH',
                'gl-ES',
                'ka-GE',
                'gu-IN',
                'ha-Latn-NG',
                'hi-IN',
                'is-IS',
                'ig-NG',
                'id-ID',
                'iu-Latn-CA',
                'ga-IE',
                'xh-ZA',
                'zu-ZA',
                'kn-IN',
                'kk-KZ',
                'km-KH',
                'rw-RW',
                'sw-KE',
                'kok-IN',
                'ky-KG',
                'lo-LA',
                'lb-LU',
                'mk-MK',
                'ms-BN',
                'ms-MY',
                'ml-IN',
                'mt-MT',
                'mi-NZ',
                'mr-IN',
                'ne-NP',
                'nn-NO',
                'or-IN',
                'ps-AF',
                'fa-IR',
                'pa-IN',
                'quz-PE',
                'sr-Cyrl-CS',
                'nso-ZA',
                'tn-ZA',
                'si-LK',
                'ta-IN',
                'tt-RU',
                'te-IN',
                'ur-PK',
                'uz-Latn-UZ',
                'vi-VN',
                'cy-GB',
                'wo-SN',
        'yo-NG')]
        [Parameter(ValueFromPipelineByPropertyName)] 
        [String] 
        $SystemLocale,

        # Specifies the per-user settings used for formatting dates, times, currency and numbers (default: en-US)
        [ValidateSet('en-US',
                'nl-NL',
                'fr-FR',
                'de-DE',
                'it-IT',
                'ja-JP',
                'es-ES',
                'ar-SA',
                'zh-CN',
                'zh-HK',
                'zh-TW',
                'cs-CZ',
                'da-DK',
                'fi-FI',
                'el-GR',
                'he-IL',
                'hu-HU',
                'ko-KR',
                'nb-NO',
                'pl-PL',
                'pt-BR',
                'pt-PT',
                'ru-RU',
                'sv-SE',
                'tr-TR',
                'bg-BG',
                'hr-HR',
                'et-EE',
                'lv-LV',
                'lt-LT',
                'ro-RO',
                'sr-Latn-CS',
                'sk-SK',
                'sl-SI',
                'th-TH',
                'uk-UA',
                'af-ZA',
                'sq-AL',
                'am-ET',
                'hy-AM',
                'as-IN',
                'az-Latn-AZ',
                'eu-ES',
                'be-BY',
                'bn-BD',
                'bn-IN',
                'bs-Cyrl-BA',
                'bs-Latn-BA',
                'ca-ES',
                'fil-PH',
                'gl-ES',
                'ka-GE',
                'gu-IN',
                'ha-Latn-NG',
                'hi-IN',
                'is-IS',
                'ig-NG',
                'id-ID',
                'iu-Latn-CA',
                'ga-IE',
                'xh-ZA',
                'zu-ZA',
                'kn-IN',
                'kk-KZ',
                'km-KH',
                'rw-RW',
                'sw-KE',
                'kok-IN',
                'ky-KG',
                'lo-LA',
                'lb-LU',
                'mk-MK',
                'ms-BN',
                'ms-MY',
                'ml-IN',
                'mt-MT',
                'mi-NZ',
                'mr-IN',
                'ne-NP',
                'nn-NO',
                'or-IN',
                'ps-AF',
                'fa-IR',
                'pa-IN',
                'quz-PE',
                'sr-Cyrl-CS',
                'nso-ZA',
                'tn-ZA',
                'si-LK',
                'ta-IN',
                'tt-RU',
                'te-IN',
                'ur-PK',
                'uz-Latn-UZ',
                'vi-VN',
                'cy-GB',
                'wo-SN',
        'yo-NG')]
        [Parameter(ValueFromPipelineByPropertyName)] 
        [String] 
        $UserLocale,

        # Specifies the system default user interface (UI) language (default: en-US)
        [ValidateSet('en-US',
                'nl-NL',
                'fr-FR',
                'de-DE',
                'it-IT',
                'ja-JP',
                'es-ES',
                'ar-SA',
                'zh-CN',
                'zh-HK',
                'zh-TW',
                'cs-CZ',
                'da-DK',
                'fi-FI',
                'el-GR',
                'he-IL',
                'hu-HU',
                'ko-KR',
                'nb-NO',
                'pl-PL',
                'pt-BR',
                'pt-PT',
                'ru-RU',
                'sv-SE',
                'tr-TR',
                'bg-BG',
                'hr-HR',
                'et-EE',
                'lv-LV',
                'lt-LT',
                'ro-RO',
                'sr-Latn-CS',
                'sk-SK',
                'sl-SI',
                'th-TH',
                'uk-UA',
                'af-ZA',
                'sq-AL',
                'am-ET',
                'hy-AM',
                'as-IN',
                'az-Latn-AZ',
                'eu-ES',
                'be-BY',
                'bn-BD',
                'bn-IN',
                'bs-Cyrl-BA',
                'bs-Latn-BA',
                'ca-ES',
                'fil-PH',
                'gl-ES',
                'ka-GE',
                'gu-IN',
                'ha-Latn-NG',
                'hi-IN',
                'is-IS',
                'ig-NG',
                'id-ID',
                'iu-Latn-CA',
                'ga-IE',
                'xh-ZA',
                'zu-ZA',
                'kn-IN',
                'kk-KZ',
                'km-KH',
                'rw-RW',
                'sw-KE',
                'kok-IN',
                'ky-KG',
                'lo-LA',
                'lb-LU',
                'mk-MK',
                'ms-BN',
                'ms-MY',
                'ml-IN',
                'mt-MT',
                'mi-NZ',
                'mr-IN',
                'ne-NP',
                'nn-NO',
                'or-IN',
                'ps-AF',
                'fa-IR',
                'pa-IN',
                'quz-PE',
                'sr-Cyrl-CS',
                'nso-ZA',
                'tn-ZA',
                'si-LK',
                'ta-IN',
                'tt-RU',
                'te-IN',
                'ur-PK',
                'uz-Latn-UZ',
                'vi-VN',
                'cy-GB',
                'wo-SN',
        'yo-NG')]
        [Parameter(ValueFromPipelineByPropertyName)] 
        [String] 
        $UILanguage,

        # Registered Owner (default: 'Valued Customer')
        [Parameter(ValueFromPipelineByPropertyName)] 
        [ValidateNotNull()] 
        [String] 
        $RegisteredOwner,

        # Registered Organization (default: 'Valued Customer')
        [Parameter(ValueFromPipelineByPropertyName)] 
        [ValidateNotNull()] 
        [String] 
        $RegisteredOrganization,

        # Array of hashtables with Description, Order, and Path keys, and optional Domain, Password(plain text), username keys. Executed by in the system context 
        [Parameter(ValueFromPipelineByPropertyName = $true, 
        ParameterSetName = 'Advanced')] 
        [Hashtable[]] 
        $FirstBootExecuteCommand,

        # Array of hashtables with Description, Order and CommandLine keys. Execuded at first logon of an Administrator, will auto elivate
        [Parameter(ValueFromPipelineByPropertyName = $true, 
        ParameterSetName = 'Advanced')] 
        [Hashtable[]] 
        $FirstLogonExecuteCommand,

        # Array of hashtables with Description, Order and CommandLine keys. Executed at every logon, does not elivate.
        [Parameter(ValueFromPipelineByPropertyName = $true, 
        ParameterSetName = 'Advanced')] 
        [Hashtable[]] 
        $EveryLogonExecuteCommand,

        # Enable Local Administrator account (default $true) this is needed for client OS if your not useing autologon or adding aditional admin users.
        [switch]
        $enableAdministrator 
    )

    Begin
    {
        $templateUnattendXml = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
		<component name="Microsoft-Windows-Deployment" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
		<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
		<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></component>
    </settings>
    <settings pass="oobeSystem">
		<component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
		<component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
				<SkipUserOOBE>true</SkipUserOOBE>
				<SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
            <TimeZone>GMT Standard Time</TimeZone>
            <UserAccounts>
                <AdministratorPassword>
                    <Value></Value>
                    <PlainText>false</PlainText>
                </AdministratorPassword>
             </UserAccounts>
            <RegisteredOrganization>Generic Organization</RegisteredOrganization>
            <RegisteredOwner>Generic Owner</RegisteredOwner>
        </component>
		<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
				<SkipUserOOBE>true</SkipUserOOBE>
				<SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
            <TimeZone>GMT Standard Time</TimeZone>
            <UserAccounts>
                <AdministratorPassword>
                    <Value></Value>
                    <PlainText>false</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <RegisteredOrganization>Generic Organization</RegisteredOrganization>
            <RegisteredOwner>Generic Owner</RegisteredOwner>
        </component>
    </settings>
</unattend>
'@

        $PowerShellStartupCmd = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File'

        if ($LogonCount -gt 0)
        {
            Write-Warning -Message '-Autologon places the Administrator password in plain txt'
        }
    }
    Process
    {
        if ($pscmdlet.ShouldProcess('$path', 'Create new Unattended.xml'))
        {
            if ($FirstBootScriptPath)
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding PowerShell script to First boot command"
                $FirstBootExecuteCommand = @(@{
                        Description = 'PowerShell First boot script'
                        order       = 1
                        path        = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FirstBootScriptPath`""
                })
            }

            if ($FirstLogonScriptPath)
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding PowerShell script to First Logon command"
                $FirstLogonExecuteCommand = @(@{
                        Description = 'PowerShell First logon script'
                        order       = 1
                        CommandLine = "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FirstBootScriptPath`""
                })
            }
     
            if ($enableAdministrator)
            {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Enabeling Administrator via First boot command"
                if ($FirstBootExecuteCommand)
                {
                    $FirstBootExecuteCommand = $FirstBootExecuteCommand + @{
                        Description = 'Enable Administrator'
                        order       = 0
                        path        = 'net user administrator /active:yes'
                    }
                }
                else 
                {
                    $FirstBootExecuteCommand = @{
                        Description = 'Enable Administrator'
                        order       = 0
                        path        = 'net user administrator /active:yes'
                    }
                }
            }
            else
            {
                if (-not ($UserAccount) )
                {
                    Write-Warning -Message "$Path only usable on a server SKU, for a client OS, use either -EnableAdministrator or -UserAccount"
                }
            }

            [xml] $unattendXml = $templateUnattendXml
            foreach ($setting in $unattendXml.Unattend.Settings) 
            {
                foreach($component in $setting.Component) 
                {
                    if ($setting.'Pass' -eq 'specialize' -and $component.'Name' -eq 'Microsoft-Windows-Deployment' ) 
                    {
                        if (($FirstBootExecuteCommand -ne $null -or $FirstBootExecuteCommand.Length -gt 0) -and $component.'processorArchitecture' -eq 'x86') 
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding first boot command(s)"
                            $commandOrder = 1
                            $runSynchronousElement = $component.AppendChild($unattendXml.CreateElement('RunSynchronous','urn:schemas-microsoft-com:unattend'))
                            foreach ($synchronousCommand in ($FirstBootExecuteCommand | Sort-Object -Property {
                                        $_.order
                            })) 
                            {
                                $syncCommandElement = $runSynchronousElement.AppendChild($unattendXml.CreateElement('RunSynchronousCommand','urn:schemas-microsoft-com:unattend'))
                                $null = $syncCommandElement.SetAttribute('action','http://schemas.microsoft.com/WMIConfig/2002/State','add')
                                $syncCommandDescriptionElement = $syncCommandElement.AppendChild($unattendXml.CreateElement('Description','urn:schemas-microsoft-com:unattend'))
                                $syncCommandDescriptionTextNode = $syncCommandDescriptionElement.AppendChild($unattendXml.CreateTextNode($synchronousCommand['Description']))
                                $syncCommandOrderElement = $syncCommandElement.AppendChild($unattendXml.CreateElement('Order','urn:schemas-microsoft-com:unattend'))
                                $syncCommandOrderTextNode = $syncCommandOrderElement.AppendChild($unattendXml.CreateTextNode($commandOrder))
                                $syncCommandPathElement = $syncCommandElement.AppendChild($unattendXml.CreateElement('Path','urn:schemas-microsoft-com:unattend'))
                                $syncCommandPathTextNode = $syncCommandPathElement.AppendChild($unattendXml.CreateTextNode($synchronousCommand['Path']))
                                $commandOrder++
                            }
                        }
                    }
                    if (($setting.'Pass' -eq 'specialize') -and ($component.'Name' -eq 'Microsoft-Windows-Shell-Setup')) 
                    {
                        if ($ComputerName) 
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding custom computername for $($component.'processorArchitecture') Architecture"
                            $computerNameElement = $component.AppendChild($unattendXml.CreateElement('ComputerName','urn:schemas-microsoft-com:unattend'))
                            $computerNameTextNode = $computerNameElement.AppendChild($unattendXml.CreateTextNode($ComputerName))
                        }
                        if ($ProductKey) 
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Product key for $($component.'processorArchitecture') Architecture"
                            $productKeyElement = $component.AppendChild($unattendXml.CreateElement('ProductKey','urn:schemas-microsoft-com:unattend'))
                            $productKeyTextNode = $productKeyElement.AppendChild($unattendXml.CreateTextNode($ProductKey.ToUpper()))
                        }
                    }
              
                    if (($setting.'Pass' -eq 'oobeSystem') -and ($component.'Name' -eq 'Microsoft-Windows-International-Core')) 
                    {
                        if ($InputLocale)
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Input Locale for $($component.'processorArchitecture') Architecture"
                            $component.InputLocale = $InputLocale
                        }
                        if ($SystemLocale)
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding System Locale for $($component.'processorArchitecture') Architecture"
                            $component.SystemLocale = $SystemLocale
                        }
                        if ($UILanguage)
                        { 
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding UI Language for $($component.'processorArchitecture') Architecture"
                            $component.UILanguage = $UILanguage
                        }
                        if ($UserLocale)
                        { 
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding User Locale for $($component.'processorArchitecture') Architecture"
                            $component.UserLocale = $UserLocale
                        }
                    }
              
                    if (($setting.'Pass' -eq 'oobeSystem') -and ($component.'Name' -eq 'Microsoft-Windows-Shell-Setup')) 
                    {
                        if ($TimeZone)
                        { 
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Time Zone for $($component.'processorArchitecture') Architecture"
                            $component.TimeZone = $TimeZone
                        }
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Administrator Passwords for $($component.'processorArchitecture') Architecture"
                        $concatenatedPassword = '{0}AdministratorPassword' -f $AdminCredential.GetNetworkCredential().password
                        $component.UserAccounts.AdministratorPassword.Value = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($concatenatedPassword))
                        if ($RegisteredOrganization)
                        { 
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Registred Organization for $($component.'processorArchitecture') Architecture"
                            $component.RegisteredOrganization = $RegisteredOrganization
                        }
                        if ($RegisteredOwner)
                        { 
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Registered Owner for $($component.'processorArchitecture') Architecture"
                            $component.RegisteredOwner = $RegisteredOwner
                        }
                        if ($UserAccount)
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding User Account(s) for $($component.'processorArchitecture') Architecture"
                            $UserAccountsElement = $component.UserAccounts
                            $LocalAccountsElement = $UserAccountsElement.AppendChild($unattendXml.CreateElement('LocalAccounts','urn:schemas-microsoft-com:unattend'))
                            foreach ($Account in $UserAccount) 
                            {
                                $LocalAccountElement = $LocalAccountsElement.AppendChild($unattendXml.CreateElement('LocalAccount','urn:schemas-microsoft-com:unattend'))
                                $LocalAccountPasswordElement = $LocalAccountElement.AppendChild($unattendXml.CreateElement('Password','urn:schemas-microsoft-com:unattend'))
                                $LocalAccountPasswordValueElement = $LocalAccountPasswordElement.AppendChild($unattendXml.CreateElement('Value','urn:schemas-microsoft-com:unattend'))
                                $LocalAccountPasswordPlainTextElement = $LocalAccountPasswordElement.AppendChild($unattendXml.CreateElement('PlainText','urn:schemas-microsoft-com:unattend'))
                                $LocalAccountDisplayNameElement = $LocalAccountElement.AppendChild($unattendXml.CreateElement('DisplayName','urn:schemas-microsoft-com:unattend'))
                                $LocalAccountGroupElement = $LocalAccountElement.AppendChild($unattendXml.CreateElement('Group','urn:schemas-microsoft-com:unattend'))
                                $LocalAccountNameElement = $LocalAccountElement.AppendChild($unattendXml.CreateElement('Name','urn:schemas-microsoft-com:unattend'))
                            
                                $null = $LocalAccountElement.SetAttribute('action','http://schemas.microsoft.com/WMIConfig/2002/State','add')
                                $concatenatedPassword = '{0}Password' -f $Account.GetNetworkCredential().password
                                $null = $LocalAccountPasswordValueElement.AppendChild($unattendXml.CreateTextNode([System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($concatenatedPassword))))
                                $null = $LocalAccountPasswordPlainTextElement.AppendChild($unattendXml.CreateTextNode('false'))
                                $null = $LocalAccountDisplayNameElement.AppendChild($unattendXml.CreateTextNode($Account.UserName))
                                $null = $LocalAccountGroupElement.AppendChild($unattendXml.CreateTextNode('Administrators'))
                                $null = $LocalAccountNameElement.AppendChild($unattendXml.CreateTextNode($Account.UserName))
                            }
                        }
                        
                        if ($LogonCount)
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Autologon for $($component.'processorArchitecture') Architecture"
                            $autoLogonElement = $component.AppendChild($unattendXml.CreateElement('AutoLogon','urn:schemas-microsoft-com:unattend'))
                            $autoLogonPasswordElement = $autoLogonElement.AppendChild($unattendXml.CreateElement('Password','urn:schemas-microsoft-com:unattend'))
                            $autoLogonPasswordValueElement = $autoLogonPasswordElement.AppendChild($unattendXml.CreateElement('Value','urn:schemas-microsoft-com:unattend'))
                            $autoLogonCountElement = $autoLogonElement.AppendChild($unattendXml.CreateElement('LogonCount','urn:schemas-microsoft-com:unattend'))
                            $autoLogonUsernameElement = $autoLogonElement.AppendChild($unattendXml.CreateElement('Username','urn:schemas-microsoft-com:unattend'))
                            $autoLogonEnabledElement = $autoLogonElement.AppendChild($unattendXml.CreateElement('Enabled','urn:schemas-microsoft-com:unattend'))
                            
                            $null = $autoLogonPasswordValueElement.AppendChild($unattendXml.CreateTextNode($AdminCredential.GetNetworkCredential().password))
                            $null = $autoLogonCountElement.AppendChild($unattendXml.CreateTextNode($LogonCount))
                            $null = $autoLogonUsernameElement.AppendChild($unattendXml.CreateTextNode('administrator'))
                            $null = $autoLogonEnabledElement.AppendChild($unattendXml.CreateTextNode('true'))
                        }

                        if (($FirstLogonExecuteCommand -ne $null -or $FirstBootExecuteCommand.Length -gt 0) -and $component.'processorArchitecture' -eq 'x86')
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding First Logon Commands"
                            $commandOrder = 1
                            $FirstLogonCommandsElement = $component.AppendChild($unattendXml.CreateElement('FirstLogonCommands','urn:schemas-microsoft-com:unattend'))
                            foreach ($command in ($FirstLogonExecuteCommand | Sort-Object -Property {
                                        $_.order
                            }))
                            {
                                $CommandElement = $FirstLogonCommandsElement.AppendChild($unattendXml.CreateElement('SynchronousCommand','urn:schemas-microsoft-com:unattend'))
                                $CommandDescriptionElement = $CommandElement.AppendChild($unattendXml.CreateElement('Description','urn:schemas-microsoft-com:unattend'))
                                $CommandOrderElement = $CommandElement.AppendChild($unattendXml.CreateElement('Order','urn:schemas-microsoft-com:unattend'))
                                $CommandCommandLineElement = $CommandElement.AppendChild($unattendXml.CreateElement('CommandLine','urn:schemas-microsoft-com:unattend'))
                                $CommandRequireInputlement = $CommandElement.AppendChild($unattendXml.CreateElement('RequiresUserInput','urn:schemas-microsoft-com:unattend'))

                                $null = $CommandElement.SetAttribute('action','http://schemas.microsoft.com/WMIConfig/2002/State','add')
                                $null = $CommandDescriptionElement.AppendChild($unattendXml.CreateTextNode($command['Description']))
                                $null = $CommandOrderElement.AppendChild($unattendXml.CreateTextNode($commandOrder))
                                $null = $CommandCommandLineElement.AppendChild($unattendXml.CreateTextNode($command['CommandLine']))
                                $null = $CommandRequireInputlement.AppendChild($unattendXml.CreateTextNode('false'))
                                $commandOrder++
                            }
                        }
                        if (($EveryLogonExecuteCommand -ne $null -or $FirstBootExecuteCommand.Length -gt 0) -and $component.'processorArchitecture' -eq 'x86')
                        {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Adding Every-Logon Commands"
                            $commandOrder = 1
                            $FirstLogonCommandsElement = $component.AppendChild($unattendXml.CreateElement('LogonCommands','urn:schemas-microsoft-com:unattend'))
                            foreach ($command in ($EveryLogonExecuteCommand | Sort-Object -Property {
                                        $_.order
                            }))
                            {
                                $CommandElement = $FirstLogonCommandsElement.AppendChild($unattendXml.CreateElement('AsynchronousCommand','urn:schemas-microsoft-com:unattend'))
                                $CommandDescriptionElement = $CommandElement.AppendChild($unattendXml.CreateElement('Description','urn:schemas-microsoft-com:unattend'))
                                $CommandOrderElement = $CommandElement.AppendChild($unattendXml.CreateElement('Order','urn:schemas-microsoft-com:unattend'))
                                $CommandCommandLineElement = $CommandElement.AppendChild($unattendXml.CreateElement('CommandLine','urn:schemas-microsoft-com:unattend'))
                                $CommandRequireInputlement = $CommandElement.AppendChild($unattendXml.CreateElement('RequiresUserInput','urn:schemas-microsoft-com:unattend'))

                                $null = $CommandElement.SetAttribute('action','http://schemas.microsoft.com/WMIConfig/2002/State','add')
                                $null = $CommandDescriptionElement.AppendChild($unattendXml.CreateTextNode($command['Description']))
                                $null = $CommandOrderElement.AppendChild($unattendXml.CreateTextNode($commandOrder))
                                $null = $CommandCommandLineElement.AppendChild($unattendXml.CreateTextNode($command['CommandLine']))
                                $null = $CommandRequireInputlement.AppendChild($unattendXml.CreateTextNode('false'))
                                $commandOrder++
                            }
                        }
                    } 
                } #end foreach setting.Component
            } #end foreach unattendXml.Unattend.Settings

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Saving file"
 
            $unattendXml.Save($Path)
            Get-ChildItem $Path
            #         }
            #         catch 
            #         {
            #             throw $_.Exception.Message
            #         }
        }
    }
}


function Get-UnattendChunk 
{
    param
    (
        [string] $pass, 
        [string] $component,
        [string] $arch, 
        [xml] $unattend
    ) 
    
    # Helper function that returns one component chunk from the Unattend XML data structure
    return $unattend.unattend.settings |
    Where-Object -Property pass -EQ -Value $pass |
    Select-Object -ExpandProperty component |
    Where-Object -Property name -EQ -Value $component |
    Where-Object -Property processorArchitecture -EQ -Value $arch
}
