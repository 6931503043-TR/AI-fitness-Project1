# AGENTS.md

## Project

AI Fitness Coach — prototype for an AI-assisted fitness coaching application.

The system is intended to:
1. collect user workout/profile data,
2. generate a proposed workout plan with AI,
3. allow a human trainer to review/approve the plan,
4. optionally use camera-based body/pose tracking to provide movement feedback.

This is a prototype. Prefer simple, understandable solutions over premature production complexity.

## Source of Truth

This file contains the shared rules for coding agents.

Claude, Codex, Cursor, Copilot, and other agents should follow this file unless a more specific rule in a nested directory explicitly overrides it.

`CLAUDE.md` should not duplicate or contradict these rules.

## Core Engineering Rules

### 1. Keep responsibilities separated

Use clear boundaries between:

- UI / presentation
- application/business logic
- AI integration
- database/storage
- body/pose tracking
- external services

UI code should not contain database queries or AI provider-specific logic.

### 2. Keep the AI provider replaceable

Do not couple business logic directly to one LLM provider.

Prefer:

    AI Coach Service
          |
          +-- OpenAI adapter
          +-- Gemini adapter
          +-- Local LLM adapter

The application should depend on an internal interface/service, not directly on provider SDKs throughout the codebase.

### 3. Trainer approval is a safety boundary

The AI may propose a workout plan.

The AI must not silently treat its own proposal as trainer-approved.

Use an explicit state such as:

    draft -> pending_review -> approved/rejected

Do not remove or bypass this boundary without an explicit design decision.

### 4. Body tracking is a separate subsystem

Camera capture, pose estimation, movement analysis, and UI presentation should remain separable.

Do not put pose-estimation code directly inside screens/components unless there is a documented reason.

### 5. Database access

UI/presentation code must not access SQLite directly.

Prefer:

    UI
      -> application/service
      -> repository
      -> SQLite

Keep SQL/storage-specific details inside the database/repository layer.

### 6. Validate external input

Treat user input, AI output, API responses, and database data as untrusted input.

Validate data at boundaries.

Never assume an LLM response is valid merely because it matches the expected prose format.

### 7. Small, focused changes

Prefer small changes that can be tested and reviewed independently.

Do not refactor unrelated code while implementing a feature.

### 8. Do not invent APIs

Before using a library/API:
- inspect the installed version,
- inspect existing usage in the repository,
- or consult the official documentation.

Do not invent method names, configuration keys, or SDK behavior.

### 9. Tests

New business logic should have tests where practical.

Prioritize tests for:
- workout-plan generation/validation,
- trainer approval state transitions,
- repositories,
- data transformations,
- safety-critical decision boundaries.

Do not write tests that merely duplicate implementation details.

### 10. Verification

Before declaring a task complete, run the relevant checks.

For JavaScript/TypeScript code:

    npm run lint
    npm test

If TypeScript is used:

    npm run typecheck

If a check cannot be run, state that explicitly.

## AI-Agent Workflow

Before editing:
1. Inspect the relevant files.
2. Identify the smallest change that satisfies the request.
3. Check existing conventions.
4. Implement the change.
5. Run relevant verification.
6. Report what changed and what was verified.

Do not claim a task is complete merely because code was written.

## Dependency Rules

Do not add a dependency when the existing platform/library can solve the problem reasonably well.

When adding a dependency:
- explain why it is needed,
- prefer maintained packages,
- avoid adding multiple packages for the same responsibility.

## Security and Privacy

Do not commit:
- API keys,
- passwords,
- access tokens,
- private user data,
- production credentials.

Use environment variables or a secure secret-management mechanism.

Do not log sensitive user information unnecessarily.

## Git

Prefer focused commits.

Commit messages should describe the change, for example:

    feat: add workout plan validation
    fix: prevent unapproved plans from being activated
    test: cover trainer approval transitions

Do not rewrite history or force-push unless explicitly requested.

## When a Rule Is Repeatedly Violated

If a rule keeps being violated by humans or agents, consider moving it from a prompt/instruction into an automated guard:

    prompt rule
        -> lint rule
        -> test
        -> CI check

Prefer machine-verifiable constraints when practical.

## Definition of Done

A change is not considered complete until:

- the implementation is present,
- relevant tests/checks pass,
- no known lint/type errors remain,
- the architecture boundaries are respected,
- and any important limitation is documented.
