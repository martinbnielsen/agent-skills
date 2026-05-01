# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo is the source of truth for custom agent skills deployable to both Claude Code and Codex. Skills are deployed as symlinks so edits take effect immediately without re-deploying.

## Deployment targets

| Target | Path | Format |
|--------|------|--------|
| Claude Code (CLI + VS Code extension) | `~/.claude/skills/<name>.md` | single file |
| Codex | `~/.codex/skills/<name>/SKILL.md` | file inside directory |

## Common commands

```bash
make deploy        # deploy all skills to both claude and codex
make deploy-claude # deploy to claude only
make deploy-codex  # deploy to codex only
make undeploy      # remove all managed symlinks
make status        # show deployment state per skill per target
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
skills/              ← one .md file per skill (source of truth)
Makefile             ← deploy/undeploy/status targets
~/.claude/skills/    ← symlinks: <name>.md → this repo
~/.codex/skills/     ← symlinks: <name>/SKILL.md → this repo
```

New skills: create `skills/<name>.md`, then run `make deploy`.
