# atlas

A model for describing what is on disk, so that work can start without re-explaining it.

## What atlas is

The ordinary use is plain. A person catalogs a project's resources once. From then on, an agent
told the project opens the catalog, finds the checkouts and the document to read next, and gets
to work. The catalog exists for the questions that run past one repository: which project does
this checkout belong to, what else depends on it, where is it on this machine, what has to be
cloned and installed before a task can run at all.

Those facts have three homes, and keeping them apart is most of the model. A person's own catalog
holds what is true only on their machines, which is where things are. A project's shared catalog,
kept in the project's own repository with the people who work on it, holds what is true of the
project for everyone: what it is made of and what depends on what. And a repository says for itself
what it is and which project it belongs to, in its own README or agent instructions. Facts move
between the three in fixed directions, and a path on one machine never leaves it.

The model prescribes a small vocabulary and stops there. It does not name your catalog, your
repositories or your directories, and a project that adopts it keeps its own documentation, its
own conventions and its own build. An entry is a few fields and a paragraph.

## What is in this directory

| File         | What it is                                                      |
|--------------|-----------------------------------------------------------------|
| `SKILL.md`   | The model: reading a catalog, who owns which facts, keeping one |
| `entries.md` | The shape of an entry, and one section per type                 |

## Using it as a Claude Code skill

`atlas` is a [Claude Code](https://claude.com/claude-code) skill in the `atlas` plugin,
[gnagy/atlas-plugin](https://github.com/gnagy/atlas-plugin), which also ships the entry schema a
catalog is validated against, so the two are one version. It loads itself when work starts on a
cataloged project or a question runs past one repository, and runs on `/atlas` when you want it
deliberately. **Loading it is not permission to write.** The skill's own body says a catalog is
added to, a region charted and a pointer written only when a person asks. The plugin's root
`README.md` has the install steps.

Nothing in this directory depends on Claude Code beyond the skill front matter. The model is prose.
