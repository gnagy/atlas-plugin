# Catalog entries

One entry per resource. An entry is a markdown note in the catalog's wiki: front matter with a
few fixed fields, then prose. The prose says what the thing is and anything the fields cannot
carry. Keep it short; the entry points at the resource's own documentation, it does not repeat it.

## Two kinds of entry

**Identity entries** describe something that is the same everywhere: a **project** or a **repo**.
They carry no path.

**Placement entries** describe something at a path: an **environment**, a **workspace** or
**material**. A path is true in one environment only, so every placement entry lives in that
environment's section of the catalog and nowhere else. The identity entries are what the sections
have in common.

## The fields

| Field         | On                                         | Answers                                                                                      |
|---------------|--------------------------------------------|----------------------------------------------------------------------------------------------|
| `type`        | every entry                                | Which kind of thing this is                                                                  |
| `subtype`     | every entry, optional                      | Which kind of that type, in this catalog's own words                                         |
| `location`    | repo, environment, workspace, material     | Where it is: a URL for a repo, a path for the rest                                           |
| `project`     | project, workspace                         | Which project this is part of: the parent of a subproject, or the project a workspace places |
| `checkout-of` | workspace                                  | Which repo this directory is a clone of. Present, the workspace is a checkout                |
| `namespace`   | project                                    | The catalog whose shared facts these are, when it is not this one                            |
| `observed`    | environment, workspace, material, optional | When the placement was last verified, if it was recorded from outside its environment        |

Each field answers one question. **Containment is never written**: which workspace holds which
is read from the paths in a section, never from a field.

**The names and values are the schema's.** `schemas/<version>/entry.schema.json` in this plugin
is the shape an entry is validated against, and `atlas schema path <version>` prints where it is,
so a catalog's validator config names a version and never a copy. This table says what each field
means; the schema says what it may hold.

**`subtype` is a free string, and the skill defines none.** A kind of thing one catalog wants to
tell apart gets a `subtype` on one of the types above rather than a type of its own, so its entries
stay valid in any catalog that has never heard of the value. `type` and `subtype` together are how
entries are looked up: `material` of subtype `wiki`, `workspace` of subtype `sandbox`.

## Where entries go

Every entry sits in a namespace: a folder named for the catalog whose facts it carries. This
catalog's own namespace is named for its own id, and holds its identity entries and every
environment section. Another namespace holds the identity entries of a catalog whose shared facts
are kept here for now, and nothing else. Inside a namespace, entries are filed by type. The default:

```text
index.md
namespace/<this>/project/<project>.md                  identity
namespace/<this>/repo/<repo>.md                        identity
namespace/<this>/environment/<name>/<name>.md          the environment entry
namespace/<this>/environment/<name>/workspace/…        its workspaces
namespace/<this>/environment/<name>/material/…         its material
namespace/<other>/project/<project>.md                 another catalog's shared facts, held here
namespace/<other>/repo/<repo>.md
```

**Placements are only ever in this catalog's own namespace.** A shared catalog owns membership and
dependency, never where something sits on one person's disk, so no other namespace has an
`environment/`. **A folder named for a concept is that concept's exact singular name** —
`project/`, not `projects/` — so nothing has to work out a plural.

The environment entry is its section's own page: it lists what the section holds, the folder has
no `index.md` beside it, and a link to it carries the folder path, `[[environment/<name>/<name>]]`,
since a bare stem does not reach it. `subtype` gets no folder. The catalog may lay entries out
differently; what the skill fixes is that no placement sits outside a section or outside this
catalog's own namespace, and no identity entry sits inside a section. Fields name identity entries
by filename, so those names are unique across the catalog, across namespaces too. Placement entries
are named by nothing, since a placement is never pointed at, so the same filename may recur in two
sections; link one, if ever, with its folder in the link.

## The shape of an entry

```markdown
---
title: acme api
type: workspace
location: ~/work/acme/api
checkout-of: github-acme-api
---
```

## Identity entries

### project

A named body of work, and the main organizing entry. It is not local: a project has no
`location`, and where it is in a given environment is answered by the workspaces there that name
it. Projects can nest: a subproject is a project entry whose `project` names its parent, and
nothing else marks it as one. The nesting is kept on the project entries so that every
environment reads the same project tree, whether or not it holds a workspace for any of it.

`namespace` names the catalog whose shared facts the project's are, when that is not this one —
whether that catalog already has a repository of its own or is being worked out here until it
does; see *Who owns which facts* in `SKILL.md`. It agrees with the namespace folder the entry sits
in. Unwritten, the project is this catalog's own. The prose says what the project is and which
document to read next.

### repo

A version control repository, typically git: `location` is its URL. It is a shared resource, so
it carries nothing about one user or one environment. A repo can exist with no remote copy; it
still has a version history, and the entry says that it exists in one place only.

## Placement entries

### environment

One place where paths resolve: a host, a VM, a container, a sandbox with its own filesystem. Two
contexts are one environment when a path recorded in one opens the same files in the other, so a
git worktree is another workspace in the same environment, not a new one.

Each environment has its own checkout of the catalog and its own section in it, holding every
placement that exists there. `location` is that checkout's path, so another environment can say
where the catalog is over there. A session learns which environment it is in from a local-only
agent file at the catalog checkout, `CLAUDE.local.md` for Claude Code, naming the environment;
*Finding the catalog* and *Instruction files in an environment* in `SKILL.md` have the rule and
the file's shape. An environment that is thrown away takes its
section with it; one that is kept costs nothing.

### workspace

A directory where work happens, for agents, IDEs and other tools. `location` is its path. It may
be a remote share, as long as it is mounted into the environment's filesystem.

`project` names the project this workspace is a placement of, and is written **only where the
answer changes**: on the outermost workspace of a project, and on a nested workspace that belongs
to a subproject. A nested workspace never repeats its parent's project; a workspace with no
`project` and no cataloged workspace above it belongs to no project, which is a plain grouping.

**With `checkout-of` a workspace is a checkout**: one clone of a repo, in this environment. When
the working copy has several remotes, which repo it is a checkout of is your call; `origin` is
only a default. There is no separate checkout type, because the one fact that makes a workspace a
checkout is the field. So the simplest case, cloning a repo and working in it, is one entry; a
project that is one repo is that entry with `project` beside `checkout-of`; a submodule is a
checkout inside a checkout; a monorepo subdirectory assigned to a subproject is a workspace inside
a checkout, with `project` and no `checkout-of`.

A placement dies with its directory. The repo and project entries it named outlive it. A placement
is a claim about a disk that changes without anyone editing the entry. From inside its environment
the entry needs no date saying when it was last true: a path is checked by looking, which costs
nothing and answers now. A placement recorded from another environment, over ssh say, was not free
to look at, so it carries `observed: YYYY-MM-DD`, the day it was last verified there.

### material

Files that matter to a project and are worth placing apart from the directory they sit in: data
directories, documents, scans, a read-only share, a wiki inside a checkout. They may live inside a
repository or outside any; which is read from the paths above the location, never written.
`location` is its path. The prose says what it holds, how to read it, and what may be done with
it; where the repo beside it cannot describe it, because it is gitignored, this entry is the only
description.

Material is always a placement, owned by the environment it is in. A thing inside a repository
can have facts that are not about one checkout of it — a wiki's own name, for one — and those would
want an identity home; the model adds one when a catalog needs it, not before.

### unknown

Something the user or an agent added to the catalog by explicit request, not while charting, but
whose type and details are yet to be determined. Ignore it when looking for information. List
them to the user when they ask, so they can inspect and catalog them.
