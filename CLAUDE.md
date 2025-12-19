# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Specify template** repository - a structured workflow framework for feature specification, planning, and implementation. The project currently contains only the workflow infrastructure (no application code yet).

## Workflow Commands

The project uses slash commands in `.claude/commands/speckit.*` for the development workflow:

| Command | Purpose |
|---------|---------|
| `/speckit.specify` | Create feature specification from natural language description |
| `/speckit.clarify` | Ask clarification questions about underspecified areas in spec |
| `/speckit.plan` | Generate technical implementation plan from specification |
| `/speckit.tasks` | Generate dependency-ordered task list from plan |
| `/speckit.implement` | Execute tasks defined in tasks.md |
| `/speckit.analyze` | Cross-artifact consistency analysis |
| `/speckit.checklist` | Generate custom checklist for feature |
| `/speckit.taskstoissues` | Convert tasks to GitHub issues |
| `/speckit.constitution` | Create/update project principles |

## Workflow Sequence

```
/speckit.specify → /speckit.clarify (optional) → /speckit.plan → /speckit.tasks → /speckit.implement
```

## Directory Structure

- `.specify/templates/` - Templates for spec, plan, tasks, and checklists
- `.specify/memory/constitution.md` - Project principles and constraints (customize per project)
- `.specify/scripts/powershell/` - Helper scripts for workflow commands
- `.claude/commands/` - Slash command definitions

## Key Scripts

Run from repository root:

```powershell
# Create new feature branch and spec file
.specify/scripts/powershell/create-new-feature.ps1 -Json "feature description"

# Setup plan workflow
.specify/scripts/powershell/setup-plan.ps1 -Json

# Check prerequisites before tasks/implement
.specify/scripts/powershell/check-prerequisites.ps1 -Json

# Update agent context after planning
.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude
```

## Feature Development Pattern

Each feature creates:
- `specs/<number>-<short-name>/spec.md` - Feature specification
- `specs/<number>-<short-name>/plan.md` - Technical plan
- `specs/<number>-<short-name>/tasks.md` - Implementation tasks
- `specs/<number>-<short-name>/checklists/` - Validation checklists
- Optional: `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

## Task Format

Tasks in tasks.md follow strict format:
```
- [ ] T001 [P] [US1] Description with file path
```
- `T001` - Sequential task ID
- `[P]` - Parallelizable marker (optional)
- `[US1]` - User story reference (required for story phases)
