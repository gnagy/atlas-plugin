---
name: atlas
description: >-
  Use this skill when work on a project starts from its catalog (the user names a project or workspace and the right checkouts and documents have to be found), or when a question runs past one repository: which project a directory belongs to, what a working copy is a checkout of, what depends on it, what has to be cloned first. Also for a project whose facts are shared in a project repository, for cataloging a region on request, and for adding a project's atlas pointer to its instructions. Runs on `/atlas` as well.
---

# Atlas

Atlas helps users and agents find their way around project resources: repos, workspaces, data
directories, and the like. It is a model for keeping a catalog of those resources, for using the
catalog to make sense of them, and for sharing that information with other people who work on the
same projects.

`README.md` beside this file is a short introduction, written to be linked from shared atlas
resources for people who have not met atlas before.

## Working from a catalog

Usually the user and the agent already know about the catalog, from the prompt or from a
`CLAUDE.md`, and use it to look up context about the project that does not need repeating in the
prompt or copying into several project resources.

### Finding the catalog.

The user's user-level agent instructions can define where it is stored.
For Claude Code that is `~/.claude/CLAUDE.md`. One line is enough, for example:

```markdown
My atlas is at ~/atlas, a clone of git@github.com:me/atlas.git. Start at atlas/index.md.
```

If there is no such line, ask. Do not search the disk for a catalog, and do not work it out from
the current directory. The directory matters for orienting, not for finding the catalog.

**Which environment this is** comes from the catalog checkout itself: a local-only agent file at
its root, `CLAUDE.local.md` for Claude Code, names the environment, and that name is the section
of the catalog whose placements are true here. The file is a one-line import stub; *Instruction
files in an environment* below says what it imports. One host can hold two checkouts of the catalog,
each claiming a different environment, which is how a sandbox is told apart from the main one.
If the checkout has no such file, ask; never guess the environment from the hostname.

### Using the catalog

The steps, in general:

0. Determine whether you need context from the catalog at all. Use it only where it helps.
1. Look up the project in the catalog, from whatever named it: the prompt, a `CLAUDE.md`, the
   pointer in the project's own instructions. Then, in this environment's section, the workspaces
   that name that project, and by path what sits under them.
2. If you cannot reach a catalog, or find nothing relevant in it, tell the user and confirm
   whether to continue.
3. Narrow the scope within the workspace or project to the work at hand.
4. List the resources the catalog entries name for it: repos, wikis, data files and so on.
5. Look up details of those resources as needed, and read the document the entry points at. From
   there the project's own documentation takes over.

## Orienting

Determine where you need to perform an action and look those resource(s) up in the catalog.

For example the CWD may be the project directory while the work is in the wiki, the data directory,
or another project entirely.

The resources the prompt points at may have nothing to do with the current location, or the
current location may be unknown — the agent started in the user's home directory, in Claude Code
with no directory given, or in another project's directory the user forgot to leave. If the prompt
and context make it clear the work belongs somewhere else, orient there regardless of where you
started, and tell the user you did — never switch silently.

If you cannot orient yourself: don't guess, say so, and stop if this blocks you. This also covers
the case where the prompt does not make sense for the current location and no other location can
be worked out either — ask the user rather than picking one.

### Starting work elsewhere

The common case is not "orient in place" but "start work on a different project": the user names a
project or workspace from wherever the current session happens to be, meaning to work there, not
here. Resolve it from the catalog and **open a genuinely new session there, if this host gives you
a way to. Never use a host's directory-switch action for this, even if the host offers one and even
if asked.**

In Claude Desktop that way is the `claude://code/new?folder=<path>&q=<prompt>` deep link:
run `open "claude://code/new?folder=<resolved path>&q=<url-encoded first prompt>"` and it opens a
new Code session rooted at that path, with the prompt sitting ready in the composer — deep links
never auto-submit, by design, so say that's what to expect rather than treat it as a stall. Where a
host has no such route, fall back to handing the user the resolved path and a ready first prompt to
open a new session with themselves.

