# Update Migration

What an **existing installation** needs after the plugin moves on. [CHANGELOG.md](../../CHANGELOG.md)
records what changed in the plugin; this file records what to **check and fix in your project**, so
your setup and your knowledge base end up where a fresh install would put them.

It is written for your agent as much as for you. It ships inside the plugin, so every installed copy
carries the entries that match its own version.


## How to use it

1. **Update the plugin**, then start a fresh session.
2. **Run `/xnd:kb-check-setup`.** It is read-only, and cites the IDs below for anything it finds.
3. **Run `/xnd:kb-update`.** Its Phase 0 walks this file and applies every entry whose *Fix by* names
   it. It reports the rest under *What needs you*.
4. **Handle the entries marked *you*.** They need a decision, or they touch something the skills may
   not edit, such as your verifier's source code.

**You never need to know which version you came from.** Every *Detect* is safe to run on any
installation, and every *Fix* is a no-op when *Detect* finds nothing. Running the whole file again is
harmless.


## Severity

| | Meaning |
| :--- | :--- |
| 🔴 | **Broken.** Rules are not reaching the agent, or a skill would act on a wrong reading. Fix first |
| 🟠 | **Drift.** Something reads as true and no longer is, or will mislead a later run |
| 🟢 | **Improvement.** The installation works; this brings it up to the current shape |


## At a glance

