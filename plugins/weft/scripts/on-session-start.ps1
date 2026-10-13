# Hook script for Codex SessionStart event.
# Emits plugin version via weft://cli-agent so Weft can track the session.

. "$PSScriptRoot\common.ps1"

if (-not (Test-ShouldUseStructured)) {
    exit 0
}

$pluginVersion = "0.4.2"
$inputJson = Read-HookInput
$body = New-WeftPayload $inputJson "session_start" @{
    plugin_version = $pluginVersion
}

Send-WeftNotification "weft://cli-agent" $body
