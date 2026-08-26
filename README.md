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
| `/xnd:kb-update` | Sets up a knowledge base, or keeps an existing one healthy — tracks changes to the OKF spec, migrates your files to match, re-verifies your third-party reference docs against upstream, splits files that grew too big, sharpens summaries, and regenerates every index |
| `/xnd:review` | Reads your whole project — documentation *and* substance — cross-references the two, and writes a dated report: what's strong, what drifted, what to do next |
| `/xnd:plugin-uninstall` | Cleanly removes everything it added. Dry run first, confirmation before anything is touched, and your writing always stays put |

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

`/xnd:review` reads one more file, `ReviewConfiguration.md`, where you declare what a good review
looks like *for you*: which dimensions matter, what order to read things in, which conventions to
hold the project to. A software project might ask for type-system health and secret hygiene; a novel
might ask whether the prose holds its voice.

## A few promises

- **Nothing is deleted.** Removals are proposed, never performed.
- **Nothing is committed.** Every change lands in your working tree for you to read first.
- **Archives stay archived.** Historical documents are never rewritten.
- **Trust is earned, not stamped.** The skills mark what a machine verified against upstream, and
  leave the human sign-off to you — because a blanket "verified" tells you nothing.

## Local development

```bash
claude --plugin-dir ./plugins/xnd
/reload-plugins
```

## Licence

MIT — use it, fork it, make it yours.
