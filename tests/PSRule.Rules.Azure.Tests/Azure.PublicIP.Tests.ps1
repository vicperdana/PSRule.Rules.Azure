# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#
# Unit tests for Azure Public IP address rules
#

[CmdletBinding()]
param (

)

# Setup error handling
$ErrorActionPreference = 'Stop';
Set-StrictMode -Version latest;

if ($Env:SYSTEM_DEBUG -eq 'true') {
    $VerbosePreference = 'Continue';
}

# Setup tests paths
$rootPath = $PWD;
Import-Module (Join-Path -Path $rootPath -ChildPath out/modules/PSRule.Rules.Azure) -Force;
$here = (Resolve-Path $PSScriptRoot).Path;

Describe 'Azure.PublicIP' {
    $dataPath = Join-Path -Path $here -ChildPath 'Resources.PublicIP.json';

    Context 'Conditions' {
        $invokeParams = @{
            Baseline = 'Azure.All'
            Module = 'PSRule.Rules.Azure'
            WarningAction = 'Ignore'
            ErrorAction = 'Stop'
        }
        $result = Invoke-PSRule @invokeParams -InputPath $dataPath;

        It 'Azure.PublicIP.IsAttached' {
            $filteredResult = $result | Where-Object { $_.RuleName -eq 'Azure.PublicIP.IsAttached' };

            # Fail
            $ruleResult = @($filteredResult | Where-Object { $_.Outcome -eq 'Fail' });
            $ruleResult | Should -Not -BeNullOrEmpty;
            $ruleResult.Length | Should -Be 1;
            $ruleResult.TargetName | Should -Be 'ip-B';

            # Pass
            $ruleResult = @($filteredResult | Where-Object { $_.Outcome -eq 'Pass' });
            $ruleResult | Should -Not -BeNullOrEmpty;
            $ruleResult.Length | Should -Be 1;
            $ruleResult.TargetName | Should -Be 'ip-A';
        }
    }

    Context 'With template' {
        $templatePath = Join-Path -Path $here -ChildPath 'Resources.Template3.json';
        $outputFile = Join-Path -Path $rootPath -ChildPath out/tests/Resources.PublicIP.json;
        Export-AzTemplateRuleData -TemplateFile $templatePath -OutputPath $outputFile;
        $result = Invoke-PSRule -Module PSRule.Rules.Azure -InputPath $outputFile -Outcome All -WarningAction Ignore -ErrorAction Stop;

        It 'Azure.PublicIP.IsAttached' {
            $filteredResult = $result | Where-Object {
                $_.RuleName -eq 'Azure.PublicIP.IsAttached' -and
                $_.TargetType -eq 'Microsoft.Network/publicIPAddresses'
            };

            # Fail
            $ruleResult = @($filteredResult | Where-Object { $_.Outcome -eq 'Fail' });
            $ruleResult | Should -BeNullOrEmpty;

            # Pass
            $ruleResult = @($filteredResult | Where-Object { $_.Outcome -eq 'Pass' });
            $ruleResult | Should -BeNullOrEmpty;

            # None
            $ruleResult = @($filteredResult | Where-Object { $_.Outcome -eq 'None' });
            $ruleResult | Should -Not -BeNullOrEmpty;
            $ruleResult.Length | Should -Be 1;
            $ruleResult.TargetName | Should -Be 'pip-001';
        }
    }
}
