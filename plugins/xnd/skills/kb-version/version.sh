#!/bin/sh
# Prints the version and location of the plugin this skill ships in.
# Injected into /xnd:kb-version before the model sees it, so the answer costs no tool call.
# Must always exit 0: a failing injected command aborts the whole skill.

Root="$(cd "$(dirname "$0")/../.." && pwd)"
Version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$Root/.claude-plugin/plugin.json" 2>/dev/null | head -n 1)"

echo "version: ${Version:-unknown}"
echo "plugin root: $Root"
