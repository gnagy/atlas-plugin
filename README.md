# atlas-plugin

The `atlas` cataloguing model as a Claude Code plugin. The skill and the schema a catalog's entries
are validated against ship together, so they are always one version, and a catalog repository
names a schema version instead of keeping a copy.

## What it ships

| Part                                  | What it is                                                                            |
|---------------------------------------|---------------------------------------------------------------------------------------|
| `skills/atlas/`                       | The skill, on `/atlas`: the model, the entry types, and a short introduction          |
| `schemas/<version>/entry.schema.json` | The shape of an entry's front matter; `awt` validates a catalog against it            |
| `bin/atlas`                           | The command line: where a schema is, and what the catalog has at a path               |
| `hooks/`                              | A session-start hook that runs `atlas here` and passes the answer to the session      |

Schema versions follow Kubernetes: `v1alpha1` and `v1beta1` may change in place, `v1` is frozen
once published. `v1alpha1` is the only one shipped so far.

## The command line

```shell
atlas schema path v1alpha1          # absolute path of the entry schema in v1alpha1
atlas schema path v1alpha1 entry    # the same, naming the schema
atlas schema list                   # the versions this plugin ships, one per line
```

Exit codes: 0 ok, 1 no such schema or catalog, 2 bad usage, 3 no config. `bash test/schema.sh` and
`bash test/here.sh` run the tests; they also pass under macOS `/bin/bash` 3.2.

## What is at this path

```shell
atlas here                          # for the current directory
atlas here ~/work/acme/api/data     # for any path, which need not exist
```

It reads a machine-local config, `~/.config/atlas/catalogs` (`$XDG_CONFIG_HOME/atlas/catalogs` where
that is set, `$ATLAS_CONFIG` over both), one catalog checkout per line, environment first:

```text
# <environment> <catalog checkout>
laptop  ~/atlas
sandbox ~/sandbox/atlas
```

A path inside a listed checkout uses that line, anything else the first. The path may contain
spaces; the environment name may not. `~` is expanded, and lines starting with `#` are skipped.

The output is one line naming the environment and the checkout, then, if anything is cataloged at
the path, a tab-separated table: every placement in that environment's section whose `location`
contains the path, outermost first, then the projects those name, each after its parents.

```text
atlas: environment laptop, catalog /Users/me/atlas
type	name	project	entry
workspace	work	work	/Users/me/atlas/wiki/notes/namespace/me/environment/laptop/workspace/work.md
workspace	acme api	api	/Users/me/atlas/wiki/notes/namespace/me/environment/laptop/workspace/api.md
material	data	-	/Users/me/atlas/wiki/notes/namespace/me/environment/laptop/material/data.md
project	Work	-	/Users/me/atlas/wiki/notes/namespace/me/project/work.md
project	API	work	/Users/me/atlas/wiki/notes/namespace/me/project/api.md
```

- **The section** is the folder holding the environment's own entry, `<environment>.md`, and
  everything under it. Entries are read from their front matter: `type`, `title`, `location`,
  `project`. Dot-directories and `node_modules` are skipped.
- **Containment** compares physical paths, case-insensitively, with `~` expanded on both sides. At
  one path the environment comes before a workspace, so the catalog checkout lists both.
- **A project with no entry** is listed with `(no entry)` in place of the file.
- **Nothing cataloged** at the path prints the first line alone. **No config** prints nothing on
  stdout and exits 3.

## The hook

`hooks/hooks.json` runs `hooks/atlas-here.sh` on `SessionStart`, with no matcher so it also runs
after a compaction or `/clear`, and on `SubagentStart`. It runs `atlas here` on the session's
directory and hands the output to the session as `additionalContext`, unchanged. With no config it
exits silently; a config naming a catalog or environment that is not there is passed on as one line
saying so. It needs `jq`, and without it does nothing. The lookup is the CLI's, so an agent without
the hook gets the same answer by running the command.

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

**3. Write the config**, if this machine keeps a catalog: one line, `<environment> <checkout>`, in
`~/.config/atlas/catalogs`. `atlas here` in a cataloged directory shows whether it took.

**Then start a new Claude Code session**; a running one keeps what it already loaded, hooks included.
