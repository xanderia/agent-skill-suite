# Changelog

The skills are prompts, so behaviour changes do not show up as code diffs. Everything that changes
what the plugin *does* is recorded here.

## 0.11.0 — 2026-10-05

**New skill `/xnd:kb-version`: which plugin version is this session running?**

- **It answers instantly, with no tool calls.** A small script shipped beside the skill
  (`version.sh`) reads `plugin.json`, and its output is injected into the prompt before the model
  runs. The model only reformats it.
- **It shows where the plugin is loaded from**, which separates a linked development checkout from a
  marketplace copy. That was the open question when a fresh VSCodium session could not find
  `kb-check-setup`.
- **It shows the knowledge base's OKF spec version and `spec.sha`** when the base prompt's
  `## Bundle Configuration` table is in context. When it isn't, the skill says no knowledge-base rules
  reached the session and points to `/xnd:kb-check-setup`. That is why the skill sits in the `kb-`
  namespace.
- **It is read-only by harness.** `disallowed-tools` removes every tool, including Read and Bash.
  `allowed-tools: Bash(sh ${CLAUDE_SKILL_DIR}/version.sh)` pre-approves only the injected script.
- **Found while building it:** an injected `` !`command` `` goes through the normal permission check.
  A plain `cat` of the manifest was blocked whenever the plugin lived outside the working directory,
  which is the normal case for a marketplace install. A script bundled with the skill and
  pre-approved by its path is the documented way around this. Calling it as `sh <script>` means the
  executable bit does not have to survive the install. The script always exits 0, because a failing
  injected command aborts the whole skill.

Nothing to migrate: see `Update Migration.md`.

## 0.10.0 — 2026-10-05

**`Update Migration.md`: what an existing installation needs, version by version.** This file says what
changed in the plugin. The new [`plugins/xnd/Update Migration.md`](plugins/xnd/Update%20Migration.md)
says what to **check and fix in your project**, so an install made with an older version ends up
where a fresh install would put it.

- **15 entries, from 0.2.0 to 0.9.0.** Each has an ID (`0.9.0-A`), a severity (🔴 broken, 🟠 drift,
  🟢 improvement), and *Detect*, *Fix* and *Verify* steps, plus a *Fix by*: `kb-update` automatically,
  `kb-update` from the file, `kb-update` per KB, or **you**.
- **Version-agnostic by construction.** Every *Detect* is safe on any installation, and every *Fix* is
  a no-op when *Detect* finds nothing. Nothing records which version last touched a project, so there
  is no "last version" value to drift.
- **It ships inside the plugin** (`plugins/xnd/`), not at the repository root: an installed plugin
  receives only its own directory, and the skills must be able to read the file.
- **`kb-update` Phase 0 step 9 walks it.** It runs every *Detect*, applies the fixes that are its job
  within its hard rules, leaves per-KB fixes to Phase 3, reports the rest under *What needs you*, and
  lists every matched entry by ID in Phase 7. Distribution drift moves to step 10.
- **`kb-check-setup` cites entry IDs** in its findings. It does not walk the file; it stays read-only
  and within its own checks.
- **Found while writing it:** the 0.5.0 move of `ReviewConfiguration.md` to
  `_Workflows_/Review Prompt.md` was never automated. An install still on the old path ran
  `/xnd:project-review` with the core dimensions only, silently ignoring its own dimensions. That is
  entry `0.5.0-B`, and `kb-update` now applies it.

## 0.9.0 — 2026-10-05

**`AGENTS.md` support, a read-only setup check, and a fix for a base prompt that never loaded.** Run
`/xnd:kb-check-setup` to see whether you are affected, then `/xnd:kb-update` to repair: its Phase 0
migrates an affected install by itself and says so first.

- **New skill `/xnd:kb-check-setup`.** It answers one question: is the installation sound, and is it
  reaching this agent? It covers which instruction file holds the anchor, whether Claude Code loads
  that file, whether the base prompt actually reached context, import-path hazards, config paths, and
  base-prompt drift. It **changes nothing**. Its frontmatter `disallowed-tools` removes Edit, Write,
  Bash, web access, subagents and other skills while it runs, so being read-only is enforced by the
  harness, not just requested. It runs inline rather than forked, because the decisive check
  inspects the session's own context, and a forked subagent would not have that context. It reports
  what would fix each finding and leaves the decision to the human or their agent.

