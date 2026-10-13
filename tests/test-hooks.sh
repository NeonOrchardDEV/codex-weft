#!/bin/bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASSED=0
FAILED=0

assert_eq() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  ✓ $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $test_name"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        FAILED=$((FAILED + 1))
    fi
}

assert_contains() {
    local test_name="$1"
    local haystack="$2"
    local needle="$3"
    if printf '%s' "$haystack" | grep -Fq "$needle"; then
        echo "  ✓ $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ $test_name"
        echo "    expected to find: $needle"
        echo "    actual:           $haystack"
        FAILED=$((FAILED + 1))
    fi
}

assert_json_field() {
    local test_name="$1"
    local json="$2"
    local field="$3"
    local expected="$4"
    local actual
    actual=$(echo "$json" | jq -r "$field" 2>/dev/null)
    assert_eq "$test_name" "$expected" "$actual"
}

assert_file_exists() {
    local test_name="$1"
    local path="$2"
    assert_eq "$test_name" "true" "$([ -f "$path" ] && echo true || echo false)"
}

echo ""
echo "=== plugin manifests ==="
assert_file_exists "marketplace manifest exists" "$REPO_ROOT/.agents/plugins/marketplace.json"
assert_file_exists "weft plugin manifest exists" "$REPO_ROOT/plugins/weft/.codex-plugin/plugin.json"
assert_file_exists "weft hook config exists" "$REPO_ROOT/plugins/weft/hooks/hooks.json"
assert_file_exists "weft powershell common exists" "$REPO_ROOT/plugins/weft/scripts/common.ps1"
assert_file_exists "weft powershell session start hook exists" "$REPO_ROOT/plugins/weft/scripts/on-session-start.ps1"
assert_file_exists "weft powershell stop hook exists" "$REPO_ROOT/plugins/weft/scripts/on-stop.ps1"
assert_file_exists "weft powershell permission request hook exists" "$REPO_ROOT/plugins/weft/scripts/on-permission-request.ps1"
assert_file_exists "weft powershell prompt submit hook exists" "$REPO_ROOT/plugins/weft/scripts/on-prompt-submit.ps1"
assert_file_exists "weft powershell post tool use hook exists" "$REPO_ROOT/plugins/weft/scripts/on-post-tool-use.ps1"
assert_file_exists "github workflow exists" "$REPO_ROOT/.github/workflows/test.yml"
assert_json_field "marketplace name" "$(cat "$REPO_ROOT/.agents/plugins/marketplace.json")" ".name" "codex-weft"
assert_json_field "weft plugin name" "$(cat "$REPO_ROOT/plugins/weft/.codex-plugin/plugin.json")" ".name" "weft"
assert_contains "weft hooks use PLUGIN_ROOT" "$(cat "$REPO_ROOT/plugins/weft/hooks/hooks.json")" '${PLUGIN_ROOT}/scripts/on-session-start.sh'
assert_contains "weft hooks include prompt submit" "$(cat "$REPO_ROOT/plugins/weft/hooks/hooks.json")" '${PLUGIN_ROOT}/scripts/on-prompt-submit.sh'
assert_contains "weft hooks include post tool use" "$(cat "$REPO_ROOT/plugins/weft/hooks/hooks.json")" '${PLUGIN_ROOT}/scripts/on-post-tool-use.sh'
assert_json_field "weft session start uses Windows PowerShell" "$(cat "$REPO_ROOT/plugins/weft/hooks/hooks.json")" ".hooks.SessionStart[0].hooks[0].commandWindows" 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${PLUGIN_ROOT}/scripts/on-session-start.ps1"'
assert_json_field "weft stop uses Windows PowerShell" "$(cat "$REPO_ROOT/plugins/weft/hooks/hooks.json")" ".hooks.Stop[0].hooks[0].commandWindows" 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${PLUGIN_ROOT}/scripts/on-stop.ps1"'
assert_json_field "weft permission request uses Windows PowerShell" "$(cat "$REPO_ROOT/plugins/weft/hooks/hooks.json")" ".hooks.PermissionRequest[0].hooks[0].commandWindows" 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${PLUGIN_ROOT}/scripts/on-permission-request.ps1"'
assert_json_field "weft prompt submit uses Windows PowerShell" "$(cat "$REPO_ROOT/plugins/weft/hooks/hooks.json")" ".hooks.UserPromptSubmit[0].hooks[0].commandWindows" 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${PLUGIN_ROOT}/scripts/on-prompt-submit.ps1"'
assert_json_field "weft post tool use uses Windows PowerShell" "$(cat "$REPO_ROOT/plugins/weft/hooks/hooks.json")" ".hooks.PostToolUse[0].hooks[0].commandWindows" 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${PLUGIN_ROOT}/scripts/on-post-tool-use.ps1"'


echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
