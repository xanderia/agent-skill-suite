# 🦁 XANDERIA Agent Skill Suite

Claude Code plugin providing portable knowledge-base tooling built on the
[Open Knowledge Format (OKF)](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md).

Nothing here is XANDERIA-specific. Every project-specific rule lives in that project's own config,
so the same skills work in a monorepo, a vocabulary trainer, or a book manuscript.

## Skills

| Skill | Purpose |
| :--- | :--- |
| `/xnd:kb-update` | Install OKF into a project, or maintain an existing bundle — track spec drift by commit SHA, migrate frontmatter, verify external KBs against upstream, re-chunk, re-tag, regenerate indexes and logs |
| `/xnd:review` | Deep holistic project review across core and project-declared dimensions; writes a dated report |
| `/xnd:plugin-uninstall` | Remove the scaffolding, with a dry run and per-item confirmation |

## Install

```bash
/plugin marketplace add xanderia/agent-skill-suite
/plugin install xnd@agent-skill-suite
```

Then run `/xnd:kb-update`. On a project with no knowledge base it asks a short series of setup
questions; afterwards it never asks again.

## Local development

```bash
claude --plugin-dir ./plugins/xnd
/reload-plugins
```

## Configuration

`/xnd:kb-update` writes its config into the metadata directory's `index.md` frontmatter — the
spec-native location per OKF §12 — and an install marker into `CLAUDE.md`. Two keys matter most:

- **`okf_root`** — what is *in* the bundle. May be `/`.
- **`okf_metadata_dir`** — where config, plans, external KBs and review reports live.

They are independent. A code-first project typically scopes the bundle to a `Notes/` folder; a
knowledge-first project sets `okf_root: "/"` while keeping metadata in `Notes/`.

## Licence

MIT
