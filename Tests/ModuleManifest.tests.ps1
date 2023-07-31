Describe 'Module Manifest Tests' {
    BeforeAll {
        $ModuleName = 'Expect'
        $ModuleManifestName = "$ModuleName.psd1"
        $ModuleManifestPath = "$PSScriptRoot\..\$ModuleName\$ModuleManifestName"
    }
    It 'Passes Test-ModuleManifest' {
        Test-Path -Path $ModuleManifestPath -ErrorAction SilentlyContinue | Should -BeTrue
        Test-ModuleManifest -Path $ModuleManifestPath | Should -Not -BeNullOrEmpty
        $? | Should -BeTrue
    }
}
