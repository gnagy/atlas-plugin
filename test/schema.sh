#!/usr/bin/env bash
# Tests for `atlas schema`. Run: bash test/schema.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ATLAS="$ROOT/bin/atlas"
failures=0

check() {
  local label="$1"; shift
  if "$@"; then printf 'ok   %s\n' "$label"; else printf 'FAIL %s\n' "$label"; failures=$((failures + 1)); fi
}

exit_code_is() {
  local want="$1"; shift
  "$@" >/dev/null 2>&1
  [[ $? -eq "$want" ]]
}

V=v1alpha1
path="$("$ATLAS" schema path "$V")"
check "schema path $V prints an existing absolute file" test -f "$path" -a "${path:0:1}" = /
check "name defaults to entry" test "$path" = "$ROOT/schemas/$V/entry.schema.json"
check "an explicit name resolves the same file" test "$("$ATLAS" schema path "$V" entry)" = "$path"

link_dir="$(mktemp -d)"
ln -s "$ATLAS" "$link_dir/atlas"
check "resolves the plugin root through a symlink" test "$("$link_dir/atlas" schema path "$V")" = "$path"
ln -s "$link_dir/atlas" "$link_dir/atlas-again"
check "resolves through a chain of symlinks" test "$("$link_dir/atlas-again" schema path "$V")" = "$path"
rm -rf "$link_dir"

check "schema list includes $V" bash -c '"$1" schema list | grep -qx "$2"' _ "$ATLAS" "$V"
check "a GA version that is not shipped exits 1" exit_code_is 1 "$ATLAS" schema path v1
check "a beta version that is not shipped exits 1" exit_code_is 1 "$ATLAS" schema path v1beta1
check "unknown name exits 1" exit_code_is 1 "$ATLAS" schema path "$V" nope
check "a malformed version exits 2" exit_code_is 2 "$ATLAS" schema path v1-alpha
check "a version carrying a path exits 2" exit_code_is 2 "$ATLAS" schema path "../$V"
check "a name carrying a path exits 2" exit_code_is 2 "$ATLAS" schema path "$V" ../entry
check "missing version exits 2" exit_code_is 2 "$ATLAS" schema path
check "no command exits 2" exit_code_is 2 "$ATLAS"
check "unknown command exits 2" exit_code_is 2 "$ATLAS" frob
check "--help exits 0" exit_code_is 0 "$ATLAS" --help
check "--version names the manifest version and a working copy" test "$("$ATLAS" --version)" = "atlas 0.0.0 (working copy)"

install_dir="$(mktemp -d)"
cp -R "$ROOT/bin" "$ROOT/.claude-plugin" "$install_dir/"
printf 'abc1234\n' > "$install_dir/INSTALLED_FROM"
check "--version names the commit an install recorded" test "$("$install_dir/bin/atlas" --version)" = "atlas 0.0.0 (abc1234)"
rm -rf "$install_dir"

exit "$failures"
