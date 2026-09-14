#!/usr/bin/env bash
# Tell a session where it is, from the catalog, before its first turn.
#
# Runs `atlas here` on the session's directory and hands the output over as context.
# Nothing else: the lookup, the config and the output shape are the CLI's, so an agent
# without this hook gets the same answer by running the command.
#
# Wired to SessionStart with no matcher, so it runs again after a compaction and a
# /clear, and to SubagentStart, since a subagent gets none of its parent's context.
#
# Quiet by design: no config means this machine keeps no catalog, and every session
# on it pays one failed `test -f`. A config that names a missing catalog or
# environment is said out loud, because a silent hook there looks like a working one.
# Bash 3.2.
set -u

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null || true)
event=$(jq -r '.hook_event_name // "SessionStart"' <<<"$input" 2>/dev/null)
cwd=$(jq -r '.cwd // ""' <<<"$input" 2>/dev/null)

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)" || exit 0

out=$("$root/bin/atlas" here "${cwd:-$PWD}" 2>&1)
case $? in
  0) ;;
  3) exit 0 ;;
  *) out="atlas here failed, so this session has no orientation from the catalog: $out" ;;
esac
[[ -n "$out" ]] || exit 0

jq -n --arg e "$event" --arg c "$out" '{hookSpecificOutput: {hookEventName: $e, additionalContext: $c}}'
exit 0
