# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo is the source of truth for custom agent skills deployable to both Claude Code and Codex. Default deployment mode is `copy`; use `MODE=symlink` if you want edits to take effect without re-deploying.

## Deployment targets

| Target | Path |
|--------|------|
| Claude Code (CLI + VS Code extension) | `~/.claude/skills/<name>/SKILL.md` |
| Codex | `~/.codex/skills/<name>/SKILL.md` |

Both targets use the same directory-per-skill format.

## Common commands

```bash
make deploy               # copy all skills to both claude and codex (default: copy)
make deploy MODE=symlink  # deploy as symlinks instead (edits are live immediately)
make deploy-claude        # deploy to claude only
make deploy-codex         # deploy to codex only
make undeploy             # remove all deployed files/symlinks
make status               # show deployment state per skill per target
```

## Skill file format

Each file in `skills/` is a markdown file with YAML frontmatter (compatible with both Claude Code and Codex):

```markdown
---
name: skill-name
description: One sentence describing when the agent should invoke this skill.
version: 1.0.0
---

# Skill Title

Instruction content...
```

- `name`: kebab-case identifier matching the filename stem
- `description`: used by both Claude and Codex to decide when to activate the skill — be precise about trigger phrases

## Architecture

```
skills/              ← one directory per skill (source of truth)
  <name>/
    SKILL.md
Makefile             ← deploy/undeploy/status targets
~/.claude/skills/    ← <name>/SKILL.md (copied or symlinked)
~/.codex/skills/     ← <name>/SKILL.md (copied or symlinked)
```

New skills: create `skills/<name>/SKILL.md`, then run `make deploy`.