A directory-switch action, where a host has one, moves file tools and the instructions the session
loads, and stops there — every tool the session already connected to, MCP servers included, stays
pointed at wherever it was when it connected. A stateful one goes on answering for the old project
under the new project's name, and nothing about the switch says so: a wiki server was the case this
was found in, and it kept serving the old project's notes as if they were the new one's, through two
switches, silent both times. That is not a rough edge to warn about and use anyway — a write through
a tool in that state lands in the wrong project's data, and the skill will not cause that. Treat the
action as unavailable for this purpose regardless of what the host calls it or how convenient it
looks; there is no version of "the user asked for the switch" that makes a misdirected write safe.

A fresh session has nothing to carry over: its tools boot against the directory it starts in, so
there is no stale connection to inherit. Say what you resolved and why, per *Orienting* above,
whichever form the handoff takes.

## Catalog entries

One entry per resource, as a markdown note with a few front matter fields and short prose. Two
identity types, **project** and **repo**, are the same everywhere and carry no path. Three
placement types, **environment**, **workspace** and **material**, are at a path, and live in the
section of the environment where that path is true. `unknown` is for something you looked at and
could not place. A kind of thing a catalog wants to tell apart is a `subtype`, a free string, never
a new type. Every entry files under a namespace, the catalog whose facts it carries, and only the
catalog's own namespace holds placements. **Read `entries.md` beside this file** for the shape of
an entry, where each kind goes, and what each type is for; the plugin's entry schema, found with
`atlas schema path <version>`, is what an entry is validated against.

Four things decide most entries. A repo is the repository itself, and a project is a body of work;
neither is anywhere, so a directory is always a workspace or material and never a repo or a
project. A checkout is a workspace with a repo behind it, one field and no separate type.
Membership is your decision, not the directory tree's: a vendor clone beside your code is
something your project depends on, not a member of it. And the entry points at the resource's own
documentation rather than repeating it.

## Who owns which facts

A person has an atlas, their view of the world, and cooperates with other people on projects whose
facts are nobody's alone. So a fact has three possible homes, and **each says only what only it
can know**:

| Layer                        | Owns                                                                                                |
|------------------------------|-----------------------------------------------------------------------------------------------------|
| **A personal catalog**       | Placements, meaning where things are in each of this person's environments; private notes           |
| **A shared project catalog** | Membership, dependencies, external systems, which document to read next, the project's conventions  |
| **A repository itself**      | What it is, what it needs, where its documentation is; and it may claim which project it belongs to |

Facts move between the layers in fixed directions.

- **Claims flow up.** A repository says what it is and what it needs. The project catalog may
  record that. Membership stays the project's verdict, never the repository's claim.
- **Verdicts flow down.** The project catalog says who is a member. A personal catalog takes
  that as given and adds where each member is on this person's machines.
- **Placements never flow up.** A path on one machine is nobody else's business and wrong
  everywhere else. **A shared catalog never points at a personal one.**

A shared catalog is a role a repository plays, usually the project's own management repository,
which has other work to do. It sits in one directory there so it does not spread through the
rest. When two layers disagree on what a thing means, the one with authority over that fact wins,
and the disagreement is worth a sentence to whoever keeps it.

## A participating project says what it is; the user says where the catalog is

A project in a catalog carries a one-line pointer in its own agent instructions, its `CLAUDE.md`
or `AGENTS.md`, so that a session started there orients in one step. Pointers only, never a copy
of the entry. Everything in that file is loaded into every session started there, while an entry is
read when a question needs it.

**A committed file carries identity, never placement.** It usually sits at the root of a repository
other people clone, so it cannot name one person's catalog. It says what to look for, not where:
what this directory is in the model's terms, which project it belongs to, and the entry to open,
all by name, with a line saying to find them in your atlas. A project whose facts are shared may
also name its shared catalog there, because that catalog is the project's and not one person's.

