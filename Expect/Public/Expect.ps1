$global:processHandler = [ExpectHandler]::new()

# Spawn a child process to execute commands in
function Invoke-Spawn {
    [CmdletBinding()]
    param(
        # Optional command to run with the spawn (otherwise will just start a powershell process)
        [string]$Command = $null,
        # Timeout in seconds
        [int]$Timeout = $null
    )
    try {
        $processHandler.StartProcess($Timeout)

        if ($Command) {
            $processHandler.Send($Command, $false)
        }
    }
    catch {
        Write-Warning "Expect encountered an error!"
        Write-Error $_
        throw
    }
}

# Send a command to the spawned child process
function Send-String {
    [CmdletBinding()]
    param(
        [string]$Command,
        # Optionally disable sending the newline character, which submits the response (you can still provide manually with \n)
        [switch]$NoNewline = $false
    )
    try {
        $processHandler.Send($Command, $NoNewline)
    }
    catch {
        Write-Warning "Expect encountered an error!"
        Write-Error $_
        throw
    }
}

# Wait for a regular expression match to be detected in the standard output of the child process
function Wait-Expect {
    [CmdletBinding(DefaultParameterSetName = "Regex")]
    param(
        [Parameter(ParameterSetName = "Regex")]
        [string]$Regex,
        [Parameter(ParameterSetName = "SimpleMatch")]
        [Alias("Simple")]
        [string]$SimpleMatch,
        [int]$Timeout = $null,
        [switch]$ContinueOnTimeout,
        [switch]$EOF
    )
    try {
        if ($PSCmdlet.ParameterSetName -like "Regex") {
            $processHandler.ExpectRegex($Regex, $Timeout, $ContinueOnTimeout, $EOF)
        }
        else {
            $processHandler.ExpectSimple($SimpleMatch, $Timeout, $ContinueOnTimeout, $EOF)
        }
    }
    catch {
        Write-Warning "Expect encountered an error!"
        Write-Error $_
        throw
    }
}

function Close-Spawn {
    [CmdletBinding()]
    param ()
    $processHandler.StopProcess()
}

New-Alias -Name Spawn -Value "Invoke-Spawn"
New-Alias -Name Expect -Value "Wait-Expect"
New-Alias -Name Send -Value "Send-String"
New-Alias -Name Close -Value "Close-Spawn"

Export-ModuleMember -Function "Invoke-Spawn", "Wait-Expect", "Send-String", "Close-Spawn" -Alias Spawn, Expect, Send, Close