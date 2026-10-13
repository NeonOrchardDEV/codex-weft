$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Assert-Equal {
    param(
        $Expected,
        $Actual,
        [string]$Message
    )

    if ($Expected -ne $Actual) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-PowerShellHook {
    param(
        [string]$ScriptPath,
        [string]$InputJson,
        [string[]]$ScriptArguments = @()
    )

    $powershellArguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $ScriptPath
    ) + $ScriptArguments

    $output = @($InputJson | & powershell.exe @powershellArguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "$ScriptPath exited with code $LASTEXITCODE.`n$($output -join "`n")"
    }

    return $output
}

function Test-PowerShellSyntax {
    $parseFailures = New-Object System.Collections.Generic.List[string]

    foreach ($script in Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter "*.ps1") {
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $script.FullName,
            [ref]$tokens,
            [ref]$errors
        )

        foreach ($parseError in $errors) {
            [void]$parseFailures.Add("$($script.FullName): $($parseError.Message)")
        }
    }

    if ($parseFailures.Count -gt 0) {
        throw "PowerShell parse failures:`n$($parseFailures -join "`n")"
    }
}

function Test-WindowsHookCommands {
    $manifestPaths = @(
        (Join-Path $repoRoot "plugins\weft\hooks\hooks.json")
    )

    foreach ($manifestPath in $manifestPaths) {
        $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
        $pluginRoot = Split-Path (Split-Path $manifestPath -Parent) -Parent

        foreach ($event in $manifest.hooks.PSObject.Properties) {
            foreach ($group in $event.Value) {
                foreach ($hook in $group.hooks) {
                    $commandWindows = [string]$hook.commandWindows
                    Assert-True (-not [string]::IsNullOrWhiteSpace($commandWindows)) "$manifestPath $($event.Name) is missing commandWindows."

                    if ($commandWindows -notmatch '-File\s+"?\$\{PLUGIN_ROOT\}/(?<scriptPath>[^"\s]+\.ps1)"?') {
                        throw "$manifestPath $($event.Name) has an invalid PowerShell commandWindows value: $commandWindows"
                    }

                    $scriptPath = Join-Path $pluginRoot ($Matches.scriptPath -replace "/", "\")
                    Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "$manifestPath references missing script $scriptPath."
                }
            }
        }
    }
}

function Test-WeftPayload {
    . (Join-Path $repoRoot "plugins\weft\scripts\common.ps1")

    $payload = New-WeftPayload `
        '{"session_id":"session-1","cwd":"C:\\work\\project"}' `
        "test-event" `
        @{ detail = "ok" } |
        ConvertFrom-Json

    Assert-Equal "codex" $payload.agent "Weft payload agent mismatch."
    Assert-Equal "test-event" $payload.event "Weft payload event mismatch."
    Assert-Equal "session-1" $payload.session_id "Weft payload session mismatch."
    Assert-Equal "project" $payload.project "Weft payload project mismatch."
    Assert-Equal "ok" $payload.detail "Weft payload extra field mismatch."
}

function Test-WeftConsoleWriterInterop {
    . (Join-Path $repoRoot "plugins\weft\scripts\common.ps1")

    Initialize-WeftConsoleWriter
    Assert-True ($null -ne ("WeftConsoleWriter" -as [type])) "Weft console writer type was not loaded."
    [void][WeftConsoleWriter]::Write("")
}

function Test-WeftHookEntryPoints {
    $oldProtocolVersion = $env:WEFT_CLI_AGENT_PROTOCOL_VERSION
    $oldClientVersion = $env:WEFT_CLIENT_VERSION

    try {
        $env:WEFT_CLI_AGENT_PROTOCOL_VERSION = "1"
        $env:WEFT_CLIENT_VERSION = "test"
        $inputJson = '{"session_id":"session-1","cwd":"C:\\work\\project","prompt":"Test prompt","tool_name":"shell","tool_input":{"command":"echo test"},"last_assistant_message":"Done","transcript_path":"C:\\work\\transcript.jsonl"}'

        foreach ($script in Get-ChildItem -LiteralPath (Join-Path $repoRoot "plugins\weft\scripts") -Filter "on-*.ps1") {
            [void](Invoke-PowerShellHook $script.FullName $inputJson)
        }
    } finally {
        $env:WEFT_CLI_AGENT_PROTOCOL_VERSION = $oldProtocolVersion
        $env:WEFT_CLIENT_VERSION = $oldClientVersion
    }
}

Test-PowerShellSyntax
Test-WindowsHookCommands
Test-WeftPayload
Test-WeftConsoleWriterInterop
Test-WeftHookEntryPoints

Write-Host "PowerShell hook tests passed."
