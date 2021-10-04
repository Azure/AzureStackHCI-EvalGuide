$script:ModuleName         = 'Helper'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResources\Helper.psm1')

#endregion

# Begin Testing
InModuleScope $script:ModuleName {

    $testParams = @{
        ScopeId = '192.168.1.0'
        IPStartRange = '192.168.1.10'
        IPEndRange = '192.168.1.99'
        SubnetMask = '255.255.255.0'
        AddressFamily = 'IPv4'
    }

    #region Function Assert-ScopeParameter
    Describe 'Helper\Assert-ScopeParameter' {
        It 'Should not throw when parameters are correct' {
            { Assert-ScopeParameter @testParams } | Should -Not -Throw
        }

        It 'Should return nothing when parameters are correct' {
            Assert-ScopeParameter @testParams | Should -BeNullOrEmpty
        }

        It 'Should throw an exception with ErrorId <ErrorId> and information about incorrect <Parameter> (<Value>)' {
            param (
                [String]$Parameter,
                [String]$Value,
                [String]$ErrorPattern,
                [String]$ErrorId
            )
            $brokenTestParams = $testParams.Clone()
            $brokenTestParams[$Parameter] = $Value
            { Assert-ScopeParameter @brokenTestParams } | Should -Throw -ExpectedMessage $ErrorPattern -ErrorId $ErrorId
        } -TestCases @(
            @{
                Parameter = 'ScopeId'
                Value = '192.168.1.42'
                ErrorPattern = 'Value of byte 4 in ScopeId (42) is not valid.'
                ErrorId = 'ScopeIdOrMaskIncorrect'
            }
            @{
                Parameter = 'IPStartRange'
                Value = '192.168.0.1'
                ErrorPattern = 'Value of byte 3 in IPStartRange (0) is not valid.'
                ErrorId = 'ScopeIdOrMaskIncorrect'
            }
            @{
                Parameter = 'IPEndRange'
                Value = '192.167.1.100'
                ErrorPattern = 'Value of byte 2 in IPEndRange (167) is not valid.'
                ErrorId = 'ScopeIdOrMaskIncorrect'
            }
            @{
                Parameter = 'IPEndRange'
                Value = '192.168.1.2'
                ErrorPattern = 'not valid. Start should be lower than end.'
                ErrorId = 'RangeNotCorrect'
            }
        )
    }
    #endregion
}
