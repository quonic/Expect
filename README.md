# Expect

Spawn, Expect, and Send, but for PowerShell in pure PowerShell!

## How to use

Just like how you would use `spawn`, `expect`, and `send`
Import the module, include in your profile, or add it to your script.

`Spawn` or `Invoke-Spawn` will spawn a pwsh or powershell process and run the command you give it. Calling `Invoke-Spawn` a second time will recreate the process, stopping the previous process.

`Expect` or `Wait-Expect` will wait for a specific output. Either Regex or a simple match. Regex it tried first.

`Send` or `Send-String` will send a string response to the process.

`Close` or `Close-Spawn` when you wish to close the process for clean up or to start a new `Invoke-Spawn` process.

### Examples

Simple match:

```powershell
Spawn -Command '$a = Read-Host -Prompt "Test Response"' # Spawn a powershell or pwsh process with a command
Expect -SimpleMatch "Test Response*" -Timeout 2 # Expect a response
Send -Command "My Response" # Send the response
Close # Close the spawned process if it still runs
```

Regex match:

```powershell
Spawn -Command '$a = Read-Host -Prompt "Test[Response]"' # Spawn a powershell or pwsh process with a command
Expect -Regex "Test\[Response\].*" -Timeout 2 # Expect a response
Send -Command "My Response" # Send the response
Close # Close the spawned process if it still runs
```

## Install

### As a module

`Install-Module -Name Expect`

or for your current user

`Install-Module -Name Expect -Scope CurrentUser`

### Include in your profile or script

Download or copy the [Expect.ps1](Expect.ps1) from the root of this repository and add it to your `Profile.ps1` or script.

## Contributions

Code or Issue contributions are welcome!
