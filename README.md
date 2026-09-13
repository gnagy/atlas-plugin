# atlas-plugin

The `atlas` cataloguing model as a Claude Code plugin. The skill and the schema a catalog's entries
are validated against ship together, so they are always one version, and a catalog repository
names a schema version instead of keeping a copy.

## What it ships

| Part                                  | What it is                                                                            |
|---------------------------------------|---------------------------------------------------------------------------------------|
| `skills/atlas/`                       | The skill, on `/atlas`: the model, the entry types, and a short introduction          |
| `schemas/<version>/entry.schema.json` | The shape of an entry's front matter; `awt` validates a catalog against it            |
| `bin/atlas`                           | The command line that prints where a schema is, so no repository commits a local path |

Schema versions follow Kubernetes: `v1alpha1` and `v1beta1` may change in place, `v1` is frozen
once published. `v1alpha1` is the only one shipped so far.

## The command line

```shell
atlas schema path v1alpha1          # absolute path of the entry schema in v1alpha1
atlas schema path v1alpha1 entry    # the same, naming the schema
atlas schema list                   # the versions this plugin ships, one per line
```

Exit codes: 0 ok, 1 no such schema, 2 bad usage. `bash test/schema.sh` runs the tests; they also
pass under macOS `/bin/bash` 3.2.

## Using the schema in a catalog

`awt` does the validation and reads schema files by path from `awt.config.mjs`. A catalog's config
asks `atlas` for the path when it loads:

```js
import {execFileSync} from 'node:child_process'
const entrySchema = execFileSync('atlas', ['schema', 'path', 'v1alpha1'], {encoding: 'utf8'}).trim()
export default { schemas: { [entrySchema]: ['namespace/**/*.md'] } }
```

Without `atlas` on `PATH`, or with a version this plugin does not ship, loading the config fails
loudly rather than skipping validation.

## Setup

**1. Add the marketplace and install the plugin.** From GitHub, or from a local checkout by path:

```shell
claude plugin marketplace add gnagy/atlas-plugin
claude plugin install atlas@atlas-plugin
```

**2. Put `atlas` on `PATH`.** Link `~/.local/bin/atlas` to `bin/atlas` in a checkout of this
repository. The installed copy sits under a versioned plugin cache path that changes on every
update, so the link points at the checkout; the shim resolves the link to find its schemas.

```shell
ln -sfn ~/Dev/Projects/AiSandbox/tools/atlas-plugin/bin/atlas ~/.local/bin/atlas
atlas schema list
```

**3. Remove a standalone copy of the skill.** A machine that installed `atlas` from
`gnagy/claude-skills` has it at `~/.agents/skills/atlas`, symlinked from `~/.claude/skills/atlas`.
Left in place it loads beside the plugin's copy.

```shell
npx skills remove atlas -g -y
ls ~/.claude/skills/atlas ~/.agents/skills/atlas   # both gone
```

**Then start a new Claude Code session**; a running one keeps what it already loaded.
