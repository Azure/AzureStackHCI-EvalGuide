#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xHyper-V' `
    -DSCResourceName 'MSFT_xVMSwitch' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{

}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xVMSwitch' {

        <#
            Defines a variable that contains all the possible Bandwidth Reservation Modes which will be used
            for foreach loops later on
        #>
        New-Variable -Name 'BANDWIDTH_RESERVATION_MODES' -Option 'Constant' -Value @('Default', 'Weight', 'Absolute', 'None')

        # Function to create a exception object for testing output exceptions
        function Get-InvalidArgumentError
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ErrorId,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ErrorMessage
            )

            $exception = New-Object -TypeName System.ArgumentException `
                -ArgumentList $ErrorMessage
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $ErrorId, $errorCategory, $null
            return $errorRecord
        } # end function Get-InvalidArgumentError

        # A helper function to mock a VMSwitch
        function New-MockedVMSwitch
        {
            Param (
                [Parameter(Mandatory = $true)]
                [string]
                $Name,

                [Parameter(Mandatory = $true)]
                [ValidateSet('Default', 'Weight', 'Absolute', 'None', 'NA')]
                [string]
                $BandwidthReservationMode,

                [Parameter()]
                [bool]
                $AllowManagementOS = $false
            )

            $mockedVMSwitch = @{
                Name = $Name
                SwitchType = 'External'
                AllowManagementOS = $AllowManagementOS
                NetAdapterInterfaceDescription = 'Microsoft Network Adapter Multiplexor Driver'
            }

            if ($BandwidthReservationMode -ne 'NA')
            {
                $mockedVMSwitch['BandwidthReservationMode'] = $BandwidthReservationMode
            }

            return [PsObject]$mockedVMSwitch
        }

        Describe 'Validates Get-TargetResource Function' {
            # Create an empty function to be able to mock the missing Hyper-V cmdlet
            function Get-VMSwitch
            {

            }

            <#
                Mocks Get-VMSwitch and will return $global:mockedVMSwitch which is
                a variable that is created during most It statements to mock a VMSwitch
            #>
            Mock -CommandName Get-VMSwitch -MockWith {
                param
                (
                    [string]
                    $ErrorAction
                )

                if ($ErrorAction -eq 'Stop' -and $global:mockedVMSwitch -eq $null)
                {
                    throw [System.Management.Automation.ActionPreferenceStopException]'No switch can be found by given criteria.'
                }

                return $global:mockedVMSwitch
            }

            # Mocks Get-NetAdapter which returns a simplified network adapter
            Mock -CommandName Get-NetAdapter -MockWith {
                return [PSCustomObject]@{
                    Name = 'SomeNIC'
                    InterfaceDescription = 'Microsoft Network Adapter Multiplexor Driver'
                }
            }

            # Mocks "Get-Module -Name Hyper-V" so that the DSC resource thinks the Hyper-V module is on the test system
            Mock -CommandName Get-Module -ParameterFilter { ($Name -eq 'Hyper-V') -and ($ListAvailable -eq $true) } -MockWith {
                return $true
            }

            # Create all the test cases for Get-TargetResource
            $getTestCases = @()
            foreach ($brmMode in $BANDWIDTH_RESERVATION_MODES) {
                $getTestCases += @{
                    CurrentName = $brmMode + 'BRM'
                    CurrentBandwidthReservationMode = $brmMode
                }
            }

            # Test Get-TargetResource with the test cases created above
            It 'Current switch''s BandwidthReservationMode is set to <CurrentBandwidthReservationMode>' -TestCases $getTestCases {
                param
                (
                    [Parameter()]
                    [string]
                    $CurrentName,

                    [Parameter()]
                    [string]
                    $CurrentBandwidthReservationMode
                )

                # Set the mocked VMSwitch to be returned from Get-VMSwitch based on the input from $getTestCases
                $global:mockedVMSwitch = New-MockedVMSwitch -Name $CurrentName -BandwidthReservationMode $CurrentBandwidthReservationMode

                $targetResource = Get-TargetResource -Name $CurrentName -Type 'External'
                $targetResource -is [System.Collections.Hashtable] | Should Be $true
                $targetResource['BandwidthReservationMode'] | Should Be $CurrentBandwidthReservationMode

                Remove-Variable -Scope 'Global' -Name 'mockedVMSwitch' -ErrorAction 'SilentlyContinue'
            }

            <#
                Test Get-TargetResource when the VMSwitch's BandwidthReservationMode member variable is not
                set which simulates older versions of Windows that don't support it
            #>
            It 'BandwidthReservationMode is set to null' {
                # Set the mocked VMSwitch to be returned from Get-VMSwitch
                $global:mockedVMSwitch = New-MockedVMSwitch -Name 'NaBRM' -BandwidthReservationMode 'NA'

                $targetResource = Get-TargetResource -Name 'NaBRM' -Type 'External'
                $targetResource -is [System.Collections.Hashtable] | Should Be $true
                $targetResource['BandwidthReservationMode'] | Should Be "NA"

                Remove-Variable -Scope 'Global' -Name 'mockedVMSwitch' -ErrorAction 'SilentlyContinue'
            }
        }

        # Create all the test cases for Test-TargetResource and Set-TargetResource when the switch already exists
        $testSetTestCases = @()
        foreach ($currentBrmMode in $BANDWIDTH_RESERVATION_MODES)
        {
            foreach ($desiredBrmMode in $BANDWIDTH_RESERVATION_MODES)
            {
                foreach ($ensureOption in @('Present', 'Absent'))
                {
                    $case = @{
                        CurrentName = $currentBrmMode + 'BRM'
                        CurrentBandwidthReservationMode = $currentBrmMode
                        DesiredName = $desiredBrmMode + 'BRM'
                        DesiredBandwidthReservationMode = $desiredBrmMode
                        Ensure = $ensureOption
                        ExpectedResult = $ensureOption -eq 'Present' -and $currentBrmMode -eq $desiredBrmMode
                    }
                    $testSetTestCases += $case
                }
            }
        }

        # Create all the test cases for Test-TargetResource and Set-TargetResource when the switch does not exists
        foreach ($desiredBrmMode in $BANDWIDTH_RESERVATION_MODES)
        {
            foreach ($ensureOption in @('Present', 'Absent'))
            {
                $case = @{
                    CurrentName = $null
                    CurrentBandwidthReservationMode = $null
                    DesiredName = $desiredBrmMode + 'BRM'
                    DesiredBandwidthReservationMode = $desiredBrmMode
                    Ensure = $ensureOption
                    ExpectedResult = $ensureOption -eq 'Absent'
                }
                $testSetTestCases += $case
            }
        }

        Describe 'Validates Test-TargetResource Function' {
            # Create an empty function to be able to mock the missing Hyper-V cmdlet
            function Get-VMSwitch
            {

            }

            <#
                Mocks Get-VMSwitch and will return $global:mockedVMSwitch which is
                a variable that is created during most It statements to mock a VMSwitch
            #>
            Mock -CommandName Get-VMSwitch -MockWith {
                param (
                    [string]
                    $ErrorAction
                )

                if ($ErrorAction -eq 'Stop' -and $global:mockedVMSwitch -eq $null)
                {
                    throw [System.Management.Automation.ActionPreferenceStopException]'No switch can be found by given criteria.'
                }

                return $global:mockedVMSwitch
            }

            # Mocks Get-NetAdapter which returns a simplified network adapter
            Mock -CommandName Get-NetAdapter -MockWith {
                return [PSCustomObject]@{
                    Name = 'SomeNIC'
                    InterfaceDescription = 'Microsoft Network Adapter Multiplexor Driver'
                }
            }

            # Mocks "Get-Module -Name Hyper-V" so that the DSC resource thinks the Hyper-V module is on the test system
            Mock -CommandName Get-Module -ParameterFilter { ($Name -eq 'Hyper-V') -and ($ListAvailable -eq $true) } -MockWith {
                return $true
            }

            Mock -CommandName Get-OSVersion -MockWith {
                return [Version]::Parse('6.3.9600')
            }

            # Create all the test cases for Get-TargetResource
            $getTestCases = @()
            foreach ($brmMode in $BANDWIDTH_RESERVATION_MODES)
            {
                $getTestCases += @{
                    CurrentName = $brmMode + 'BRM'
                    CurrentBandwidthReservationMode = $brmMode
                }
            }

            # Test Test-TargetResource with the test cases created above
            It 'Current Name "<CurrentName>" | Current BandwidthReservationMode set to "<CurrentBandwidthReservationMode>" | Desired BandwidthReservationMode set to "<DesiredBandwidthReservationMode>" | Ensure "<Ensure>"' -TestCases $testSetTestCases {
                param
                (
                    [Parameter()]
                    [string]
                    $CurrentName,

                    [Parameter()]
                    [string]
                    $CurrentBandwidthReservationMode,

                    [Parameter()]
                    [string]
                    $DesiredName,

                    [Parameter()]
                    [string]
                    $DesiredBandwidthReservationMode,

                    [Parameter()]
                    [string]
                    $Ensure,

                    [Parameter()]
                    [bool]
                    $ExpectedResult
                )

                # Set the mocked VMSwitch to be returned from Get-VMSwitch if the switch exists
                if ($CurrentName)
                {
                    $global:mockedVMSwitch = New-MockedVMSwitch -Name $CurrentName -BandwidthReservationMode $CurrentBandwidthReservationMode -AllowManagementOS $true
                }

                $targetResource = Test-TargetResource -Name $DesiredName -BandwidthReservationMode $DesiredBandwidthReservationMode -Type 'External' -NetAdapterName 'SomeNIC' -Ensure $Ensure -AllowManagementOS $true
                $targetResource | Should Be $ExpectedResult

                Remove-Variable -Scope 'Global' -Name 'mockedVMSwitch' -ErrorAction 'SilentlyContinue'
            }

            Mock -CommandName Get-OSVersion -MockWith {
                return [Version]::Parse('6.1.7601')
            }

            # Test Test-TargetResource when the version of Windows doesn't support BandwidthReservationMode
            It 'Invalid Operating System Exception' {
                $errorRecord = Get-InvalidArgumentError `
                    -ErrorId 'BandwidthReservationModeError' `
                    -ErrorMessage $LocalizedData.BandwidthReservationModeError
                {Test-TargetResource -Name 'WeightBRM' -Type 'External' -NetAdapterName 'SomeNIC' -AllowManagementOS $true -BandwidthReservationMode 'Weight' -Ensure 'Present'} | Should Throw $errorRecord
            }

            # Test Test-TargetResource when the version of Windows doesn't support BandwidthReservationMode and specifies NA for BandwidthReservationMode
            It 'Simulates Windows Server 2008 R2 | Desired BandwidthReservationMode set to "NA" | Ensure Present | Expected Result is True' {
                $global:mockedVMSwitch = New-MockedVMSwitch -Name 'SomeSwitch' -BandwidthReservationMode 'NA' -AllowManagementOS $true
                $targetResource = Test-TargetResource -Name 'SomeSwitch' -BandwidthReservationMode 'NA' -Type 'External' -NetAdapterName 'SomeNIC' -Ensure 'Present' -AllowManagementOS $true
                $targetResource | Should Be $true
            }

            It 'Passes when "BandwidthReservationMode" does not match but is not specified (#48)' {
                $global:mockedVMSwitch = New-MockedVMSwitch -Name 'SomeSwitch' -BandwidthReservationMode 'Absolute'
                $targetResource = Test-TargetResource -Name 'SomeSwitch' -Type 'Internal' -Ensure 'Present'
                $targetResource | Should Be $true
            }
        }

        Describe 'Validates Set-TargetResource Function' {
            # Create empty functions to be able to mock the missing Hyper-V cmdlet
            function Get-VMSwitch
            {

            }

            function New-VMSwitch
            {

            }

            function Remove-VMSwitch
            {

            }

            function Set-VMSwitch
            {

            }

            <#
                Mocks Get-VMSwitch and will return $global:mockedVMSwitch which is
                a variable that is created during most It statements to mock a VMSwitch
            #>
            Mock -CommandName Get-VMSwitch -MockWith {
                param
                (
                    [string]
                    $Name,

                    [string]
                    $SwitchType,

                    [string]
                    $ErrorAction
                )

                if ($ErrorAction -eq 'Stop' -and $global:mockedVMSwitch -eq $null)
                {
                    throw [System.Management.Automation.ActionPreferenceStopException]'No switch can be found by given criteria.'
                }

                return $global:mockedVMSwitch
            }

            <#
                Mocks New-VMSwitch and will assign a mocked switch to $global:mockedVMSwitch. This returns $global:mockedVMSwitch
                which is a variable that is created during most It statements to mock a VMSwitch
            #>
            Mock -CommandName New-VMSwitch -MockWith {
                param
                (
                    [string]
                    $Name,

                    [string]
                    $NetAdapterName,

                    [string]
                    $MinimumBandwidthMode,

                    [bool]
                    $AllowManagementOS
                )

                $global:mockedVMSwitch = New-MockedVMSwitch -Name $Name -BandwidthReservationMode $MinimumBandwidthMode -AllowManagementOS $AllowManagementOS
                return $global:mockedVMSwitch
            }

            <#
                Mocks Set-VMSwitch and will modify $global:mockedVMSwitch which is
                a variable that is created during most It statements to mock a VMSwitch
            #>
            Mock -CommandName Set-VMSwitch -MockWith {
                param
                (
                    [bool]
                    $AllowManagementOS
                )

                if ($AllowManagementOS)
                {
                    $global:mockedVMSwitch['AllowManagementOS'] = $AllowManagementOS
                }
            }

            <#
                Mocks Remove-VMSwitch and will remove the variable $global:mockedVMSwitch which is
                a variable that is created during most It statements to mock a VMSwitch
            #>
            Mock -CommandName Remove-VMSwitch -MockWith {
                $global:mockedVMSwitch = $null
            }

            # Mocks Get-NetAdapter which returns a simplified network adapter
            Mock -CommandName Get-NetAdapter -MockWith {
                return [PSCustomObject]@{
                    Name = 'SomeNIC'
                    InterfaceDescription = 'Microsoft Network Adapter Multiplexor Driver'
                }
            }

            # Mocks "Get-Module -Name Hyper-V" so that the DSC resource thinks the Hyper-V module is on the test system
            Mock -CommandName Get-Module -ParameterFilter { ($Name -eq 'Hyper-V') -and ($ListAvailable -eq $true) } -MockWith {
                return $true
            }

            Mock -CommandName Get-OSVersion -MockWith {
                return [Version]::Parse('6.3.9600')
            }

            # Create all the test cases for Get-TargetResource
            $getTestCases = @()
            foreach ($brmMode in $BANDWIDTH_RESERVATION_MODES)
            {
                $getTestCases += @{
                    CurrentName = $brmMode + 'BRM'
                    CurrentBandwidthReservationMode = $brmMode
                }
            }

            It 'Current Name "<CurrentName>" | Current BandwidthReservationMode set to "<CurrentBandwidthReservationMode>" | Desired BandwidthReservationMode set to "<DesiredBandwidthReservationMode>" | Ensure "<Ensure>"' -TestCases $testSetTestCases {
                param
                (
                    [Parameter()]
                    [string]
                    $CurrentName,

                    [Parameter()]
                    [string]
                    $CurrentBandwidthReservationMode,

                    [Parameter()]
                    [string]
                    $DesiredName,

                    [Parameter()]
                    [string]
                    $DesiredBandwidthReservationMode,

                    [Parameter()]
                    [string]
                    $Ensure,

                    [Parameter()]
                    [bool]
                    $ExpectedResult
                )

                # Set the mocked VMSwitch to be returned from Get-VMSwitch if the switch exists
                if ($CurrentName)
                {
                    $global:mockedVMSwitch = New-MockedVMSwitch -Name $CurrentName -BandwidthReservationMode $CurrentBandwidthReservationMode -AllowManagementOS $true
                }

                $targetResource = Set-TargetResource -Name $DesiredName -BandwidthReservationMode $DesiredBandwidthReservationMode -Type 'External' -NetAdapterName 'SomeNIC' -Ensure $Ensure -AllowManagementOS $true
                $targetResource | Should Be $null

                if ($CurrentName -and $Ensure -eq 'Present')
                {
                    if ($DesiredBandwidthReservationMode -ne $CurrentBandwidthReservationMode)
                    {
                        Assert-MockCalled -CommandName Get-VMSwitch -Times 2 -Scope 'It'
                        Assert-MockCalled -CommandName Remove-VMSwitch -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName New-VMSwitch -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Set-VMSwitch -Times 0 -Scope 'It'
                    }
                    else
                    {
                        Assert-MockCalled -CommandName Get-VMSwitch -Times 1 -Scope 'It'
                    }
                }
                elseif ($Ensure -eq 'Present')
                {
                    Assert-MockCalled -CommandName Get-VMSwitch -Times 1 -Scope 'It'
                    Assert-MockCalled -CommandName New-VMSwitch -Times 1 -Scope 'It'
                }
                else
                {
                    Assert-MockCalled -CommandName Get-VMSwitch -Times 1 -Scope 'It'
                    Assert-MockCalled -CommandName Remove-VMSwitch -Times 1 -Scope 'It'
                }
                Remove-Variable -Scope 'Global' -Name 'mockedVMSwitch' -ErrorAction 'SilentlyContinue'
            }

            # Test Set-TargetResource when the version of Windows doesn't support BandwidthReservationMode
            It 'Invalid Operating System Exception' {
                Mock -CommandName Get-OSVersion -MockWith {
                    return [Version]::Parse('6.1.7601')
                }

                $errorRecord = Get-InvalidArgumentError `
                    -ErrorId 'BandwidthReservationModeError' `
                    -ErrorMessage $LocalizedData.BandwidthReservationModeError
                {Set-TargetResource -Name 'WeightBRM' -Type 'External' -NetAdapterName 'SomeNIC' -AllowManagementOS $true -BandwidthReservationMode 'Weight' -Ensure 'Present'} | Should Throw $errorRecord
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
