# Design Documentation

This directory is the home for design decisions and supporting documentation for the **AI Fitness Coach** prototype.

It keeps the reasoning behind the product experience close to the UI prototypes, while making it clear which materials describe an accepted design and which are exploratory examples.

## What belongs here

Use this directory for:

- Screen specifications and component behaviour
- User journeys, navigation flows, and interaction rules
- Design-system decisions, including layout, colour, typography, and reusable patterns
- Accessibility and responsive-behaviour notes
- Design decisions, alternatives considered, and their rationale

## Existing UI prototypes

Interactive HTML prototypes are stored separately in [../prototypes/](../prototypes/). The current collection includes:

- **body/** — Body Status and body-related screens
- **chat/** — trainer and AI chat explorations
- **plan/** — workout-plan flows and plan-building explorations
- **settings/** — settings screens
- **legacy/** — earlier prototypes kept for reference

A prototype is an exploration or demonstration, not automatically the final product specification or proof that every depicted feature is implemented. Demo data, fallback text, and AI-related UI should be interpreted according to the implementation in that prototype.

## Recommended documentation structure

Add files when there is real content to document; do not create empty folders solely for a future possibility.

    docs/
    ├── design/
    │   ├── README.md
    │   ├── screens/
    │   ├── user-flows/
    │   ├── design-system/
    │   └── decisions/
    └── prototypes/
        ├── body/
        ├── chat/
        ├── plan/
        ├── settings/
        └── legacy/

The subdirectories shown under design/ are suggested locations, not folders that must all exist now.

## Suggested format for a design document

When relevant, include:

1. **Status** — Draft, In Review, Accepted, Implemented, or Retired
2. **Purpose** — the user problem or requirement being addressed
3. **Scope** — what is included and what is intentionally excluded
4. **Behaviour** — interactions, navigation, validation, and important states
5. **Responsive behaviour** — expected behaviour on mobile, tablet, and desktop
6. **Accessibility** — keyboard use, labels, contrast, and other relevant considerations
7. **Related materials** — prototype paths, requirements, and implementation references
8. **Open questions** — decisions that are not yet confirmed

Use relative links to connect design documents to the relevant prototype or implementation. Update the document when an accepted design decision changes.

## Project constraints

Design proposals must remain consistent with the project guidance in [../../AGENTS.md](../../AGENTS.md), especially the prototype scope, separation of responsibilities, privacy and security rules, and the human-trainer approval boundary for AI-proposed workout plans.

Do not describe a simulated or unconnected AI interaction as a production AI capability. Record known limitations alongside the relevant design.
