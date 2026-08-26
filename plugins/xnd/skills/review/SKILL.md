---
name: review
description: Deep holistic project review — reads all documentation and all source, cross-references them, and writes a dated review report covering architecture, accuracy, debt, knowledge-bundle health and prioritized next steps
user-invocable: true
---


# 🦁 Deep Review

A full, holistic review of this project. You read **everything**, cross-reference documentation
against reality, and write **one report**. You change nothing else.

This skill is **project-agnostic**. What to review, which dimensions apply, and which conventions to
audit against all come from the project's own configuration — never from assumptions baked into this
file.


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

1. Read `CLAUDE.md` (or `AGENTS.md`) and the config frontmatter in `{Metadata_Dir}/index.md` — the
   same keys `/xnd:kb-update` writes. You need `okf_root`, `okf_metadata_dir`, `okf_immutable`,
   `okf_types`, `okf_tags`, the date format, and `kb_title`.
2. Read **`{Metadata_Dir}/ReviewConfiguration.md`** — the project's own review contract. It declares
   which dimensions apply, which to skip, which to add, and the project-specific conventions to audit
   against.
3. If `ReviewConfiguration.md` does not exist, say so, run the [core dimensions](#core-dimensions)
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

1. `CLAUDE.md` — confirm it is in context.
2. `{Metadata_Dir}/index.md` — the bundle map. Use it to find files a fixed list would miss.
3. Follow the index depth-first: root concepts, then area overviews, then everything beneath them.
4. **External KBs** — `index.md` + `gotchas.md` + `log.md` for each. Chapter files only if a concern
   arises. `log.md` is the KB's upstream-verification provenance and is the primary evidence for the
   staleness dimension; **note which KBs have no `log.md` at all.**
5. **The format contract** — enough of the OKF spec KB to judge the bundle *as a bundle*, not just as
   prose: its `gotchas.md` and its provenance/trust/lifecycle chapter.
6. `{Metadata_Dir}/log.md` — what maintenance has actually happened, versus what was merely planned.
7. Everything in `{Metadata_Dir}/_Plans_/`.
8. `ReviewConfiguration.md`'s own reading additions, if it declares any.

**Do not start Phase 2 until you have read every file above.**


# Phase 2 — Scan the substance

Read the project's actual content — source code, manuscript, catalogue, whatever this project is.
`ReviewConfiguration.md` declares the layers and their dependency order; follow it. Absent that,
derive an order from the dependency graph: most foundational first, most dependent last.

Exclude what the ignore configuration excludes, plus lockfiles and generated output.

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
2. **Convention compliance** — spot-check the conventions `ReviewConfiguration.md` declares. Report
   the top three most common deviations, with counts.
3. **Gap identification** — what does the documentation promise that reality does not deliver? What
   exists but is undocumented?
4. **Dependency analysis** — where applicable, read manifests for outdated, duplicated or
   security-relevant packages.
5. **Bundle audit** — walk concept frontmatter for the knowledge-bundle dimensions: description
   quality, tag health, `type` correctness, link graph, trust-tier distribution, reserved-file
   conformance.
6. **Staleness audit** — for each external KB, compare its asserted versions against the versions
   actually installed or deployed.
7. Any additional audits `ReviewConfiguration.md` declares.


# Phase 4 — Write the report

Write to `{Metadata_Dir}/_Plans_/_ReviewReports_/ReviewReport-<date>.md` using the project's
configured date format. Include OKF frontmatter with the project's report type.

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

   **Rank by blast radius, not age.** Where `CLAUDE.md` makes a KB mandatory reading, staleness is a
   live hazard because an agent is *instructed* to trust it. Staleness in a KB for unadopted tech is
   merely untidy.

   **State the confidence of each claim.** Version drift read off a lockfile is a fact; "upstream has
   probably changed since April" is an inference from a date and must be labelled as one. Offline you
   can prove *that* a KB is unverified, but rarely *that* its content is now wrong. Do not overclaim
   the difference.

   **Do not fetch upstream documentation** — that is `/xnd:kb-update`'s job. Deliver a prioritized
   re-verification queue instead, as scoped invocations in the order they should be run, one line of
   reasoning each.
10. **Prioritized Next Steps** — Consolidated and ranked: (a) quick wins under an hour, (b) medium
    efforts around a day, (c) strategic investments of a week or more. Each references the dimension
    it addresses and is formatted as a ready plan input.

## Project dimensions

Everything `ReviewConfiguration.md` adds — security posture, test coverage, performance, commercial
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
- **`staleness`** — read every chapter of every external KB rather than just the entry points,
  cross-check each version claim against the installed pin, and give a per-chapter safe/stale
  verdict. Still offline; still no upstream fetching.
- **`diff`** — find the most recent previous report in `_ReviewReports_` and focus on what changed:
  what improved, what regressed, what is new.
- **anything else** — free-form focus. Read everything; weight the analysis accordingly.

$ARGUMENTS