- **🔴 Fixed: every anchored install since 0.3.0 imported nothing.** The default base-prompt home was
  `{Metadata_Dir}/_Workflows_/knowledge-base/`, and an `@` import cannot pass through a `_Name_`
  segment. The parser reads the line as Markdown, `/_Workflows_/` becomes emphasis, and the path
  splits. Every session got the anchor's one sentence and none of the bundle's rules, with no error
  shown anywhere. Escaping does not help: `\_Workflows\_` and `<…>` fail too. Measured on XANDERIA
  with a headless probe (`claude -p --tools ""`, asking for a value only the base prompt carries):
  `NONE` before, `62432a095` after. The probe table, Claude Code 2.1.289:

  | Import | Loads |
  | :--- | :--- |
  | `@plain/a.md` · `@Dir/snake_case/h.md` | yes |
  | `@Sp\ ace/d.md` · `@Notes/Knowledge\ Base/Base\ Prompt.md` | yes |
  | `@Dir/_Mid_/c.md` · `@_Under_/b.md` | **no** |
  | `@Dir/\_Mid\_/f.md` · `@<Dir/_Mid_/k.md>` | **no** |

  - The base prompt now lives in **`{Metadata_Dir}/Knowledge Base/`**, cased per the project's
    convention. **Phase 0 step 5** moves an existing install there, along with its index, links,
    config and anchor. `_Workflows_/` keeps `Review Prompt.md`, which is read on demand and never
    imported.
  - **Phase 0 step 2 checks that the base prompt actually loaded.** Before reading the file, it looks
    for the `## Bundle Configuration` table in its own context. That self-test would have caught this
    on day one.
- **Spaces in import paths are now allowed.** Escape each one with a backslash
  (`@Notes/Knowledge\ Base/Base\ Prompt.md`). The 0.3.0 claim that `@` imports have "no escaping
  mechanism" was wrong. The kebab-case exception it justified is gone, so the user's naming
  convention applies to these names too. `layout.base_prompt` stores the real path; spaces are
  escaped only on the import line and written as `%20` in the link.
- **`AGENTS.md` and `CLAUDE.md` are both supported, and the plugin takes no side.** The three skills
  used to disagree: `kb-update` read `CLAUDE.md` first, `plugin-uninstall` read only `CLAUDE.md`, and
  `project-review` read either. On a project whose `CLAUDE.md` is just `@AGENTS.md`, `kb-update`
  Step 0, followed literally, found no marker and went to **Install**, re-installing over a working
  setup. Now:
  - all skills read both files from disk, and an existing anchor stays where it is;
  - for a new install, the user's agent chooses. The facts it needs are in one place: a table of
    what Claude Code loads in each combination of files, including when a `CLAUDE.md` hides an
    `AGENTS.md`. That section lives in `kb-check-setup`, and the other skills link to it;
  - the one hard requirement is that Claude Code loads the anchor. Editing another instruction file
    to achieve that, such as adding `@AGENTS.md` to `CLAUDE.md`, needs the human's approval.
- **The anchor links the base prompt as well as importing it.** Most non-Claude agents reading
  `AGENTS.md` do not expand `@` imports. The separate "host without `@` imports" fallback is gone,
  because every anchor now carries the link. Phase 0 adds it to existing anchors.
- **`plugin-uninstall` leaves `@AGENTS.md` in `CLAUDE.md` alone.** It is the standard shim and may
  predate the plugin.
- **`project-review` reports** an instruction file Claude Code does not load, and any `@` import whose
  target never reached context, both under dimension 7. Which file a project uses is not a finding.
- **`kb-update`: an external KB never names the project's own versions.** This reverses 0.6.0, which
  wrote disagreement between the in-use sources (binary, pin, container tag) into the KB as a gotcha.
  The in-use version still drives the recommendation and decides which facts get a marker. It is no
  longer written down; disagreement now goes to the human. Still allowed: the documented upstream
  version, upstream markers (`[1.4]`), and dated `log.md` history. The banner names only the
  documented version. The rule applies to external KBs only, and the stated reason is maintenance
  overhead: every upgrade would need a KB edit that nothing prompts. In-use versions belong in the
  project's own docs, ideally one list of every pin.
  - The **install template** writes the rule into every new base prompt.
  - **Phase 3** strips existing back-references as it verifies each KB.
  - **`project-review` dimension 9** names any it finds, file and line.
- Fixed wording left over from 0.3.0: install questions 2 and 5 and the Verifier contract wrote rules
  "into the `CLAUDE.md` section", but those rules have lived in the base prompt since the anchor shape.
- `README.md` and `MAINTAINING.md` described the pre-0.5.0 `okf_*` frontmatter configuration for four
  releases; both now describe `Configuration.yaml`.

## 0.8.0 — 2026-09-03

