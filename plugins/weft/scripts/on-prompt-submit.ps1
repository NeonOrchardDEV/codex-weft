# Hook script for Codex UserPromptSubmit event.
# Sends a structured Weft notification when the user submits a prompt.

. "$PSScriptRoot\common.ps1"

if (-not (Test-ShouldUseStructured)) {
    exit 0
}

$inputJson = Read-HookInput
$inputObject = ConvertFrom-JsonSafe $inputJson
$query = [string](Get-JsonProperty $inputObject "prompt" "")
$query = Get-TruncatedText $query 200

$body = New-WeftPayload $inputJson "prompt_submit" @{
    query = $query
}

Send-WeftNotification "weft://cli-agent" $body
