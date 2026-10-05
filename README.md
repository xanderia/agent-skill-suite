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
| `/xnd:kb-version` | Tells you which plugin version this session runs and where it's loaded from, plus your knowledge base's OKF spec version. Instant and read-only |
| `/xnd:kb-check-setup` | Checks that your setup actually works: which instruction file holds it, whether your agent loads it, and whether the rules really reached the session. **Read-only**: it changes nothing and fetches nothing, and tells you what would fix each problem |
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

**Upgrading from an older version?** Run `/xnd:kb-check-setup`, then `/xnd:kb-update`. The update
walks [Update Migration.md](plugins/xnd/Update%20Migration.md), which lists what each version needs
from an existing installation. It fixes what it can, and tells you what needs your decision.

**Works with `AGENTS.md` or `CLAUDE.md`.** The setup adds a short section to whichever instruction
file your project already uses, pointing at one generated rules file. The plugin doesn't pick a side:
it gives your agent the facts (which file Claude loads, when a `CLAUDE.md` hides an `AGENTS.md`) and
asks before touching any other file. Unsure whether it's working? `/xnd:kb-check-setup` tells you,
and changes nothing.

## How it adapts to your project

Nothing is hardcoded. Your answers live in one commented file,
`<metadata dir>/_Configuration_/Configuration.yaml`. The skills read your project's rules from there
rather than imposing anyone else's, and you're welcome to edit it by hand: the next run picks up the
change and regenerates everything derived from it.

Two settings do most of the work:

- **`layout.root`** — what belongs to the knowledge base. Often `/`.
- **`layout.metadata_dir`** — where configuration, plans, reference docs and review reports live.

They're independent, which is what makes the same plugin fit very different projects. A codebase
usually keeps its knowledge in a `Notes/` folder and sets both there. A writing project sets
`root: "/"` (because *everything* is the knowledge) while keeping `Notes/` for the machinery.

Your naming convention holds everywhere, including the generated rules file: `Knowledge Base/`
stays `Knowledge Base/` if that's how you name things.

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
in a code diff. [Update Migration.md](plugins/xnd/Update%20Migration.md) is its practical counterpart:
what to check and fix in a project installed with an older version.

## Licence

MIT — use it, fork it, make it yours.
