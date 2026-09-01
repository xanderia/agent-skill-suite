# Changelog

The skills are prompts, so behaviour changes do not show up as code diffs. Everything that changes
what the plugin *does* is recorded here.

## 0.4.0 — 2026-08-31

**External-KB metadata, and one more archiving step.**

- **`Archiving a document` gained a first step: rescue what is still live.** Read the document for
  unfinished business — unchecked boxes, open questions, deferred decisions — and move each somewhere
  active *before* the move. The archive is where open items go to die quietly, because the `git mv` is
  the last moment anyone reads them. The step also says to verify the finished parts really are
  finished rather than trusting the document's account of itself.
- **New section: `External KB metadata`.** Three questions about an external KB get three different
  answers. **Shape** (simple vs complex) is *derived* from the directory tree, never stored — a
  recorded copy can disagree with the tree, and the tree always wins. **Version** lives in the KB's own
  `gotchas.md` frontmatter as a producer-defined `upstream: {product, version, kind}` key beside the
  spec's `resource:`, because a reserved `index.md` cannot carry frontmatter, because `stale_after` and
  `verified` are per-document, and because one version per KB is frequently a lie when a KB is being
  repaired chapter by chapter. **The central registry is generated** from that frontmatter in Phase 6,
  never authored.
- `kind` is `semver | sha | date` and records what upstream actually publishes, so a consumer knows
  whether comparing two values means anything. A git-hosted spec needs a SHA precisely because its
  declared version can lie; a package registry gives honest semver.
- Phase 3 now stamps the pinned version during upstream verification; Phase 6 regenerates the registry.

## 0.3.0 — 2026-08-31

**`kb-update` gained `Phase 0 — Verify the installation`.** The skill now checks how it is installed
before doing anything else, and repairs or migrates the installation if needed.

- **The install shape changed** from a long block pasted into `CLAUDE.md` to a thin **anchor** — a
  heading, a marker comment, one sentence and an `@…/base-prompt.md` import — pointing at a generated
  base prompt at the new `okf_base_prompt` key. Phase 0 detects the legacy inline shape and migrates
  it automatically, rebasing the moved text's relative links.
- The motivation is **atomicity, not context savings**: imported files are expanded into context at
  launch exactly as if inlined. What changes is ownership — the skill regenerates a file it owns
  instead of surgically rewriting the user's most important file, and uninstall becomes a deletion
  plus one line rather than fuzzy block-matching.
- **Three `@`-import constraints are now documented and enforced.** Import paths **cannot contain
  spaces** (no quoting mechanism exists; whitespace truncates the path), so the workflow directory is
  kebab-case even in a Title-Case project. **HTML comments are stripped from context**, so the
  `<!-- okf:installed -->` marker is invisible unless `CLAUDE.md` is read from disk — a context-only
  check reports "not installed" for a working install and would trigger a destructive re-install.
  Both `kb-update` and `plugin-uninstall` now read the file. Imports nest at most four hops.
- **`plugin-uninstall`** treats the anchor and its base prompt as one unit, and offers inlining the
  base prompt back into `CLAUDE.md` as a middle option between keeping and removing.
- New config key: `okf_base_prompt`.

## 0.2.0 — 2026-08-31

**Archiving, immutability and self-update.** Three additions, all generalised from one failure: a
bundle was found holding archived files stranded on an old spec version, because the immutability rule
had frozen them before the migration could reach them.

- **`Archiving a document`** — an ordered procedure. The move into an archive is what freezes a file,
  so everything that must be true of it forever has to be true *before* the move: stamp
  `status: deprecated`, delete `stale_after`, drop any duplicate lifecycle tag, finish any pending
  spec migration, *then* move, then repoint active documents and index both ends.
- **`Verifier contract`** — a two-axis grading rule for project verifiers. OKF §11 hard rules stay
  errors everywhere, including inside immutable zones; house-rule findings inside those zones are
  **suppressed but counted**, with a `--strict` escape hatch. A linter that reports findings nobody is
  permitted to fix teaches its reader to ignore the real ones. `stale_after` no longer applies to a
  document marked `status: deprecated`.
- **`Phase 1b — Self-update`** — when the OKF spec moves, the skill updates its own instructions
  rather than merely reporting that they are outdated. Gated on the new `okf_skill_source` key: set
  when a project vendors the suite as source, absent when the plugin is installed read-only from a
  marketplace, in which case the skill reports what needs changing. Bounded to spec facts, the
  `## Spec baseline` line, the version, and the suite's own prose — never behaviour the spec did not
  change, and never a project's verifier implementation.
- **Hard rule 3 gained a bounded exception**: a spec migration may touch frontmatter inside an
  immutable zone — never body or links — because otherwise archives rot on a revision no consumer can
  parse, and a history that has become unreadable is not preserved, merely stuck.
- New config key: `okf_skill_source`.

## 0.1.0 — 2026-08-26

First release. Three skills, namespaced so the prefix says what each one acts on: `/xnd:kb-*` for the
knowledge base, `/xnd:project-*` for the whole project, `/xnd:plugin-*` for the plugin itself.

- **`/xnd:kb-update`** — installs or maintains an OKF bundle. Tracks the upstream spec by **commit
  SHA rather than version string**, vendors the spec for reproducibility, migrates frontmatter,
  re-verifies external reference KBs against upstream, re-chunks, re-tags and regenerates indexes.
  Absorbed a predecessor skill entirely rather than running alongside it — two skills writing the same
  frontmatter would drift.
- **`/xnd:project-review`** — reads documentation and substance, cross-references them, and writes a
  dated report. Review dimensions come from the project's own `Review Prompt.md`.
- **`/xnd:plugin-uninstall`** — removes the scaffolding, dry run first, per-item confirmation, and the
  user's writing always stays put.
- **Project-agnostic by construction.** Every project-specific rule lives in the consuming project's
  config, so the same plugin fits a codebase, a vocabulary trainer or a book manuscript.
- Four standing guarantees: nothing is deleted, nothing is committed, archives stay archived, and
  trust is earned rather than stamped.
