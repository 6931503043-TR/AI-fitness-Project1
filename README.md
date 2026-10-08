# AI Fitness Coach — Agent Rules

Initial agent/quality setup:

- `AGENTS.md` — shared engineering rules for coding agents
- `CLAUDE.md` — Claude-specific workflow pointer and verification behavior
- `eslint.config.js` — JavaScript/TypeScript lint rules
- `.github/workflows/ci.yml` — GitHub Actions quality gate

## Important

The main prototype may use Flutter/Dart. ESLint does **not** lint Dart code.

For Flutter code, keep using:

    flutter analyze
    flutter test

This ESLint setup is intended for JavaScript/TypeScript parts of the project, such as a web UI, backend, tooling, or AI service.

## Recommended package scripts

    "scripts": {
      "lint": "eslint .",
      "typecheck": "tsc --noEmit",
      "test": "vitest run"
    }

If the project uses a different test runner, replace the `test` script accordingly.
