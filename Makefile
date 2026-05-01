CLAUDE_SKILLS_DIR := $(HOME)/.claude/skills
CODEX_SKILLS_DIR  := $(HOME)/.codex/skills
PROJECT_DIR       := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: deploy deploy-claude deploy-codex undeploy status

deploy: deploy-claude deploy-codex

deploy-claude:
	@mkdir -p $(CLAUDE_SKILLS_DIR)
	@for f in $(PROJECT_DIR)/skills/*.md; do \
		name=$$(basename $$f); \
		target=$(CLAUDE_SKILLS_DIR)/$$name; \
		if [ -L "$$target" ] && [ "$$(readlink $$target)" = "$$f" ]; then \
			echo "  ok  claude/$$name"; \
		else \
			ln -sf "$$f" "$$target" && echo "linked claude/$$name" || echo "FAILED claude/$$name"; \
		fi; \
	done

deploy-codex:
	@for f in $(PROJECT_DIR)/skills/*.md; do \
		skill=$$(basename $$f .md); \
		dir=$(CODEX_SKILLS_DIR)/$$skill; \
		target=$$dir/SKILL.md; \
		mkdir -p "$$dir"; \
		if [ -L "$$target" ] && [ "$$(readlink $$target)" = "$$f" ]; then \
			echo "  ok  codex/$$skill"; \
		else \
			ln -sf "$$f" "$$target" && echo "linked codex/$$skill" || echo "FAILED codex/$$skill"; \
		fi; \
	done

undeploy:
	@for f in $(PROJECT_DIR)/skills/*.md; do \
		name=$$(basename $$f); \
		skill=$$(basename $$f .md); \
		claude_target=$(CLAUDE_SKILLS_DIR)/$$name; \
		if [ -L "$$claude_target" ] && [ "$$(readlink $$claude_target)" = "$$f" ]; then \
			rm "$$claude_target" && echo "removed claude/$$name"; \
		fi; \
		codex_target=$(CODEX_SKILLS_DIR)/$$skill/SKILL.md; \
		if [ -L "$$codex_target" ] && [ "$$(readlink $$codex_target)" = "$$f" ]; then \
			rm "$$codex_target" && echo "removed codex/$$skill/SKILL.md"; \
			rmdir "$(CODEX_SKILLS_DIR)/$$skill" 2>/dev/null || true; \
		fi; \
	done

status:
	@printf "%-30s %-20s %-20s\n" "skill" "claude" "codex"
	@printf "%-30s %-20s %-20s\n" "-----" "------" "-----"
	@for f in $(PROJECT_DIR)/skills/*.md; do \
		name=$$(basename $$f); \
		skill=$$(basename $$f .md); \
		claude_target=$(CLAUDE_SKILLS_DIR)/$$name; \
		if [ -L "$$claude_target" ] && [ "$$(readlink $$claude_target)" = "$$f" ]; then \
			cs="linked"; \
		elif [ -e "$$claude_target" ]; then \
			cs="exists,not linked"; \
		else \
			cs="not deployed"; \
		fi; \
		codex_target=$(CODEX_SKILLS_DIR)/$$skill/SKILL.md; \
		if [ -L "$$codex_target" ] && [ "$$(readlink $$codex_target)" = "$$f" ]; then \
			xs="linked"; \
		elif [ -e "$$codex_target" ]; then \
			xs="exists,not linked"; \
		else \
			xs="not deployed"; \
		fi; \
		printf "%-30s %-20s %-20s\n" "$$skill" "$$cs" "$$xs"; \
	done
