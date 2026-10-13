# Hook script for Codex Stop event.
# Sends a structured Weft notification when Codex finishes a turn.

. "$PSScriptRoot\common.ps1"

if (-not (Test-ShouldUseStructured)) {
    exit 0
}

$inputJson = Read-HookInput
$inputObject = ConvertFrom-JsonSafe $inputJson
$response = [string](Get-JsonProperty $inputObject "last_assistant_message" "")
$response = Get-TruncatedText $response 200
$transcriptPath = [string](Get-JsonProperty $inputObject "transcript_path" "")

$body = New-WeftPayload $inputJson "stop" @{
    response = $response
    transcript_path = $transcriptPath
}

Send-WeftNotification "weft://cli-agent" $body
