#https://pester-docs.netlify.app/docs/quick-start

Describe 'normal UI should exist' {
    It 'Should exist' {
      '.\TimeZoneUI.ps1' | Should -Exist
    }
}

Describe 'windows 10 UI should exist ' {
    It 'Should exist' {
      '.\TimeZoneUI_Win10.ps1' | Should -Exist
    }
}

Describe 'windows 11 UI should exist ' {
    It 'Should exist' {
      '.\TimeZoneUI_Win11.ps1' | Should -Exist
    }
}

Describe ".\TimeZoneUI.ps1" {
    Context "when param not specified" {
        It "should return 'UI'" {
            .\TimeZoneUI.ps1 | Should -Be $null
        }

        It "should set registry name status to completed" {
            Get-ItemPropertyValue HKCU:\Software\PowerShellCrack\TimeZoneSelector -Name Status | Should -Be 'Completed'
        }

        It "should output 'TimeZoneUI.log' file" {
            Test-Path $env:TEMP\TimeZoneUI.log | Should -Exist
        }
    }

    Context "when running '-ForceInteraction:$true'" {
        It "should return 'True'" {
            .\TimeZoneUI.ps1 -ForceInteraction:$true | Should -Be $null
        }

        It "should set registry name status to completed" {
            Get-ItemPropertyValue HKCU:\Software\PowerShellCrack\TimeZoneSelector -Name Status | Should -Be 'Completed'
        }

        It "should output 'TimeZoneUI.log' file" {
            Test-Path $env:TEMP\TimeZoneUI.log | Should -Exist
        }
    }
}