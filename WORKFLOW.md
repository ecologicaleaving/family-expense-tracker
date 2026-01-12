# Finn - Development Workflow Quick Reference

This project uses a dual-repository workflow with build flavors for parallel development and production.

## Quick Start

```bash
# Daily development
flutter run --flavor dev -d <device-id>

# Commit and push to test
git add . && git commit -m "message"
git push origin test

# Create production release
# See full workflow in .claude/commands/dev-workflow.md
```

## Repository Setup

- **Development (origin)**: ecologicaleaving/finn → `test` branch
- **Production (production)**: 80-20Solutions/finn → `master` branch

## Build Flavors

Two apps can coexist on the same device:
- **Fin** (production): `com.ecologicaleaving.fin` - Stable version for users
- **Fin Dev** (development): `com.ecologicaleaving.fin.dev` - Testing version

```bash
# Install dev version (daily testing)
flutter run --flavor dev -d <device-id>

# Install production version (stable)
flutter run --flavor production -d <device-id>
```

## Branching Strategy

```
origin (ecologicaleaving/finn)
├── test (main development)
├── feature/* (feature branches)
└── hotfix/* (hotfix branches)

production (80-20Solutions/finn)
└── master (stable releases only)
```

## Custom Skill

For detailed workflow instructions, use the custom skill:

```
/dev-workflow
```

Or refer to: `.claude/commands/dev-workflow.md`

This skill provides step-by-step guidance for:
- Daily development commits
- Creating production releases
- Semantic versioning
- Hotfix workflow
- Troubleshooting

## Important Rules

⚠️ **ALWAYS use `--flavor dev` for development**
⚠️ **NEVER push directly to production/master**
⚠️ **Test thoroughly on test branch before production release**

---

**Brand**: Finn - AI-powered family budget assistant
**Version**: See `pubspec.yaml`
