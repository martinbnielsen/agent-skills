---
name: oracle-forms
description: Parse Oracle Forms XML exports (.fmb exported to .xml) and migrate them to Oracle APEX APEXlang (.apx) applications. Use when the user references a .fmb, .xml Oracle Forms file, asks to migrate/convert/modernize a Forms application, or needs to understand Oracle Forms XML structure in order to generate APEX pages.
version: 1.0.0
---

# Oracle Forms Migration Skill

This skill equips Claude to read Oracle Forms XML exports, understand their structure, and generate equivalent Oracle APEX APEXlang (`.apx`) artifacts.

## How to Use This Skill

1. Read `references/xml-structure.md` to understand the Oracle Forms XML schema.
2. Read `references/forms-to-apex-mapping.md` to understand how Forms concepts map to APEX/APEXlang constructs.
3. Follow `references/migration-workflow.md` for the step-by-step process of producing `.apx` output.
4. Use the `apex` skill (APEXlang generation) to produce and validate the final `.apx` files.

## Directory Structure

```
oracle-forms/
├── SKILL.md                          ← this file (entry point)
└── references/
    ├── xml-structure.md              ← Oracle Forms XML element reference
    ├── forms-to-apex-mapping.md      ← Forms → APEX concept mapping tables
    └── migration-workflow.md         ← End-to-end migration workflow
```

## Category Routing

| Task                                                | Reference                                 |
|-----------------------------------------------------|-------------------------------------------|
| Understand what an XML element means                | `references/xml-structure.md`             |
| Map a Forms concept to an APEX equivalent           | `references/forms-to-apex-mapping.md`     |
| Run a full Forms → APEX migration                   | `references/migration-workflow.md`        |
| Generate valid APEXlang after mapping is complete   | Use the `apex` skill                      |

## Trigger Phrases

Load this skill when the user:
- Opens or references a file with `.fmb`, `_fmb.xml`, or `xmlns="http://xmlns.oracle.com/Forms"` content
- Asks to "migrate", "convert", or "modernize" an Oracle Forms application
- Asks what a `<Block>`, `<Item>`, `<Trigger>`, or `<Relation>` element means in a Forms XML
- Asks to "generate an APEX app from a Forms module"
- Asks to "parse" or "analyze" an Oracle Forms XML export
