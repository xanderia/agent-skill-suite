# 🦁 XANDERIA Agent Skill Suite

**Give your project a knowledge base your AI agent can actually use.**

A Claude Code plugin built on the
[Open Knowledge Format (OKF)](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) —
an open spec for structuring documentation as *concepts* that machines can navigate, trust and keep
current.

Point it at a codebase, a vocabulary trainer, a research archive or a book manuscript. It asks a few
questions the first time, then gets out of your way.

## What you get

| Skill | What it does |
| :--- | :--- |
| **`/xnd:kb-*`** — your knowledge base | |
| `/xnd:kb-update` | Sets up a knowledge base, or keeps an existing one healthy — tracks changes to the OKF spec, migrates your files to match **and updates its own instructions to match too**, re-verifies your third-party reference docs against upstream, splits files that grew too big, sharpens summaries, and regenerates every index |
| | |
| **`/xnd:project-*`** — your whole project | |
| `/xnd:project-review` | Reads your whole project — documentation *and* substance — cross-references the two, and writes a dated report: what's strong, what drifted, what to do next |
| | |
| **`/xnd:plugin-*`** — this plugin itself | |
| `/xnd:plugin-uninstall` | Cleanly removes everything it added. Dry run first, confirmation before anything is touched, and your writing always stays put |

Skills are grouped by namespace, so `/xnd:` plus a prefix tells you what a skill acts on before you
read a word of its description.

## Get started

```bash
/plugin marketplace add xanderia/agent-skill-suite
/plugin install xnd@agent-skill-suite
```

Then run:

```bash
/xnd:kb-update
```

On a project with no knowledge base yet, it walks you through a short setup — where your knowledge
lives, how you like files named, what to ignore — and writes the answers down. **It never asks
again.** Every run after that just does the work and hands you a short, readable summary.

Already using OKF? It detects what you have and adopts it rather than overwriting.

## How it adapts to your project

Nothing is hardcoded. Your answers live in your metadata directory's `index.md` frontmatter — the
location the OKF spec itself recommends — so the skills read your project's rules rather than
imposing anyone else's.

Two settings do most of the work:

- **`okf_root`** — what belongs to the knowledge base. Often `/`.
- **`okf_metadata_dir`** — where configuration, plans, reference docs and review reports live.

They're independent, which is what makes the same plugin fit very different projects. A codebase
usually keeps its knowledge in a `Notes/` folder and sets both there. A writing project sets
`okf_root: "/"` — because *everything* is the knowledge — while keeping `Notes/` for the machinery.

`/xnd:project-review` reads one more file, `Review Prompt.md`, where you declare what a good review
looks like *for you*: which dimensions matter, what order to read things in, which conventions to
hold the project to. A software project might ask for type-system health and secret hygiene; a novel
might ask whether the prose holds its voice.

## A few promises

- **Nothing is deleted.** Removals are proposed, never performed.
- **Nothing is committed.** Every change lands in your working tree for you to read first.
- **Archives stay archived.** Historical documents are never rewritten — and never nagged about
  either. A broken link in a five-year-old document you've promised never to touch is history, not a
  defect, so it's counted rather than shouted. (`--strict` shows you everything, always.)
- **Trust is earned, not stamped.** The skills mark what a machine verified against upstream, and
  leave the human sign-off to you — because a blanket "verified" tells you nothing.

## Two ideas worth knowing before you start

**Archiving is a one-way door.** Once a document enters an archive, the skills never touch it again —
so everything that must be true of it forever gets stamped *before* the move, not after. Skip that
order and you end up with archived files frozen on an old format that nothing is allowed to migrate.
The skill performs the steps for you in the right sequence.

**Stale is not the same as deprecated, and neither is a tag.** A document that is *superseded* says so
in `status`. A document that is merely *out of date* says so by having a `stale_after` date in the
past. A document nobody has checked says so by having no `verified` entry. Three questions, three
fields, no overlap — which is why the skills will not let you express one of them with a tag, or
silence a stale warning by pushing its date into the future.

## Local development

Two ways to run the suite from a checkout. They answer different questions.

**Fast loop** — edit, reload, repeat. Skips the marketplace entirely:

```bash
claude --plugin-dir ./plugins/xnd
/reload-plugins
```

**Dogfooding** — use the plugin exactly as an installed user would, from the same repo you develop it
in. A marketplace is just a directory containing `.claude-plugin/marketplace.json`, and `add` accepts
a path, so point it at your own working tree:

```bash
/plugin marketplace add ./Code/AgentSkillSuite
/plugin install xnd@agent-skill-suite
```

A directory-sourced marketplace is **linked, not copied** — the install points straight back at your
working tree — so edits to a `SKILL.md` are live in the next session, with no reinstall step. Only
changes to `marketplace.json` or `plugin.json` need `/plugin marketplace update agent-skill-suite`.

Use `--scope project` to commit the marketplace entry so collaborators get it automatically, or
`--scope local` to keep it to your machine. Either way the install resolves through the real
marketplace code path, so a broken `marketplace.json`, a bad `source` path or a missing skill fails
for you before it fails for anyone else.

## Contributing and releases

[MAINTAINING.md](MAINTAINING.md) covers the repository topology, how releases are versioned and
published, and the spec-baseline rule. [CHANGELOG.md](CHANGELOG.md) records every behaviour change —
worth reading before an upgrade, because the skills are prompts and a behaviour change leaves no trace
in a code diff.

## Licence

MIT — use it, fork it, make it yours.
