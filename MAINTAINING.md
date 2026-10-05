# Maintaining the suite

How this repository is built, versioned and published. If you only want to *use* the plugin, the
[README](README.md) is the whole story.

## Where the source lives

The published repository is an export. Development happens inside a private monorepo, and
`git subtree` pushes this directory out to GitHub with its history intact:

```
Monorepo (private)                        GitHub (public)
Code/AgentSkillSuite/       ──subtree──▶   xanderia/agent-skill-suite
  .claude-plugin/                            ↑ marketplace root
    marketplace.json                         .claude-plugin/marketplace.json
  plugins/xnd/                               plugins/xnd/…
    .claude-plugin/plugin.json
    skills/{kb-update, project-review, plugin-uninstall}/SKILL.md
  README.md · MAINTAINING.md · CHANGELOG.md
```

```bash
git subtree push --prefix=Code/AgentSkillSuite skill-suite main
```

`subtree` was chosen over submodules or a separate checkout because it needs no extra tooling and
keeps the private repository private. The marketplace submission form does accept a *"Path within
repository"*, which would let a subdirectory of a public repo serve as the marketplace — but that
means publishing the whole monorepo, which is the thing subtree exists to avoid.

**The branch argument is the remote's branch.** The monorepo's trunk is `alpha`; the subtree pushes to
`main`, because `/plugin marketplace add owner/repo` reads the repository's **default branch** and
contributors expect `main`.

> If your upstream remote is a different host from your fork's, a first subtree push can fail with
> `Permission denied (publickey)` — the local SSH agent offers the wrong host's key and never reaches
> the right one. A per-host `IdentitiesOnly yes` block in `~/.ssh/config` fixes it. The symptom looks
> nothing like an auth-configuration problem, which is why it is worth naming.

## Working on it

Two modes, described in the README's [Local development](README.md#local-development) section: a fast
`--plugin-dir` loop, and a dogfooding install through a directory-sourced marketplace that exercises
the real resolution path. Use the second before publishing anything.

A directory-sourced marketplace is **linked, not copied** — the install points back at your working
tree, so `SKILL.md` edits take effect next session. Only `marketplace.json` and `plugin.json` changes
need `/plugin marketplace update`.

## Versioning

`plugins/xnd/.claude-plugin/plugin.json` carries the version. The rule the `kb-update` skill applies
to itself, and the one to apply by hand:

| Change | Bump |
| :--- | :--- |
| Editorial correction; rewording that does not change behaviour | patch |
| A new or changed rule, phase, or config key | minor |
| A config key renamed or removed; an install shape that old installs cannot read | major |

Record every release in [CHANGELOG.md](CHANGELOG.md). The skills are prompts, not code — a behaviour
change is invisible in a diff unless someone writes it down.

## The spec baseline

`kb-update` tracks the [OKF specification](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
by **commit SHA, never by the declared version string**. This is not caution for its own sake: on
2026-08-21 the spec changed materially — every timestamp became an ISO 8601 datetime with an explicit
UTC offset — while still declaring `Version 0.2`. A version check would have reported "nothing to do"
and been wrong.

The SHA the skill's instructions were written against is recorded in its `## Spec baseline` section.
When the spec moves, `Phase 1b — Self-update` brings the skill's own text in line and updates that
line, provided the consuming project sets `layout.skill_source` in its `Configuration.yaml`. Without
that key the skill reports what needs changing rather than editing a read-only marketplace install.

## Before you publish

```bash
claude plugin validate . --strict     # marketplace + plugin manifests; --strict is the CI gate
```

Then: bump the version, write the changelog entry, dogfood the install once, and push the subtree.

**Check that the anchor still loads.** An `@` import that fails says nothing, and one did for five
releases. In a project using the plugin, ask a headless session for a value only the base prompt
carries, with tools disabled so it cannot read the file:

```bash
echo "Without tools: what does the spec.sha row of the Bundle Configuration table in your project
instructions show? Reply with only the value, or NONE." | claude -p --tools ""
```

`NONE` means the import is broken. The usual cause is a `_Name_` segment in the path.

Submission to the community marketplace goes through the Console form at
`platform.claude.com/plugins/submit`; no subscription tier gates creating or self-publishing a
marketplace.

## What is deliberately not here

- **A CLI.** The skills *detect* a conformance verifier via the project's `verifier` key and fall
  back to a manual checklist. Shipping one in `bin/` was considered and tabled: `bin/` reaches the
  agent's shell rather than an interactive terminal, so it would supplement a real install rather than
  replace it.
- **Project-specific rules.** Every one lives in the consuming project's config —
  `{metadata dir}/_Configuration_/Configuration.yaml` (grouped `spec`, `layout`, `naming`,
  `vocabulary`, `zones`, plus `verifier` and `title`), and review dimensions in
  `_Workflows_/Review Prompt.md`. A rule that cannot be expressed in config is a bug in the skill, not
  a reason to hardcode.