**Where a personal catalog is belongs to the user's side**, in the user-level instructions
that are never in a repository: `~/.claude/CLAUDE.md` for Claude Code, different in each environment.
One line there serves every project the user has cataloged; *Finding the catalog* above shows it.
A config file for this earns itself only when a machine holds more than one catalog or a tool has
to read the list, and if one ever exists the line points at it, so the agent still discovers
nothing.

Keeping the pointer current is part of keeping the catalog. A retired entry or a renamed project
leaves a stale line here, and nothing else detects it.

## Instruction files in an environment

Claude Code loads `CLAUDE.md` and `CLAUDE.local.md` from the working directory and every
directory above it, up to the filesystem root, so a file at a workspace is read by every session
started in any checkout under it. That makes a workspace's `CLAUDE.local.md` the natural home for
the personal pointer a shared repository's root cannot carry. **The file is the environment's own
instruction file for that place, not an atlas format**: it holds whatever a session there should
know, and atlas contributes one line of it, which workspace this is, in which environment, of
which project, and the entry to open. The skill recognises nothing about the file.

**The content is versioned in the catalog and delivered by an import stub.** The file on disk is
one line, created when the workspace's entry is and never edited afterwards:

```markdown
@~/atlas/instructions/environments/maci/shelton-workspace.md
```

The file it names holds the content, and composes shared pieces by relative path, which is the
same in every checkout of the catalog:

```markdown
@../../projects/shelton.md
@../maci.md

Open this workspace in IntelliJ; the six checkouts are its modules.
```

- `instructions/projects/<project>.md` is what is true of the project everywhere: how to work
  on it, what to read first.
- `instructions/environments/<name>.md` is what is true of the environment everywhere: its
  tooling, its quirks. The catalog checkout's own `CLAUDE.local.md` is a stub importing this file,
  which is where the environment claim in *Finding the catalog* lives.
- `instructions/environments/<name>/<entry>.md` is what only that placement knows.

**Write where the answer changes**, as with `project` on entries: files stack up the tree in
order, so the outermost workspace of a project says project and environment, and a nested one
says only what differs. The directory sits outside the wiki, since these are not notes, and
mirrors the entries: one file per entry that has anything to say.

Three costs, so nobody is surprised by them. Claude Code asks once per project before following
an import that resolves outside the working directory, and declining silences the whole chain
there without asking again; `/context` shows what loaded. Other agents do not follow imports, so
to them the stub is an empty file. And a stub inside a checkout of someone else's repository is
ignored by nothing unless the environment's global git excludes name it. **No secrets in any of
these files**: their content lands in every session's context, and the catalog is a repository.

## Keeping a catalog

A catalog grows as resources are created and is kept for as long as the work lasts.

- **Add**, when something lands the catalog does not have. One unit, one entry.
- **Correct a type.** A type is a claim.
- **Resolve an `unknown`.** Ask whoever put the directory there what it was for. That answer is
  not on any disk and stops existing when they forget.
- **Retire.** A placement record dies with its directory, and an environment's whole section
  with the environment. An identity record outlives both.

**Record decisions; measure separately.** Counts and sizes are true on the day and stale after.
They go wherever the catalog keeps its chronology, dated.

**When the tree and the catalog disagree.** On what exists, the tree wins: look, and correct the
entry. On what things mean, meaning membership, dependency, and which identity is
primary, the catalog wins, because the tree records none of it.

## Charting

Charting is something the user can ask for: look at specific directories and files that are not in the
catalog yet, and add to the catalog as a stub if it matches a type in `entries.md` or custom types in the catalog.
One entry per resource. Use your judgment and the resource's own files and documentation to decide what each entry is.
Do not write `unknown` entries unless the user asks for them, for later classification;
where you cannot tell, ask.

Charting is only for existing resources that predate the catalog. The normal way a catalog grows
is one entry as each resource is created, and charting is never started on the agent's own
initiative.
