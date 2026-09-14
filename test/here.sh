#!/usr/bin/env bash
# Tests for `atlas here` and the hook that runs it. Run: bash test/here.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ATLAS="$ROOT/bin/atlas"
HOOK="$ROOT/hooks/atlas-here.sh"
failures=0

check() {
  local label="$1"; shift
  if "$@"; then printf 'ok   %s\n' "$label"; else printf 'FAIL %s\n' "$label"; failures=$((failures + 1)); fi
}

same() {
  [[ "$1" == "$2" ]] && return 0
  printf -- '--- want\n%s\n--- got\n%s\n' "$2" "$1"
  return 1
}

exit_code_is() {
  local want="$1"; shift
  "$@" >/dev/null 2>&1
  [[ $? -eq "$want" ]]
}

# A fake home, so `~` in the fixture resolves inside it. Physical, because macOS's
# temporary directory sits behind a symlink and `atlas here` compares physical paths.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$(cd "$TMP" && pwd -P)"
export ATLAS_CONFIG="$HOME/catalogs"
unset XDG_CONFIG_HOME

entry() {  # entry <file> <front matter lines...>
  local file="$1"; shift
  mkdir -p "$(dirname "$file")"
  { printf -- '---\n'; printf '%s\n' "$@"; printf -- '---\n\nProse.\n'; } >"$file"
}

C="$HOME/atlas"
N="$C/wiki/notes/namespace/me"
entry "$N/project/work.md" 'title: Work' 'type: project'
entry "$N/project/api.md" 'title: API' 'type: project' 'project: work'
entry "$N/project/lonely-sub.md" 'title: lonely' 'type: project' 'project: work'
entry "$N/repo/acme-api.md" 'title: acme api' 'type: repo' 'location: git@example.com:acme/api.git'
entry "$N/environment/laptop/laptop.md" 'title: laptop' 'type: environment' 'location: ~/atlas'
entry "$N/environment/laptop/workspace/atlas.md" 'title: atlas checkout' 'type: workspace' 'location: ~/atlas/'
entry "$N/environment/laptop/workspace/work.md" 'title: work' 'type: workspace' 'location: ~/Work' 'project: work'
entry "$N/environment/laptop/workspace/api.md" 'title: "acme api"' 'type: workspace' 'location: ~/work/api' 'project: api' 'checkout-of: acme-api'
entry "$N/environment/laptop/material/data.md" 'title: data' 'type: material' "location: '~/work/api/data dir'"
entry "$N/environment/laptop/workspace/api-v2.md" 'title: api-v2' 'type: workspace' 'location: ~/work/api-v2'
entry "$N/environment/laptop/workspace/sub.md" 'title: sub' 'type: workspace' 'location: ~/work/sub' 'project: lonely-sub'
entry "$N/environment/laptop/workspace/absolute.md" 'title: absolute' 'type: workspace' "location: $HOME/abs"
entry "$N/environment/laptop/unknown.md" 'title: what' 'type: unknown' 'location: ~/work/api'
entry "$N/environment/laptop/workspace/orphan.md" 'title: orphan' 'type: workspace' 'location: ~/orphan' 'project: nowhere'
entry "$N/environment/server/server.md" 'title: server' 'type: environment' 'location: /srv/atlas'
entry "$N/environment/server/workspace/api.md" 'title: server api' 'type: workspace' 'location: ~/work/api'
# Outside the notes, but a .md with front matter all the same: the section is what bounds a lookup.
entry "$C/instructions/api.md" 'title: stray' 'type: workspace' 'location: ~/work/api'
mkdir -p "$HOME/work/api/data dir/raw" "$HOME/Work/api-v2" "$HOME/abs" "$C/node_modules/x"
entry "$C/node_modules/x/laptop.md" 'title: decoy' 'type: environment' 'location: ~'
ln -s "$HOME/work/api" "$HOME/api-link"

E="$N/environment/laptop"
P="$N/project"
HEAD="atlas: environment laptop, catalog $C"
COLS=$'type\tname\tproject\tentry'

check "no config exits 3 with nothing on stdout" exit_code_is 3 "$ATLAS" here "$HOME"
check "no config prints nothing on stdout" test -z "$("$ATLAS" here "$HOME" 2>/dev/null)"

printf '# catalogs on this machine\n\nlaptop ~/atlas\n' >"$ATLAS_CONFIG"

check "an uncataloged path prints one line" same "$("$ATLAS" here /)" "$HEAD"
check "a path outside every placement prints one line" same "$("$ATLAS" here "$HOME/elsewhere")" "$HEAD"

want="$HEAD
$COLS
workspace	work	work	$E/workspace/work.md
workspace	acme api	api	$E/workspace/api.md
material	data	-	$E/material/data.md
project	Work	-	$P/work.md
project	API	work	$P/api.md"
check "a nested path lists its chain outermost first, then projects after their parents" \
  same "$("$ATLAS" here "$HOME/work/api/data dir/raw")" "$want"