| ID | | What | Fix by |
| :--- | :--- | :--- | :--- |
| [0.9.0-A](#090-a--the-base-prompt-never-loads) | 🔴 | The base prompt never loads | `kb-update`, automatic |
| [0.9.0-B](#090-b--claude-code-does-not-load-the-anchor-file) | 🔴 | Claude Code does not load the anchor file | you |
| [0.9.0-C](#090-c--a-second-install-over-a-working-one) | 🔴 | A second install over a working one | you |
| [0.9.0-D](#090-d--the-anchor-has-no-link) | 🟢 | The anchor has no link | `kb-update`, automatic |
| [0.9.0-E](#090-e--leftover-import-path-exemptions) | 🟢 | Leftover import-path exemptions | `kb-update`, from this file |
| [0.9.0-F](#090-f--external-kbs-name-the-projects-own-versions) | 🟠 | External KBs name the project's own versions | `kb-update`, per KB |
| [0.6.0-A](#060-a--a-kb-documents-a-newer-version-than-you-run) | 🟠 | A KB documents a newer version than you run | `kb-update`, per KB |
| [0.5.0-A](#050-a--configuration-still-in-indexmd-frontmatter) | 🟠 | Configuration still in `index.md` frontmatter | `kb-update`, automatic |
| [0.5.0-B](#050-b--review-contract-at-the-old-path) | 🟠 | Review contract at the old path | `kb-update`, from this file |
| [0.4.0-A](#040-a--external-kbs-without-upstream-metadata) | 🟢 | External KBs without `upstream:` metadata | `kb-update`, per KB |
| [0.4.0-B](#040-b--hand-written-external-kb-registry) | 🟠 | Hand-written external-KB registry | `kb-update`, automatic |
| [0.3.0-A](#030-a--inline-install-shape) | 🟢 | Inline install shape | `kb-update`, automatic |
| [0.2.0-A](#020-a--archived-files-stranded-on-an-old-spec) | 🟠 | Archived files stranded on an old spec | `kb-update`, Phase 1 |
| [0.2.0-B](#020-b--the-verifier-nags-about-archives) | 🟠 | The verifier nags about archives | you |
| [0.2.0-C](#020-c--lifecycle-in-tags) | 🟢 | Lifecycle expressed as tags | `kb-update`, automatic |

*Fix by* means:

- **`kb-update`, automatic** — a named step does it on every maintain run.
- **`kb-update`, from this file** — Phase 0 applies the fix written here.
- **`kb-update`, per KB** — it happens as each external KB is verified (`/xnd:kb-update external`, or
  `/xnd:kb-update <kb-name>` for one).
- **you** — needs your decision.

Paths below use `{Metadata_Dir}` for `layout.metadata_dir`, read from `Configuration.yaml`.


---

## 0.9.0

### 0.9.0-A · The base prompt never loads

🔴 Affects every anchored install made with the defaults of 0.3.0 to 0.8.0.

- **Detect.** The anchor's `@` import path contains a segment wrapped in `_` or `*`, such as
  `@Notes/_Workflows_/knowledge-base/base-prompt.md`. Markdown reads `_Workflows_` as emphasis, so
  the path splits and nothing is imported, silently. Escaping the underscores does not help.
  `/xnd:kb-check-setup` shows Checks 3 and 5 as ❌.
- **Fix.** `kb-update`, automatic: *Phase 0 → Migrate an unloadable base prompt*. It moves the base
  prompt and its `index.md` to `{Metadata_Dir}/Knowledge Base/` (cased per `naming.folders`), and
  rewrites `layout.base_prompt`, the anchor's link and import, and every index that listed the old
  path.
- **Verify.** In a fresh session, `/xnd:kb-check-setup` Check 3 is ✅.

### 0.9.0-B · Claude Code does not load the anchor file

🔴 This happens when the anchor sits in an `AGENTS.md` that a `CLAUDE.md`, `.claude/CLAUDE.md` or
`CLAUDE.local.md` hides, because that file neither imports `AGENTS.md` nor is a symlink to it.

- **Detect.** `/xnd:kb-check-setup` Check 2 is ❌. The table it uses is in
  [How agents load the instruction files](skills/kb-check-setup/SKILL.md#how-agents-load-the-instruction-files).
- **Fix.** You decide; the plugin takes no side. The options:
  - add `@AGENTS.md` to `CLAUDE.md`;
  - move the anchor into the file that is loaded;
  - make `CLAUDE.md` a symlink to `AGENTS.md`;
  - set *Project instructions* to load both, which is per-user.

  `/xnd:kb-check-setup` gives the trade-off of each.
- **Verify.** In a fresh session, Checks 2 and 3 are ✅.

### 0.9.0-C · A second install over a working one

🔴 Before 0.9.0, `kb-update` looked for the marker in `CLAUDE.md` first. If `CLAUDE.md` existed but
the anchor was in `AGENTS.md`, a run could miss it and install a second time.

- **Detect.** Any of these:
  - both instruction files carry `<!-- okf:installed -->` (`/xnd:kb-check-setup` Check 1 ❌);
  - a second `Configuration.yaml`;
  - a second base prompt.
- **Fix.** You decide which installation to keep. Delete the duplicate's anchor, config and base
  prompt by hand. The skills never delete. Compare the two configs first, since the second install
  asked its questions afresh.
- **Verify.** Check 1 is ✅, with exactly one marker.

### 0.9.0-D · The anchor has no link

🟢 Most non-Claude agents that read `AGENTS.md` do not expand `@` imports. Without a markdown link,
they never find the base prompt.

- **Detect.** The anchor section has an `@` import but no markdown link to the same file.
- **Fix.** `kb-update`, automatic: *Phase 0 → Repair the anchor*. It writes spaces as `%20` in the link
  and as `\ ` in the import.
- **Verify.** `/xnd:kb-check-setup` Check 5 shows no ⚠️ for the link.

### 0.9.0-E · Leftover import-path exemptions

🟢 Older installs reserved kebab-case names for the base prompt because an `@` import was believed
unable to take a space. It can, with a backslash, so the exemptions protect nothing.

- **Detect.** `naming.reserved` lists `base-prompt.md`, or `naming.reserved_folders` lists
  `_Workflows_/knowledge-base`, while `layout.base_prompt` no longer uses that path.
- **Fix.** `kb-update`, from this file: remove the stale entries, and add a line to `log.md`. If the
  base prompt still carries a kebab-case name in a project whose convention differs, **only propose**
  renaming it to the convention. A rename changes the file's identity, so that is your call.
- **Verify.** Neither entry remains; `/xnd:kb-check-setup` stays ✅.

### 0.9.0-F · External KBs name the project's own versions

🟠 0.6.0 told `kb-update` to record disagreement between the project's version sources (binary, pin,
container tag) inside a KB. 0.9.0 reverses that. An external KB describes upstream only, because a
recorded in-use version goes stale on every upgrade and nothing prompts the edit.

- **Detect.** An external KB states what *this project* installs, pins, bundles or deploys. Examples:
  "the installed binary is …", "the repo pins …", "the Dockerfile resolves to …", or a table of the
  project's version sources. `/xnd:project-review` dimension 9 names each one by file and line.
- **Fix.** `kb-update`, per KB: Phase 3 removes these back-references as it verifies each KB. There
  is no bulk migration, deliberately; each removal is checked against the KB's content.
- **Still allowed:** the documented upstream version, upstream markers such as `[1.4]`, and dated
  `log.md` entries.
- **Verify.** The next `/xnd:project-review` finds none.


## 0.8.0

Nothing to migrate. Review reports written before 0.8.0 carry no `reviewer:` stamp, and they stay that
way because they are immutable. When `/xnd:project-review diff` compares an unstamped report with a
stamped one, a difference may come from the reviewer version rather than from the project.


## 0.7.0

Nothing to migrate. `/xnd:project-review` gained dimension 10 (*Configuration Conformance*), so expect
new findings about your config on the next review. They are about the config, not regressions.


## 0.6.0

### 0.6.0-A · A KB documents a newer version than you run

🟠 Without markers, a reader cannot tell which documented APIs their installed version lacks.

- **Detect.** An external KB's `gotchas.md` `upstream.version` is newer than the version the project
  uses.
- **Fix.** `kb-update`, per KB. Every fact upstream added after the in-use version gets an inline
  marker (`[1.4]`), and the root `index.md` gets a banner naming the **documented** version. Under
  0.9.0-F, the banner does not name the in-use version.
- **Verify.** Unmarked content holds on the older version too.


## 0.5.0

### 0.5.0-A · Configuration still in `index.md` frontmatter

🟠 Every skill since 0.7.0/0.8.0 reads `Configuration.yaml`. A bundle still on the old layout is
reported, but none of its keys are found.

- **Detect.** `{Metadata_Dir}/index.md` frontmatter carries `okf_*` keys other than `okf_version`.
- **Fix.** `kb-update`, automatic: *Phase 0 → Migrate frontmatter config → `Configuration.yaml`*.
  `okf_version` stays in `index.md`, where OKF §12 puts it.
- **Verify.** `/xnd:kb-check-setup` Check 4 is ✅.

### 0.5.0-B · Review contract at the old path

🟠 0.5.0 moved the review contract, but no step ever migrated it. `/xnd:project-review` then runs with
the core dimensions only and silently ignores your project's dimensions.

- **Detect.** `{Metadata_Dir}/ReviewConfiguration.md` exists, and `layout.review_prompt` is absent or
  points at nothing.
- **Fix.** `kb-update`, from this file:
  1. `git mv` the file to `{Metadata_Dir}/_Workflows_/Review Prompt.md`, named per `naming.files`.
  2. Set `layout.review_prompt` to the new path.
  3. Repoint inbound links from active documents. Links from archives stay frozen.
  4. Index both ends and log the move.
- **Verify.** `/xnd:kb-check-setup` Check 4 finds `layout.review_prompt`.


## 0.4.0

### 0.4.0-A · External KBs without `upstream:` metadata

🟢 The external-KB registry and the staleness checks read the pinned version from each KB's
`gotchas.md` frontmatter.

- **Detect.** An external KB's `gotchas.md` has no `upstream: {product, version, kind}`. The registry
  in `{Metadata_Dir}/_External_/index.md` shows it without a version.
- **Fix.** `kb-update`, per KB: Phase 3 stamps it as it verifies the KB.
- **Verify.** The KB's row in the generated registry shows a version.

### 0.4.0-B · Hand-written external-KB registry

🟠 A hand-maintained registry drifts silently. XANDERIA's described a spec version five weeks out of
date.

- **Detect.** `{Metadata_Dir}/_External_/index.md` lacks the "this table is generated" banner.
- **Fix.** `kb-update`, automatic: Phase 6 regenerates it from each KB's frontmatter.
- **Verify.** The banner is present, and each row matches its KB's `gotchas.md`.


## 0.3.0

### 0.3.0-A · Inline install shape

🟢 The whole instruction text sits pasted into the instruction file instead of in an imported base
prompt.

- **Detect.** The section carrying `<!-- okf:installed -->` has no `@` import line and holds the full
  rules.
- **Fix.** `kb-update`, automatic: *Phase 0 → Migrate inline → anchored*. It moves the text into
  `layout.base_prompt` and rebases its links. 0.9.0-A's path rule applies to the new location.
- **Verify.** `/xnd:kb-check-setup` Checks 3 and 5 are ✅.


## 0.2.0

### 0.2.0-A · Archived files stranded on an old spec

🟠 These are files frozen in an immutable zone before a spec migration could reach them.

- **Detect.** Files under `zones.immutable` have frontmatter that no longer parses under the current
  OKF spec, such as bare dates where the spec requires datetimes with an offset.
- **Fix.** `kb-update`, Phase 1, under its narrow spec-migration exception: frontmatter only, never
  body or links, always reported.
- **Verify.** The verifier shows no hard-rule errors inside immutable zones.

### 0.2.0-B · The verifier nags about archives

🟠 A verifier that reports findings nobody may fix teaches its reader to skip the real ones.

- **Detect.** Your verifier prints house-rule warnings (broken links, `stale_after`) for files in
  `zones.immutable`, or checks `stale_after` on `status: deprecated` documents.
- **Fix.** You. The verifier is your code; the skills only report it. The required behaviour is in
  `kb-update`'s *Verifier contract*: suppress and count those findings, and offer `--strict`.
- **Verify.** The verifier prints a suppressed count, and `--strict` shows the suppressed findings.

### 0.2.0-C · Lifecycle in tags

🟢 A `deprecated` or `obsolete` tag duplicates `status` and drifts against it.

- **Detect.** An active document carries a lifecycle tag (`deprecated`, `obsolete`, `draft`).
- **Fix.** `kb-update`, automatic: Phase 5 expresses lifecycle through `status` and drops the tag.
  Archived documents keep their tags, because immutability wins.
- **Verify.** No active document carries a lifecycle tag.


---

## Writing an entry

For maintainers: [MAINTAINING.md](../../MAINTAINING.md) requires an entry for every release that
changes what an existing installation should contain.

- Use an ID of `<version>-<letter>`, and never renumber. Reports and runs cite these IDs.
- Write a *Detect* that is safe and conclusive on **any** installation, whichever version it came
  from.
- Write a *Fix* that is a no-op when *Detect* finds nothing.
- Give a *Verify* that a fresh session can run, preferably `/xnd:kb-check-setup`.
- Name the *Fix by* honestly. Anything a skill may not do under its hard rules is **you**.