**Every skill states its version; one skill checks for drift.** Previously the version lived in
`plugin.json` and nothing surfaced it, so a run left no record of which version produced it — worst
for `project-review`, whose reports are immutable and dated.

- **All three skills open with their version**, read from `plugin.json` at runtime — resolved via
  `${CLAUDE_PLUGIN_ROOT}`, then relative to the skill's own directory, then `layout.skill_source`. An
  unresolvable manifest prints `plugin version unknown` and never blocks the run. **The version is
  never hardcoded into a `SKILL.md`**, and the illustrative banners deliberately read `v<version>`
  rather than a number that would go stale every release.
- **`project-review` stamps `reviewer: xnd-plugin/<version>` into the report frontmatter.** A finding
  from v0.4.0 and one from v0.9.0 are not comparable evidence, and a `diff` run now says when the two
  reports it compares came from different versions — otherwise a newly-added dimension reads as a
  regression.
- **`kb-update` Phase 0 gained a distribution-drift check**, and **its direction is gated on
  `layout.skill_source`** — the same key that already separates a vendoring publisher from a
  read-only consumer for Phase 1b:

  | `skill_source` | Compare | On drift |
  | :--- | :--- | :--- |
  | Set (vendored — the project *is* upstream) | local vs published | Local ahead → report unpublished work and name the publish command. **Never suggest updating** |
  | Absent (marketplace install) | published vs installed | Published ahead → suggest the human update. Never self-update in place |

  Getting this backwards is the trap the check exists to avoid: a project that vendors the source
  will never have an update waiting, because it *is* the update. Measured on XANDERIA at the time of
  writing — local `0.7.0`, published `0.1.0` — an unconditional "is a newer version out?" check would
  have answered "no" forever while six minor versions of unpublished work went unreported.

  It fetches the raw manifest rather than the rendered repository page, derives the URL from
  `repository` in the local `plugin.json`, and treats **every** failure as skip-and-stay-silent. A
  version check must never block a maintenance run.
- **`project-review` and `plugin-uninstall` make no network calls at all.** The review already forbade
  itself upstream fetches; an upgrade prompt during an uninstall is pure noise.
- **Fixed: `plugin-uninstall` still read config from `{Metadata_Dir}/index.md` frontmatter** — the same
  pre-0.5.0 staleness found in `project-review` for 0.7.0. Step 1, the Step 1 inventory, the Step 2
  question and the Step 5 report row all now name `_Configuration_/Configuration.yaml`, with the
  legacy frontmatter as a documented fallback, and the Step 2 question protects `okf_version` where
  OKF §12 puts it.

## 0.7.0 — 2026-09-03

**`project-review` now audits the configuration file itself.** Previously the config was only an
*input* to the review — the skill read a few keys and audited everything else against them. It is now
also a *subject*: dimension 10 checks the project against the config **and** the config against the
project.

- **New core dimension 10, `Configuration Conformance`.** *Prioritized Next Steps* moves to 11; every
  other dimension keeps its number, so existing references to "core dimension 9" stay valid. It
  covers naming adherence (`naming.files`, `folders`, `dates_in_filenames`, honouring both reserved
  lists before reporting), vocabulary drift in **both directions**, ignore reconciliation, and
  `layout`/`zones` internal consistency.
- **The enforcement gap is the headline check.** For each key the review must state what actually
  enforces it — verifier, hook, CI, or nothing — and is explicitly told **not to assume a key is
  enforced because the config declares it**, but to read the verifier's behaviour or source. A rule
  nothing checks is worse than no rule: every other dimension audits against it in good faith and
  inherits false confidence. This was not hypothetical. In XANDERIA, 8 of ~12 keys turned out to have
  no enforcement at all — the three `naming.*` values were read only to string-match them into the
  base prompt's table, `vocabulary.tags` had zero references anywhere, and `isReserved` was hardcoded
  to `index.md`/`log.md`, ignoring the configured reserved lists entirely.
- **Not a second linter.** Where the project has a verifier, the dimension says to run it, take what
  it proves, and spend the expensive judgement on what a linter cannot check.
- **Ignore reconciliation names its two asymmetric failure modes**: *ignored-but-present* (the review
  may have silently skipped something the bundle depends on — it must say what it did not read) and
  *present-but-unignored* (build output and vendored trees inflating retrieval surface and the cost
  of every future review). When `zones.ignore` links to a VCS ignore file, the review must judge
  whether that file is a *good* ignore source for a knowledge bundle — it was written to keep
  artifacts out of version control, a related but different question.
