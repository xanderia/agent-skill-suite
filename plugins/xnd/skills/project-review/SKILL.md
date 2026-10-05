---
name: project-review
description: Deep holistic project review — reads all documentation and all source, cross-references them, and writes a dated review report covering architecture, accuracy, debt, knowledge-bundle health and prioritized next steps
user-invocable: true
---


# 🦁 Deep Review

A full, holistic review of this project. You read **everything**, cross-reference documentation
against reality, and write **one report**. You change nothing else.

This skill is **project-agnostic**. What to review, which dimensions apply, and which conventions to
audit against all come from the project's own configuration — never from assumptions baked into this
file.


## First — state your version

Open with one line naming the skill and the plugin version you are running, alongside the cost
confirmation below, so the human sees which reviewer they are about to spend on:

> 🦁 Deep Review — plugin v<version>

Resolve `plugin.json` by trying, in order, until one exists:

1. `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
2. `.claude-plugin/plugin.json` two levels up from this skill's own directory — this file lives at
   `plugins/<name>/skills/<skill>/SKILL.md`, so the manifest is `../../.claude-plugin/plugin.json`
3. `{layout.skill_source}/.claude-plugin/plugin.json`, when the project vendors the suite

If none resolves, say `plugin version unknown` and carry on. **Never hardcode the version into this
file** — `plugin.json` is the single source of truth, and a copy here would drift.

**Do not check whether a newer version exists.** This skill makes no network calls, for the same
reason it does not fetch upstream documentation: that is `/xnd:kb-update`'s job, and it does it as
part of Phase 0. Read the local version, state it, move on.


## Step 0 — Cost confirmation

**Before reading anything**, use the AskUser tool to confirm the human understands the cost:

> This review reads the entire codebase and knowledge base — it is one of the most token-expensive
> things you can run. It works best **shortly before your weekly subscription reset**, when it spends
> capacity that would otherwise expire. Proceed now, or come back later?

Offer: **Run the full review now**, **Run a narrowed review** (then ask for the focus area), and
**Not now**. If they choose "Not now", stop immediately and say when the reset makes it cheap.

Skip this confirmation only when `$ARGUMENTS` already narrows the scope to a single dimension or
area — the human has already signalled they know what they are asking for.


## Step 1 — Resolve configuration

1. Read the project's **instruction files**, `AGENTS.md` and `CLAUDE.md`, whichever exist, following
   their `@` imports. Note which ones reached your context. Judge them against
   [How agents load the instruction files](../kb-check-setup/SKILL.md#how-agents-load-the-instruction-files):
   an instruction file Claude Code does not load is a [dimension 7](#core-dimensions) finding, because
   every rule in it goes unread by Claude, silently. Which file a project uses is its own choice and
   not a finding.
   **An `@` import whose target is not in your context is the same kind of finding.** Check before
   you read the target, or the check proves nothing. The usual cause is a `_Name_` segment in the
   path, which Markdown parses as emphasis; no escape fixes it.
2. Read the bundle config — **`{Metadata_Dir}/_Configuration_/Configuration.yaml`**, the file
   `/xnd:kb-update` writes. **Resolve it tolerantly**: match the directory and filename
   case-insensitively and accept `.yaml` or `.yml`, because the project's own naming convention
   governed how `kb-update` created it. If it is absent, look for the superseded shape — `okf_*` keys
   in `{Metadata_Dir}/index.md` frontmatter — and if you find it, **report that the bundle is on a
   pre-0.5.0 config layout** and needs a `/xnd:kb-update` run to migrate. `okf_version` legitimately
   still lives in `index.md`; read it there in either case.
3. **Read the config in full, not only the keys you need to proceed.** It is both an input to this
   review and a *subject* of it: [dimension 10](#core-dimensions) audits the project against the
   config **and** the config against the project. At minimum you need `layout.*`, `zones.*`,
   `naming.*`, `vocabulary.types`, `vocabulary.tags`, `verifier` and `title`.
4. Read **`{Metadata_Dir}/_Workflows_/Review Prompt.md`** — the project's own review contract. It declares
   which dimensions apply, which to skip, which to add, and the project-specific conventions to audit
   against.
5. If `Review Prompt.md` does not exist, say so, run the [core dimensions](#core-dimensions)
   only, and offer to generate a starter file at the end.


## Restrictions

- **Think, don't write code.**
- Do not modify any source or documentation file.
- Do not offer to implement changes.
- The only file you create is the review report.
- **Diagnose, do not garden.** `/xnd:kb-update` performs fixes. Frame every knowledge-base finding as
  an input to a scoped `/xnd:kb-update` run or a plan task, and say which.


# Phase 1 — Read the documentation first

Read all authoritative documentation **before** touching source. This prevents premature opinions
formed from code alone.

Do not work from a hardcoded file list. **Walk the bundle:**

1. The instruction files from Step 1 — confirm what actually reached your context.
2. `{Metadata_Dir}/index.md` — the bundle map. Use it to find files a fixed list would miss.
3. Follow the index depth-first: root concepts, then area overviews, then everything beneath them.
4. **External KBs** — `index.md` + `gotchas.md` + `log.md` for each. Chapter files only if a concern
   arises. `log.md` is the KB's upstream-verification provenance and is the primary evidence for the
   staleness dimension; **note which KBs have no `log.md` at all.**
5. **The format contract** — enough of the OKF spec KB to judge the bundle *as a bundle*, not just as
   prose: its `gotchas.md` and its provenance/trust/lifecycle chapter.
6. `{Metadata_Dir}/log.md` — what maintenance has actually happened, versus what was merely planned.
7. Everything in `{Metadata_Dir}/_Plans_/`.
8. `Review Prompt.md`'s own reading additions, if it declares any.

**Do not start Phase 2 until you have read every file above.**


# Phase 2 — Scan the substance

Read the project's actual content — source code, manuscript, catalogue, whatever this project is.
`Review Prompt.md` declares the layers and their dependency order; follow it. Absent that,
derive an order from the dependency graph: most foundational first, most dependent last.

Exclude whatever `zones.ignore` resolves to — the project's VCS ignore file read live, or a dedicated
list — plus lockfiles and anything `zones.generated` declares.

**Keep a note of the discrepancies as you go.** What did you have to skip that the ignore source never
mentioned, and what does it exclude that turned out to matter? This scan is the only moment you see
the real tree, so it is the only moment those are cheap to notice. They are
[dimension 10](#core-dimensions) findings.

**Triage rules for large files:**

| Size | Treatment |
| :--- | :--- |
| Under 300 lines | Read completely |
| 300–1,000 lines | Read in full; note if deep analysis is deferred |
| Over 1,000 lines | Read structure, exports, representative sections |
| Pure data files | Verify they exist and are referenced; skip line-by-line |


# Phase 3 — Cross-reference

1. **Docs vs. reality.**
   - *Structural drift* — does the documented directory structure match the filesystem? List
     undocumented files and documented-but-missing ones.
   - *Conceptual drift* — do the architecture documents describe what the code **actually** does?
     Name the specific functions or modules that diverged.
   - *Plan drift* — cross-reference `_Plans_/*.md` against reality. Has planned work shipped without
     the plan being updated?
2. **Convention compliance** — spot-check the conventions `Review Prompt.md` declares. Report
   the top three most common deviations, with counts.
3. **Configuration conformance** — check the project against its own config file, and the config file
   against the project. Naming rules versus real filenames, `vocabulary` versus tags and types in
   use, `zones.ignore` versus what the tree actually holds, `layout` paths versus what exists. Feed
   [dimension 10](#core-dimensions); the method is described there.
4. **Gap identification** — what does the documentation promise that reality does not deliver? What
   exists but is undocumented?
5. **Dependency analysis** — where applicable, read manifests for outdated, duplicated or
   security-relevant packages.
6. **Bundle audit** — walk concept frontmatter for the knowledge-bundle dimensions: description
   quality, tag health, `type` correctness, link graph, trust-tier distribution, reserved-file
   conformance.
7. **Staleness audit** — for each external KB, compare its asserted versions against the versions
   actually installed or deployed.
8. Any additional audits `Review Prompt.md` declares.


# Phase 4 — Write the report

Write to `{Metadata_Dir}/_Plans_/_ReviewReports_/ReviewReport-<date>.md` using the project's
configured date format. Include OKF frontmatter with the project's report type.

**Record which reviewer produced the report.** Reports are immutable and dated, so a finding written
by v0.4.0 and one written by v0.9.0 are not comparable evidence — and nothing else in the file says
which ran. Stamp the version resolved above into the frontmatter beside `generated`:

```yaml
reviewer: xnd-plugin/0.7.0
```

Use `xnd-plugin/unknown` if the manifest did not resolve. A `diff` run should say when the two
reports it compares were produced by different versions, because a "regression" can just be a
dimension that did not exist before.

Every dimension gets **Strengths / Concerns / Recommendations**.

## Core dimensions

Always applicable, in any project:

1. **Structural Coherence** — Does the declared structure hold consistently? Boundary violations,
   circular dependencies, leaky abstractions.
2. **Documentation Accuracy** — Does the knowledge base tell the truth? Specific discrepancies.
   Things described but not built; built but not described; described but no longer existing. This is
   about *truthfulness of content* — the bundle's shape belongs to dimension 8.
3. **Quality & Conventions** — Adherence to the project's declared conventions. Clarity. Readability.
4. **Debt Inventory** — Files marked for deletion, suspended work, archive directories, legacy
   material. **Quantify it.**
5. **Cross-Cutting Concerns** — Logging, observability, health checks, backups — as declared.
6. **Author/Developer Experience** — Tooling effectiveness, workflow friction, what is manual versus
   automated, what slows the human down.
7. **Blind Spots & Unknowns** — What fits nowhere else. Risks they may not be considering.
   Assumptions that could prove wrong. **Anything that made you uneasy.**
8. **Knowledge Bundle Health** — Judge the bundle as a knowledge artifact agents retrieve from, not
   as prose. Cover: *frontmatter quality* (descriptions that discriminate versus restate the title;
   `type` values semantically right, not merely legal); *tag health* (dead tags, near-synonyms,
   over-broad tags carrying no signal, and — most valuable — the axis the vocabulary is **missing** as
   the project grows); *structure* (re-chunk and merge candidates, KBs that have earned sub-KBs);
   *link graph* (orphans, hubs, broken links in active documents); *trust and lifecycle* (the
   `unverified` fraction, plus a **targeted** list of which concepts most deserve a human `verified`
   stamp — **never propose bulk-stamping**, it flattens the gradient to noise); *reserved-file
   conformance*.

   Be concrete. "Tagging could be better" is worthless. "`AppServer/authentication.md` is 640 lines
   covering three subjects — split it, and `auth` alone no longer discriminates now that eight files
   carry it" is the deliverable.
9. **External KB Staleness** — External KBs are *frozen snapshots of other people's documentation*,
   and the one part of the bundle that rots **without anyone touching it**. Every other dimension
   degrades when the author changes something; these degrade when someone else ships a release.

   Cover *version drift* (KB-asserted versions vs. installed pins — the strongest signal, worth
   naming file by file), *verification provenance* (which KBs have no `log.md`, which admit never
   having been re-verified, how old the newest entry is), *declared horizons* (`stale_after` dates
   already passed), and *coverage* (dependencies with no KB; KBs for things no longer used).

   Also cover *project back-references*: KB text that states the project's own installed, pinned,
   bundled or deployed version ("the installed binary is …", "the repo pins …"). `kb-update` forbids
   this, because keeping such a number true costs a KB edit on every upgrade, and nothing prompts that
   edit. Name each one, file and line. The comparison *you* make between a KB's documented version and
   the project's pins is the review's job; the KB must not carry it. Dated `log.md` entries are exempt.

   **Rank by blast radius, not age.** Where the instruction file makes a KB mandatory reading,
   staleness is a live hazard because an agent is *instructed* to trust it. Staleness in a KB for
   unadopted tech is merely untidy.

   **State the confidence of each claim.** Version drift read off a lockfile is a fact; "upstream has
   probably changed since April" is an inference from a date and must be labelled as one. Offline you
   can prove *that* a KB is unverified, but rarely *that* its content is now wrong. Do not overclaim
   the difference.

   **Do not fetch upstream documentation** — that is `/xnd:kb-update`'s job. Deliver a prioritized
   re-verification queue instead, as scoped invocations in the order they should be run, one line of
   reasoning each.
10. **Configuration Conformance** — The config file is the bundle's constitution: nearly every other
    dimension audits against rules *it* declares. So audit it too, and in **both directions** — does
    reality obey the config, and does the config still describe reality?

    *Naming adherence* — walk the tree and check real filenames and directory names against
    `naming.files`, `naming.folders` and `naming.dates_in_filenames`. Honour `naming.reserved` and
    `naming.reserved_folders` before reporting anything, or the report is mostly false positives.
    **Cluster the violations and give each cluster a verdict.** One stray file is a fix; forty files
    sharing a single pattern means the convention was adopted after they were written, or that the
    rule itself is wrong — say which, because the remedies are opposite.

    *Vocabulary health* — `type` values must come from `vocabulary.types`. Tags are the harder half,
    and the interesting finding is directional: report tags **used but not declared** *and* tags
    **declared but no longer used**, which nobody checks. Separate a tag missing from the vocabulary
    because it is genuinely new from one missing because it is a near-miss of a declared tag — the
    first is vocabulary growth, the second is a silent retrieval failure. Cross-check against
    dimension 8 rather than repeating it: that one judges whether the vocabulary is *good*, this one
    whether the declared vocabulary and the used vocabulary are the *same set*.

    *Ignore reconciliation* — `zones.ignore` names either the project's VCS ignore file, linked live,
    or a dedicated list. Read whichever it resolves to and reconcile it against the real tree. The
    two failure modes are not symmetrical: **ignored-but-present** (something the ignore source
    excludes yet the bundle documents, indexes or depends on — this review may have silently skipped
    it, so say what you did not read) and **present-but-unignored** (build output, caches, vendored
    trees the config never excluded, inflating retrieval surface and the cost of every future
    review). When `zones.ignore` links to a VCS ignore file, state plainly whether that file is a
    *good* ignore source for a knowledge bundle: it was written to keep artifacts out of version
    control, which is a related but genuinely different question, and any divergence between those
    two purposes is itself the finding.

    *Enforcement gap* — **the highest-value output of this dimension.** For each key, state what
    actually enforces it: the verifier, a hook, CI, or nothing. **Do not assume a key is enforced
    because the config declares it** — check the verifier's behaviour or its source. A key nothing
    enforces is a rule that exists only in prose, and the project will drift from it silently while
    the config goes on asserting otherwise, which is worse than having no rule because it
    manufactures false confidence in every other dimension that trusts it. List these explicitly and
    recommend, per key, either a home for enforcement or deletion of the key.

    *Internal consistency* — `layout` paths that point at nothing; zone globs matching nothing;
    `zones.generated` files that have been hand-edited anyway. Treat the exemption lists as the place
    where conventions go to die quietly: every entry in `naming.reserved` and `reserved_folders`
    should still be earning its place and carrying a stated reason. An exemption whose reason no
    longer holds is a convention that was repealed without anyone deciding to repeal it.

    **Where the project has a verifier, confirm rather than re-derive.** Run it, take what it already
    proves, and spend this dimension on what it cannot check — which, in practice, is most of the
    config.
11. **Prioritized Next Steps** — Consolidated and ranked: (a) quick wins under an hour, (b) medium
    efforts around a day, (c) strategic investments of a week or more. Each references the dimension
    it addresses and is formatted as a ready plan input.

## Project dimensions

Everything `Review Prompt.md` adds — security posture, test coverage, performance, commercial
strategy, tone and style adherence, whatever this project cares about. Treat them with the same depth
as the core dimensions, and honour any dimension the configuration says to **skip**.


# Phase 5 — Summary

After writing the report, present:

1. The three most important findings.
2. The single biggest blind spot.
3. The single most impactful recommendation.
4. Which areas they want to discuss or turn into plan tasks.

Keep the tone warm and plain-spoken. **Warmth must not soften bad news** — a cheerful summary that
buries a serious finding is worse than no summary.


# Handling $ARGUMENTS

- **empty** or **`full`** — every applicable dimension at equal depth.
- **area keyword** — full review, double depth on that area.
- **dimension keyword** — read everything, expand that dimension substantially.
- **`okf`** — walk *every* concept's frontmatter rather than sampling, and produce a per-file table
  of proposed tag/type/structure changes ready to hand to `/xnd:kb-update`.
- **`config`** — expand dimension 10 into the main deliverable. Check **every** file and directory
  name against the naming rules rather than sampling, enumerate the full used-vs-declared tag and
  type sets in both directions, reconcile the ignore source line by line, and produce a per-key table
  of the config: what it declares, what enforces it, and whether reality complies.
- **`staleness`** — read every chapter of every external KB rather than just the entry points,
  cross-check each version claim against the installed pin, and give a per-chapter safe/stale
  verdict. Still offline; still no upstream fetching.
- **`diff`** — find the most recent previous report in `_ReviewReports_` and focus on what changed:
  what improved, what regressed, what is new.
- **anything else** — free-form focus. Read everything; weight the analysis accordingly.

$ARGUMENTS
