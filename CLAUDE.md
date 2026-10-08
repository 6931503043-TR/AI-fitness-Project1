# CLAUDE.md

> Shared project rules live in `AGENTS.md`.
> Read and follow `AGENTS.md` before making changes.

## Working Style

- Inspect the existing code before changing it.
- Prefer the smallest correct change.
- Reuse existing patterns before introducing new abstractions.
- Do not invent APIs or library behavior.
- Do not modify unrelated files.
- Keep explanations concise and evidence-based.

## Before Coding

1. Read `AGENTS.md`.
2. Inspect the relevant directory and nearby code.
3. Identify existing tests and scripts.
4. State assumptions internally; if an assumption materially changes the design, ask before proceeding.

## During Coding

- Keep UI, business logic, AI integration, database, and body-tracking responsibilities separated.
- Keep LLM providers behind an application-level abstraction.
- Never bypass the trainer approval boundary.
- Never put SQLite access directly in UI code.
- Validate AI output at the application boundary.
- Avoid unnecessary dependencies.

## Verification

Before saying a task is complete, run the relevant project checks.

For JS/TS:

    npm run lint
    npm test

If available:

    npm run typecheck

If a command cannot be run, report the reason instead of claiming it passed.

## Completion Report

When finished, report:

1. What changed
2. Files changed
3. Verification performed
4. Any remaining limitation or follow-up

Do not claim tests passed unless they were actually run.