- **Fixed: Step 1 read the config from the wrong place.** It still pointed at `okf_*` frontmatter in
  `{Metadata_Dir}/index.md` — the pre-0.5.0 location — while naming the post-0.5.0 grouped keys, so
  it would have found almost nothing. It now reads
  `{Metadata_Dir}/_Configuration_/Configuration.yaml`, resolved case-insensitively and accepting
  `.yaml`/`.yml` since the project's own naming convention governs how `kb-update` created it, and
  **reports a bundle still on the legacy layout** instead of silently proceeding.
- **New `config` argument** — expands dimension 10 into the main deliverable, with a per-key table of
  declared / enforced-by / complies.
- Phase 2 now names `zones.ignore` and `zones.generated` explicitly and asks the scan to record
  discrepancies as it goes, since the substance scan is the only moment the real tree is in view.

## 0.6.0 — 2026-09-03

**Creating an external KB now asks which version to document.** Previously the version was chosen
silently — in practice, whatever the project happened to have installed — and the choice was never
put to the human.

- **`kb-update` asks two questions when adding a KB, not one.** Shape (simple/complex) was already
  asked; **version** is now asked alongside it, with one option pre-marked `(recommended)`.
- **Both candidates must be established before asking**: what the project actually uses — read from
  manifest ranges, resolved lockfiles, the installed binary, container base images and any
  `packageManager`/`engines` pin — *and* what upstream publishes now. **Disagreement among the
  in-use sources is reported rather than averaged away**, because that disagreement is usually the
  most valuable gotcha the KB will carry.
- **Default recommendation is the in-use version**; newest is recommended when the gap spans a major
  or substantial minor and the intent is to evaluate an upgrade.
- **New rule for the inverted case.** When the documented version is *newer* than the in-use one, the
  KB must carry an inline marker on every fact that does not hold on the in-use version (`[1.4]`,
  `[v3]`, …) plus a banner on its root `index.md` naming both. Unmarked content must be true for
  both. Without this the inversion is a trap: every unavailable API reads as available.
- The same question now applies to a **re-pin** during Phase 3 — silently re-pinning discards the
  record of what the last verification actually checked.
- New `### Choosing the version to document` section under *External KB metadata*, with the
  XANDERIA Bun KB (pinned to 1.4.0 while the binary is 1.3.14) as the worked example.

This is a deliberate behaviour change requested by the human, **not** a Phase 1b self-update — Phase
1b forbids redesign during spec translation, and no spec change prompted this.

## 0.5.0 — 2026-09-03

**Configuration moved out of frontmatter into a file of its own.** Breaking for existing installs;
`kb-update` migrates them automatically on the next run.

- **`{Metadata_Dir}/_Configuration_/Configuration.yaml`** replaces the `okf_*` keys that used to live
  in the bundle-root `index.md` frontmatter. Keys are grouped (`spec`, `layout`, `naming`,
  `vocabulary`, `zones`) and the redundant `okf_` prefix is gone. YAML gives the config nesting, lists
  and comments — none of which frontmatter-inside-a-reserved-file could express.
- **`okf_version` deliberately stays in `index.md`.** It is the one spec-defined key, and OKF §12 puts
  it there, which is where a spec-only consumer looks. Everything else moved. No key lives in two
  places.
- **Phase 0 gained a config migration**: a bundle still carrying `okf_*` frontmatter has those keys
  moved into the new file, `okf_version` left behind, and the migration reported.
- **Phase 0 regenerates the base prompt mechanically.** Its `## Bundle Configuration` table is
  generated and quotes every value **verbatim in a code span** — `` `title-case` ``, never a prose
  paraphrase, because a paraphrase cannot be checked and an uncheckable claim drifts. Comparison is by
  re-rendering, not by a stored checksum: a hash would be a second source of truth about the same fact.
- The review contract moved from `{Metadata_Dir}/ReviewConfiguration.md` to
  `{Metadata_Dir}/_Workflows_/Review Prompt.md`, beside the base prompt — it is a prompt users adapt,
  not configuration. New `layout.review_prompt` key.
- **Immutability gained a second sanctioned exception**: a project-wide naming migration, explicitly
  authorised by the human, may *rename* files inside an immutable zone — path only, never content. The
  cost is stated plainly in the rule, because a concept's identity is its path.
- New keys: `layout.base_prompt`, `layout.review_prompt`, `layout.skill_source`, `naming.reserved`,
  `naming.reserved_folders`, `vocabulary.tags`.

> **Upgrading:** nothing to do. Run `/xnd:kb-update` and Phase 0 performs the migration, reporting what
> it moved. Pre-1.0 semver puts a breaking change in the minor position; `MAINTAINING.md`'s table
> classifies this as major in spirit.

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
