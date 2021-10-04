
#region HEADER
$script:DSCModuleName = 'xHyper-V'
$script:DSCResourceName = 'MSFT_xVMSwitch'

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -ResourceType 'Mof' `
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

    InModuleScope $script:DSCResourceName {

        # A helper function to create a exception object for testing output exceptions
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
        }

        # A helper function to mock a VMSwitch
        function New-MockedVMSwitch
        {
            param (
                [Parameter(Mandatory = $true)]
                [String]
                $Name,

                [Parameter()]
                [ValidateNotNullOrEmpty()]
                [Guid]
                $Id
            )

            $mockedVMSwitch = @{
                Name                            = $Name
                SwitchType                      = 'External'
                AllowManagementOS               = $true
                EmbeddedTeamingEnabled          = $true
                LoadBalancingAlgorithm          = 'HyperVPort'
                BandwidthReservationMode        = 'Default'
                NetAdapterInterfaceDescriptions = @("Microsoft Network Adapter Multiplexor Driver #1", "Microsoft Network Adapter Multiplexor Driver #2")
            }

            if ($PSBoundParameters.ContainsKey('Id'))
            {
                $mockedVMSwitch['Id'] = $Id
            }
            else
            {
                $mockedVMSwitch['Id'] = New-Guid
            }
            return [PsObject]$mockedVMSwitch
        }

        # Mocks "Get-Module -Name Hyper-V" so that the DSC resource thinks the Hyper-V module is on the test system
        Mock -CommandName Get-Module -ParameterFilter { ($Name -eq 'Hyper-V') -and ($ListAvailable -eq $true) } -MockWith {
            return $true
        }

        function Get-VMSwitch
        {
        }
        Mock -CommandName Get-VMSwitch -MockWith {
            return $Global:MockedVMSwitch
        }

        function Get-NetAdapter
        {
        }
        Mock -CommandName Get-NetAdapter -MockWith {
            return @(
                [PSCustomObject]@{
                    Name                 = 'NIC1'
                    InterfaceDescription = 'Microsoft Network Adapter Multiplexor Driver #1'
                }
                [PSCustomObject]@{
                    Name                 = 'NIC2'
                    InterfaceDescription = 'Microsoft Network Adapter Multiplexor Driver #2'
                }
            )
        }

        function Get-VMSwitchTeam
        {
        }
        Mock -CommandName Get-VMSwitchTeam -MockWith {
            return [PSCustomObject]@{
                Name                           = 'TestTeam'
                Id                             = New-Guid
                NetAdapterInterfaceDescription = @("Microsoft Network Adapter Multiplexor Driver #1", "Microsoft Network Adapter Multiplexor Driver #2")
                TeamingMode                    = 'SwitchIndependent'
                LoadBalancingAlgorithm         = 'HyperVPort'
            }
        }

        function Remove-VMSwitch {}
        Mock -CommandName Remove-VMSwitch -MockWith {
            $Global:mockedVMSwitch = $null
        }

        function New-VMSwitch {}
        Mock -CommandName New-VMSwitch -MockWith {
            Param(
                [Parameter()]
                [String]
                $Name,

                [Parameter()]
                [String[]]
                $NetAdapterName,

                [Parameter()]
                [String]
                $MinimumBandwidthMode,

                [Parameter()]
                [bool]
                $AllowManagementOS,

                [Parameter()]
                [String]
                $SwitchType,

                [Parameter()]
                [bool]
                $EnableEmbeddedTeaming,

                [Parameter()]
                [Guid]
                $Id
            )

            if($PSBoundParameters.ContainsKey('Id'))
            {
                $Global:MockedVMSwitch = New-MockedVMSwitch -Name $Name -Id $id
            }
            else
            {
                $Global:MockedVMSwitch = New-MockedVMSwitch -Name $Name
            }
        }

        function Get-OSVersion
        {
        }
        Mock -CommandName Get-OSVersion -MockWith {
            [PSCustomObject]@{
                Major         = 10
                Minor         = 0
                Build         = 14393
                Revision      = 0
                MajorRevision = 0
                MinorRevision = 0
            }
        }

        Describe 'MSFT_xVMSwitch\Get-TargetResource' -Tag 'Get' {

            Context 'When the system is in the desired state (VMSwitch has the desired Id)' {
                $Global:MockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch'

                It 'Should return "present"' {
                    (Get-TargetResource -Name 'TestSwitch' -Type 'External').Ensure | Should Be 'Present'
                    Assert-MockCalled -CommandName "Get-VMSwitch" -Times 1
                    Assert-MockCalled -CommandName "Get-VMSwitchTeam" -Times 1
                }
            }

            Context 'When the system is not in the desired state (VMSwitch has not the desired Id)' {

                $Global:mockedVMSwitch = $null

                It 'Should return "absent"' {
                    (Get-TargetResource -Name 'TestSwitch' -Type 'External').Ensure | Should Be 'Absent'
                    Assert-MockCalled -CommandName "Get-VMSwitch" -Times 1
                    Assert-MockCalled -CommandName "Get-VMSwitchTeam" -Times 0
                }
            }
        }

        Describe 'MSFT_xVMSwitch\Set-TargetResource' -Tag 'Set' {

            Context 'When the system is in the desired state (VMSwitch has the desired Id)' {
                $desiredVMSwitchID = New-Guid

                $Global:mockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch' -Id $desiredVMSwitchID

                $testParams = @{
                    Name                     = 'TestSwitch'
                    Type                     = 'External'
                    NetAdapterName           = @('NIC1', 'NIC2')
                    AllowManagementOS        = $true
                    EnableEmbeddedTeaming    = $true
                    Ensure                   = 'Present'
                    Id                       = $desiredVMSwitchID
                }

                It 'Should run without without exceptions' {
                    {Set-TargetResource @testParams} | Should -Not -Throw
                    Assert-MockCalled -CommandName "Get-VMSwitch" -Times 1
                    Assert-MockCalled -CommandName 'Get-NetAdapter' -Times 1
                }
            }

            Context 'When the system is not in the desired state (VMSwitch has not the desired Id)' {

                $Global:mockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch'

                $testParams = @{
                    Name                     = 'TestSwitch'
                    Type                     = 'External'
                    NetAdapterName           = @('NIC1', 'NIC2')
                    AllowManagementOS        = $true
                    EnableEmbeddedTeaming    = $true
                    Ensure                   = 'Present'
                    Id                       = New-Guid
                }

                It 'Should run without exception while re-creating the VMSwitch' {
                    {Set-TargetResource @testParams} | Should -Not -Throw
                    Assert-MockCalled -CommandName "Get-VMSwitch" -Times 1
                    Assert-MockCalled -CommandName 'Get-NetAdapter' -Times 1
                    Assert-MockCalled -CommandName 'Remove-VMSwitch' -Times 1
                    Assert-MockCalled -CommandName 'New-VMSwitch' -Times 1
                }
            }

            Context 'When the specified value for Id parameter is not a GUID' {

                $Global:mockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch'

                $testParams = @{
                    Name                     = 'TestSwitch'
                    Type                     = 'External'
                    NetAdapterName           = @('NIC1', 'NIC2')
                    AllowManagementOS        = $true
                    EnableEmbeddedTeaming    = $true
                    Ensure                   = 'Present'
                    Id                       = '123'
                }

                It 'Should throw "The VMSwitch Id must be in GUID format!"' {
                    {Set-TargetResource @testParams} | Should -Throw 'The VMSwitch Id must be in GUID format!'
                }
            }

            Context 'When the system is not running Server 2016' {

                $desiredVMSwitchID = New-Guid

                $Global:mockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch' -Id $desiredVMSwitchID

                $testParams = @{
                    Name                     = 'TestSwitch'
                    Type                     = 'External'
                    NetAdapterName           = 'NIC1'
                    AllowManagementOS        = $true
                    EnableEmbeddedTeaming    = $false
                    Ensure                   = 'Present'
                    Id                       = $desiredVMSwitchID
                }

                Mock -CommandName Get-OSVersion -MockWith {
                    return [Version]::Parse('6.3.9600')
                }

                $errorRecord = Get-InvalidArgumentError `
                    -ErrorId 'VMSwitchIDServer2016Error' `
                    -ErrorMessage $LocalizedData.VMSwitchIDServer2016Error

                It 'Should throw "VMSwitchIDServer2016Error"' {
                    {Set-TargetResource @testParams} | Should -Throw $errorRecord
                }
            }
        }

        Describe 'MSFT_xVMSwitch\Test-TargetResource' -Tag 'Test' {
            Context 'When the system is in the desired state (VMSwitch has the desired Id)' {

                $desiredVMSwitchID = New-Guid

                $Global:mockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch' -Id $desiredVMSwitchID

                $testParams = @{
                    Name                  = 'TestSwitch'
                    Type                  = 'External'
                    NetAdapterName        = @('NIC1', 'NIC2')
                    AllowManagementOS     = $true
                    EnableEmbeddedTeaming = $true
                    Ensure                = 'Present'
                    Id                    = $desiredVMSwitchID
                }

                It 'Should return $true' {
                    {Test-TargetResource @testParams} | Should -Not -Throw
                    Assert-MockCalled -CommandName "Get-VMSwitch" -Times 1
                    Assert-MockCalled -CommandName 'Get-NetAdapter' -Times 1
                }
            }

            Context 'When the system is not in the desired state (VMSwitch has not the desired Id)' {

                $Global:mockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch'

                $testParams = @{
                    Name                  = 'TestSwitch'
                    Type                  = 'External'
                    NetAdapterName        = @('NIC1', 'NIC2')
                    AllowManagementOS     = $true
                    EnableEmbeddedTeaming = $true
                    Ensure                = 'Present'
                    Id                    = New-Guid
                }

                It 'Should return $false' {
                    {Test-TargetResource @testParams} | Should -Not -Throw
                    Assert-MockCalled -CommandName "Get-VMSwitch" -Times 1
                    Assert-MockCalled -CommandName 'Get-NetAdapter' -Times 1
                }
            }

            Context 'When the specified value for Id parameter is not a GUID' {

                $Global:mockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch'

                $testParams = @{
                    Name                     = 'TestSwitch'
                    Type                     = 'External'
                    NetAdapterName           = @('NIC1', 'NIC2')
                    AllowManagementOS        = $true
                    EnableEmbeddedTeaming    = $true
                    Ensure                   = 'Present'
                    Id                       = '123'
                }

                It 'Should throw "The VMSwitch Id must be in GUID format!"' {
                    {Test-TargetResource @testParams} | Should -Throw 'The VMSwitch Id must be in GUID format!'
                }
            }

            Context 'When the system is not running Server 2016' {

                $desiredVMSwitchID = New-Guid

                $Global:mockedVMSwitch = New-MockedVMSwitch -Name 'TestSwitch' -Id $desiredVMSwitchID

                $testParams = @{
                    Name                     = 'TestSwitch'
                    Type                     = 'External'
                    NetAdapterName           = 'NIC1'
                    AllowManagementOS        = $true
                    EnableEmbeddedTeaming    = $false
                    Ensure                   = 'Present'
                    Id                       = $desiredVMSwitchID
                }

                Mock -CommandName Get-OSVersion -MockWith {
                    return [Version]::Parse('6.3.9600')
                }

                $errorRecord = Get-InvalidArgumentError `
                    -ErrorId 'VMSwitchIDServer2016Error' `
                    -ErrorMessage $LocalizedData.VMSwitchIDServer2016Error

                It 'Should throw "VMSwitchIDServer2016Error"' {
                    {Test-TargetResource @testParams} | Should -Throw $errorRecord
                }
            }

        }
    }
}
finally
{
    Invoke-TestCleanup
}
