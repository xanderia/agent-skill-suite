---
name: kb-version
description: Show which version of the xnd plugin this session runs and where it is loaded from, plus the OKF spec version of the knowledge base when its rules are in context. Instant, read-only, no tool calls.
user-invocable: true
allowed-tools: Bash(sh ${CLAUDE_SKILL_DIR}/version.sh)
disallowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - NotebookEdit
  - WebFetch
  - WebSearch
  - Agent
  - Skill
---


# 🦁 Knowledge Base Version

The plugin's manifest, read by a script shipped with this skill before you saw this text:

!`sh ${CLAUDE_SKILL_DIR}/version.sh`

**Answer from what is in front of you. Call no tool;** this skill has none. Reply with:

> 🦁 xnd plugin v`<version>` — `<plugin root>`

Then add **one** of these lines:

- **If your context holds the knowledge base's `## Bundle Configuration` table**, which the base
  prompt brings in when the knowledge base is installed and loading:

  > Knowledge base: OKF `<spec version>` · spec commit `<spec.sha>`

  Quote both values exactly as that table shows them.
- **If it does not:**

  > No knowledge-base rules in this session — not installed here, or not loading.
  > `/xnd:kb-check-setup` tells which.

Nothing else. Two things are deliberately out of scope:

- **This skill makes no network call.** `/xnd:kb-update` compares the installed version with the
  published one.
- **A plugin root inside the project is a linked development checkout.** One under
  `~/.claude/plugins/` is a marketplace install. Say which, in a few words, only when the human asks.
