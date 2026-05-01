# agent-skills

A version-controlled collection of custom agent skills for [Claude Code](https://claude.ai/code) and [Codex](https://github.com/openai/codex). Skills are deployed as symlinks so edits take effect immediately without re-deploying.

## Deployment targets

| Agent | Skills directory | Format |
|-------|-----------------|--------|
| Claude Code (CLI + VS Code) | `~/.claude/skills/<name>.md` | single file |
| Codex CLI | `~/.codex/skills/<name>/SKILL.md` | file inside directory |

## Setup

Clone the repo and deploy:

```bash
git clone https://github.com/martinbnielsen/agent-skills.git
cd agent-skills
make deploy
```

## Commands

```bash
make deploy        # deploy all skills to both claude and codex
make deploy-claude # deploy to claude only
make deploy-codex  # deploy to codex only
make undeploy      # remove all managed symlinks
make status        # show deployment state for each skill
```

`make status` output:

```
skill                          claude               codex
-----                          ------               -----
web-inspector                  linked               linked
```

## Adding a skill

1. Create `skills/<name>.md` with this frontmatter:

```markdown
---
name: skill-name
description: One sentence describing when the agent should invoke this skill.
version: 1.0.0
---

# Skill Title

Instruction content...
```

2. Run `make deploy` to symlink the new skill into both targets.

The `name` field should match the filename stem (e.g. `skills/my-skill.md` → `name: my-skill`). The `description` is used by both Claude and Codex to decide when to activate the skill, so be precise about trigger phrases.

## Skills

| Skill | Description |
|-------|-------------|
| [oracle-plsql](skills/oracle-plsql.md) | Oracle PL/SQL development — Logger framework, Trivadis guidelines, Feuerstein best practices |
| [web-inspector](skills/web-inspector.md) | Inspect and interact with live websites using Chrome DevTools MCP |
