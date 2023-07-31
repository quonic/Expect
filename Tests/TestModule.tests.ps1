Describe "Test Module" {
    BeforeAll {
        $ModuleName = 'Expect'
        $ModuleManifestName = "$ModuleName.psm1"
        $ModuleManifestPath = "$PSScriptRoot\..\$ModuleName\$ModuleManifestName"
        Import-Module "$ModuleManifestPath"
    }
    It "Spawn, Expect, Send, Close" {
        {
            Spawn -Command '$a = Read-Host -Prompt "Function"'
            Expect -Regex "Function*" -Timeout 2
            Send -Command "y"
            Close
        } | Should -Not -Throw -PassThru
    }
}
