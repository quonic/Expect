class ExpectHandler {
    [System.Diagnostics.Process]$process = [System.Diagnostics.Process]::new()
    hidden [System.Collections.Generic.List[string]] $output = [System.Collections.Generic.List[string]]::new()
    hidden [int] $timeoutSeconds = $null
    hidden [int] $EventID = $null

    [void] StartProcess([int]$timeout) {
        # If a timeout was provided, override the global timeout
        if ($timeout -gt 0) {
            $this.timeoutSeconds = $timeout
        }

        $PowerShellExe = if ($(Get-Command "pwsh.exe" -ErrorAction SilentlyContinue)) {
            Get-Command "pwsh.exe" | Select-Object -ExpandProperty Path
        }
        else {
            Get-Command "powershell.exe" | Select-Object -ExpandProperty Path
        }

        # Configure the process
        $this.process.StartInfo.FileName = $PowerShellExe
        $this.process.StartInfo.UseShellExecute = $false
        $this.process.StartInfo.Arguments = "-NoLogo"
        $this.process.StartInfo.RedirectStandardInput = $true
        $this.process.StartInfo.RedirectStandardOutput = $true
        $this.process.StartInfo.CreateNoWindow = $false
        $this.process.EnableRaisingEvents = $true

        # Attach an asynchronous event handler to the output
        $stdEvent = Register-ObjectEvent -InputObject $this.process -EventName OutputDataReceived -Action {
            param([Object]$PSSender, [System.Diagnostics.DataReceivedEventArgs]$DataArgs)
            if ($null -ne $DataArgs.Data) {
                # Set the max length of the output list to 100 items
                $global:processHandler.AppendOutput($DataArgs.Data, 100)
            }
        }.GetNewClosure()

        # Save the EventID so we can unregister the event later
        $this.EventID = $stdEvent.Id

        # Start the process
        $this.process.Start()
        # Start reading the output asynchronously
        $this.process.BeginOutputReadLine()
    }
    [void] StopProcess() {
        # Stop reading the process output so we can remove the event handler
        $this.process.CancelOutputRead()
        Get-EventSubscriber | Where-Object { $_.SubscriptionId -like $this.EventID } | Unregister-Event

        # Assuming process has not already exited, destroy the process
        if (-not $this.process.HasExited) {
            $this.process.Kill()
        }
        Write-Information -MessageData "Closing process" -Tags "Close", "Process"
        $this.process.Close()
    }
    [void] Expect([string] $regexString, [int] $timeoutMs, [bool] $continueOnTimeout, [bool]$EOF) {
        # If user is expecting end of automation process, close the process.
        if ($EOF) {
            $this.StopProcess()
        }
        else {
            [bool]$IsMatched = $false
            [int] $timeout = 0

            # If a timeout was provided specifically to this expect, override any global settings
            if ($timeoutMs -gt 0) {
                $timeout = $timeoutMs
            }
            elseif ($this.timeoutSeconds -gt 0) {
                $timeout = $this.timeoutSeconds
            }
            # Calculate the max timestamp we can reach before the expect times out
            [long] $maxTimestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds() + $timeout
            # While no match is found (or no timeout occurs), continue to evaluate output until match is found
            do {
                $this.output | ForEach-Object {
                    $line = $_
                    if ($line -match $regexString -or $line -like $regexString) {
                        Write-Information -MessageData "Match found: $line" -Tags "Match", "Found"
                        $IsMatched = $true
                        break
                    }
                }
                # Clear the output to keep the buffer nice and lean
                $this.output.Clear()

                # If a timeout is set and we've exceeded the max time, throw timeout error and stop the loop
                if ($timeout -gt 0 -and [DateTimeOffset]::Now.ToUnixTimeSeconds() -ge $maxTimestamp) {
                    [string]$timeoutMessage = "Timed out waiting for: '$($regexString)'"
                    $IsMatched = $true
                    if (-not $continueOnTimeout) {
                        $this.StopProcess()
                        throw [Exception]::new($timeoutMessage)
                    }
                    else {
                        Write-Information -MessageData $timeoutMessage -Tags "Timeout"
                    }
                    break
                }

                # TODO: Evaluate if this timeout is too much or if we should attempt to evaluate matches as they arrive.
                [System.Threading.Thread]::Sleep(500)
            } while (-not $IsMatched)
        }
    }
    [void] Send([string]$command, [bool]$noNewline) {
        $this.process.StandardInput.Write($command + $(if ($noNewline) { "" }else { "`n" })) | Out-Null
    }
    [void] AppendOutput([string]$data, [int]$maxLength) {
        Write-Host $data

        # If there are too many items in the array, truncate items starting from the oldest.
        if ($this.output.Count -gt $maxLength) {
            [int]$removeCount = $this.output.Count - $maxLength
            $this.output.RemoveRange(0, $removeCount)
        }

        $this.output.Add($data)
    }
}

$global:processHandler = [ExpectHandler]::new()

# Spawn a child process to execute commands in
function Invoke-Spawn {
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
    param(
        [string]$Regex,
        [int]$Timeout = $null,
        [switch]$ContinueOnTimeout,
        [switch]$EOF
    )
    try {
        $processHandler.Expect($Regex, $Timeout, $ContinueOnTimeout, $EOF)
    }
    catch {
        Write-Warning "Expect encountered an error!"
        Write-Error $_
        throw
    }
}

function Close-Spawn {
    param ()
    $processHandler.StopProcess()
}

New-Alias -Name Spawn -Value "Invoke-Spawn"
New-Alias -Name Expect -Value "Wait-Expect"
New-Alias -Name Send -Value "Send-String"
New-Alias -Name Close -Value "Close-Spawn"