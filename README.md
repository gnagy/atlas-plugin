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

**1. Install from a checkout.** From this repository's root:

```shell
scripts/install
atlas --version    # atlas 0.0.0 (<commit>)
```

The script copies the working copy (`git ls-files -co`) into `~/.claude/skills/atlas`, which Claude
Code adopts as the plugin `atlas@skills-dir`, and links `~/.local/bin/atlas` into that copy. The
commit it installed from is in `INSTALLED_FROM`, and `atlas --version` prints it. Editing the checkout
changes nothing until the script runs again. `plugin.json` stays at `0.0.0`; a snapshot never bumps
it, and there is no marketplace to install from until a first release above that.

**2. Remove any other copy.** A marketplace install of `atlas` loads beside this one, and the script
refuses while one is there. A standalone copy of the skill from `gnagy/claude-skills`, at
`~/.agents/skills/atlas`, loads beside it too.

```shell
claude plugin uninstall atlas@atlas-plugin
claude plugin marketplace remove atlas-plugin
npx skills remove atlas -g -y
```

**Then start a new Claude Code session**; a running one keeps what it already loaded.