check "the path need not exist" same "$("$ATLAS" here "$HOME/work/api/data dir/raw/not/yet")" "$want"
check "a symlink resolves to the placement it points into" \
  same "$("$ATLAS" here "$HOME/api-link/data dir")" "$want"
check "the path defaults to the current directory" \
  same "$(cd "$HOME/work/api/data dir/raw" && "$ATLAS" here)" "$want"
check "a relative path resolves against the current directory" \
  same "$(cd "$HOME/work" && "$ATLAS" here "api/data dir")" "$want"
check "paths compare case-insensitively" same "$("$ATLAS" here "$HOME/WORK/API/Data Dir/raw")" "$want"

check "a sibling sharing a prefix is not contained" same "$("$ATLAS" here "$HOME/work/api-v2")" "$HEAD
$COLS
workspace	work	work	$E/workspace/work.md
workspace	api-v2	-	$E/workspace/api-v2.md
project	Work	-	$P/work.md"

check "a subproject with no workspace of its parent still lists the parent" \
  same "$("$ATLAS" here "$HOME/work/sub")" "$HEAD
$COLS
workspace	work	work	$E/workspace/work.md
workspace	sub	lonely-sub	$E/workspace/sub.md
project	Work	-	$P/work.md
project	lonely	work	$P/lonely-sub.md"

check "the catalog checkout lists the environment before the workspace at the same path" \
  same "$("$ATLAS" here "$C/wiki")" "$HEAD
$COLS
environment	laptop	-	$E/laptop.md
workspace	atlas checkout	-	$E/workspace/atlas.md"

check "an absolute location works without ~" same "$("$ATLAS" here "$HOME/abs")" "$HEAD
$COLS
workspace	absolute	-	$E/workspace/absolute.md"

check "a project with no entry says so" same "$("$ATLAS" here "$HOME/orphan")" "$HEAD
$COLS
workspace	orphan	nowhere	$E/workspace/orphan.md
project	nowhere	-	(no entry)"

# Two checkouts on one host: the path inside the second uses its line, anything else the first.
S="$HOME/sandbox"
entry "$S/notes/server/server.md" 'title: server' 'type: environment' 'location: ~/sandbox'
entry "$S/notes/server/api.md" 'title: sandboxed api' 'type: workspace' 'location: ~/work/api'
printf 'laptop %s\nserver   ~/sandbox  \n' "$C" >"$ATLAS_CONFIG"
check "a path outside every listed checkout uses the first line" \
  same "$("$ATLAS" here "$HOME/work/api-v2" | head -1)" "$HEAD"
check "a path inside a listed checkout uses that line" same "$("$ATLAS" here "$S/notes")" \
  "atlas: environment server, catalog $S
$COLS
environment	server	-	$S/notes/server/server.md"

printf 'nowhere ~/atlas\n' >"$ATLAS_CONFIG"
check "an environment with no entry exits 1" exit_code_is 1 "$ATLAS" here "$HOME"
check "an environment with no entry prints nothing on stdout" test -z "$("$ATLAS" here "$HOME" 2>/dev/null)"
printf 'laptop ~/gone\n' >"$ATLAS_CONFIG"
check "a missing catalog exits 1" exit_code_is 1 "$ATLAS" here "$HOME"
printf 'laptop\n' >"$ATLAS_CONFIG"
check "a line without a path exits 1" exit_code_is 1 "$ATLAS" here "$HOME"
printf '# nothing\n' >"$ATLAS_CONFIG"
check "a config listing no catalog exits 1" exit_code_is 1 "$ATLAS" here "$HOME"
check "two paths is bad usage" exit_code_is 2 "$ATLAS" here a b

# The hook.
if command -v jq >/dev/null 2>&1; then
  hook() { printf '{"hook_event_name":"%s","cwd":"%s"}' "$1" "$2" | bash "$HOOK"; }

  rm -f "$ATLAS_CONFIG"
  check "hook: no config is silent" test -z "$(hook SessionStart "$HOME/work/api")"

  printf 'laptop ~/atlas\n' >"$ATLAS_CONFIG"
  out="$(hook SessionStart "$HOME/work/api")"
  check "hook: SessionStart output names its event" same "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" SessionStart
  check "hook: the context is exactly what atlas here prints" \
    same "$(jq -r .hookSpecificOutput.additionalContext <<<"$out")" "$("$ATLAS" here "$HOME/work/api")"
  out="$(hook SubagentStart "$HOME/elsewhere")"
  check "hook: SubagentStart output names its event" same "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" SubagentStart
  check "hook: an uncataloged directory gets one line" \
    same "$(jq -r .hookSpecificOutput.additionalContext <<<"$out")" "$HEAD"

  printf 'nowhere ~/atlas\n' >"$ATLAS_CONFIG"
  out="$(hook SessionStart "$HOME")"
  check "hook: a broken config is reported, not swallowed" \
    bash -c 'jq -r .hookSpecificOutput.additionalContext <<<"$1" | grep -q "no environment entry nowhere.md"' _ "$out"
else
  printf 'skip hook tests: jq is not installed\n'
fi

exit "$failures"
