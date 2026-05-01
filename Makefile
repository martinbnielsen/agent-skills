CLAUDE_SKILLS_DIR := $(HOME)/.claude/skills
CODEX_SKILLS_DIR  := $(HOME)/.codex/skills
PROJECT_DIR       := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
MODE              ?= copy    # copy or symlink

.PHONY: deploy deploy-claude deploy-codex undeploy status

deploy: deploy-claude deploy-codex

# shared logic: $(1) = target skills dir, $(2) = label
define deploy_to
	@for f in $(PROJECT_DIR)/skills/*.md; do \
		skill=$$(basename $$f .md); \
		dir=$(1)/$$skill; \
		target=$$dir/SKILL.md; \
		mkdir -p "$$dir"; \
		if [ "$(MODE)" = "symlink" ]; then \
			if [ -L "$$target" ] && [ "$$(readlink $$target)" = "$$f" ]; then \
				echo "  ok  $(2)/$$skill"; \
			else \
				ln -sf "$$f" "$$target" && echo "linked $(2)/$$skill" || echo "FAILED $(2)/$$skill"; \
			fi; \
		else \
			[ -L "$$target" ] && rm "$$target"; \
			cp "$$f" "$$target" && echo "copied $(2)/$$skill" || echo "FAILED $(2)/$$skill"; \
		fi; \
	done
endef

deploy-claude:
	$(call deploy_to,$(CLAUDE_SKILLS_DIR),claude)

deploy-codex:
	$(call deploy_to,$(CODEX_SKILLS_DIR),codex)

undeploy:
	@for f in $(PROJECT_DIR)/skills/*.md; do \
		skill=$$(basename $$f .md); \
		for dir in $(CLAUDE_SKILLS_DIR)/$$skill $(CODEX_SKILLS_DIR)/$$skill; do \
			target=$$dir/SKILL.md; \
			if [ -e "$$target" ] || [ -L "$$target" ]; then \
				rm "$$target" && echo "removed $$target"; \
				rmdir "$$dir" 2>/dev/null || true; \
			fi; \
		done; \
	done

# shared status check: $(1) = target dir, $(2) = source file
define check_status
$$(skill=$$(basename $(2) .md); \
target=$(1)/$$skill/SKILL.md; \
if [ -L "$$target" ] && [ "$$(readlink $$target)" = "$(2)" ]; then \
	echo "linked"; \
elif [ -f "$$target" ] && diff -q "$(2)" "$$target" >/dev/null 2>&1; then \
	echo "copied (in sync)"; \
elif [ -e "$$target" ]; then \
	echo "exists (out of sync)"; \
else \
	echo "not deployed"; \
fi)
endef

status:
	@printf "%-30s %-22s %-22s\n" "skill" "claude" "codex"
	@printf "%-30s %-22s %-22s\n" "-----" "------" "-----"
	@for f in $(PROJECT_DIR)/skills/*.md; do \
		skill=$$(basename $$f .md); \
		for label_dir in "claude:$(CLAUDE_SKILLS_DIR)" "codex:$(CODEX_SKILLS_DIR)"; do \
			label=$${label_dir%%:*}; \
			dir=$${label_dir#*:}; \
			target=$$dir/$$skill/SKILL.md; \
			if [ -L "$$target" ] && [ "$$(readlink $$target)" = "$$f" ]; then \
				eval "$${label}_s=linked"; \
			elif [ -f "$$target" ] && diff -q "$$f" "$$target" >/dev/null 2>&1; then \
				eval "$${label}_s='copied (in sync)'"; \
			elif [ -e "$$target" ]; then \
				eval "$${label}_s='exists (out of sync)'"; \
			else \
				eval "$${label}_s='not deployed'"; \
			fi; \
		done; \
		printf "%-30s %-22s %-22s\n" "$$skill" "$$claude_s" "$$codex_s"; \
	done
