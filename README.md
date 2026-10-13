# codex-weft

Codex integration for [Weft](https://github.com/NeonOrchardDEV/weft), the open-source terminal by
[NeonOrchard Studio](https://neonorchard.studio).

The `weft` plugin lets Weft follow what Codex is doing in a tab: it sends native notifications when
Codex finishes or needs your input, and feeds Weft's rich agent status (prompts, tool use, permission
requests).

## Install

Weft can install it for you from the CLI agent toolbar. To install by hand:

```bash
codex plugin marketplace add NeonOrchardDEV/codex-weft
codex plugin add weft@codex-weft
```

Then restart Codex. The plugin needs `jq` on macOS and Linux.

## Layout

```
.agents/plugins/marketplace.json    Codex marketplace manifest, name: codex-weft
plugins/weft/.codex-plugin/         Plugin manifest
plugins/weft/hooks/hooks.json       Hook config (POSIX and Windows PowerShell commands)
plugins/weft/scripts/               Hook scripts
tests/                              Hook and notification tests
```

Hooks: `SessionStart`, `Stop`, `PermissionRequest`, `UserPromptSubmit`, `PostToolUse`.

## How it works

Hooks send structured events to the terminal as OSC 777 sequences titled `weft://cli-agent`. The plugin
only emits them when Weft advertises support through the `WEFT_CLI_AGENT_PROTOCOL_VERSION` and
`WEFT_CLIENT_VERSION` environment variables, so it stays silent in other terminals.

## Tests

```bash
bash tests/test-hooks.sh
bash tests/test-notifications.sh
```

`plugins/weft/scripts/on-session-start.sh` emits `PLUGIN_VERSION`. Keep it in sync with the minimum
version in Weft's Codex plugin manager.

## Attribution

Based on [codex-warp](https://github.com/warpdotdev/codex-warp), copyright (c) Warp, MIT. Not affiliated
with or endorsed by Warp.
