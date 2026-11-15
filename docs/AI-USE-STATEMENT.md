# AI Use Statement

**Project:** AI Fitness Coach  
**Project stage:** Prototype  
**Last updated:** 2026-11-15

This statement explains how generative AI is used while developing this repository and how AI-assisted capabilities are intended to be used in the application. It is a transparency note; it is not a privacy policy, medical disclaimer, or guarantee that every proposed feature is implemented.

## 1. AI-assisted development

Generative AI assistants, including ChatGPT, have been used as supporting tools during project planning and development. They may be used to help with:

- Exploring requirements, user journeys, interface ideas, and technical approaches
- Drafting or improving documentation and explanatory text
- Producing or suggesting code and UI-prototype snippets
- Explaining errors, exploring debugging approaches, and proposing test cases

AI output is treated as a draft or suggestion, not as an authoritative source. A human contributor is responsible for reviewing, adapting, testing, and deciding whether to use it. AI-generated code or documentation must not be accepted solely because an AI tool produced it.

## 2. AI-assisted capabilities in the application

The project explores an AI-assisted fitness-coaching experience. The intended capabilities include helping users understand exercise options and preparing proposed workout plans based on relevant user-provided context, such as goals, training history, available time, and other suitability information.

Camera-based pose or movement feedback is a separate computer-vision capability. It should not be described as an LLM feature, and its accuracy depends on the selected implementation and the user's recording conditions.

This repository is a prototype. The implementation status can differ between screens and experiments:

- Some screens may use illustrative or demo data.
- Some interactions may use predefined or fallback responses.
- A provider selector, API-key field, or AI-labelled screen does not by itself prove that a live model integration is active.
- Check the relevant prototype and its implementation notes before assuming that an AI request is sent to an external service.

## 3. Human review and safety

AI may suggest a workout plan, but it must not mark its own suggestion as trainer-approved. The intended workflow keeps a clear review boundary:

    draft → pending_review → approved / rejected

A plan must remain a proposal until a human trainer has reviewed it and explicitly approved it. AI output must not override a user's clinician or doctor's instructions.

AI-generated fitness information is not a medical diagnosis, treatment, or clearance to exercise. Users with injuries, medical conditions, pain, or other health concerns should follow advice from an appropriately qualified professional. Camera-based pose estimates can also be wrong and must not be treated as medical measurements.

These principles follow the project rules in [AGENTS.md](../AGENTS.md).

## 4. Data protection and external AI services

Workout history, body measurements, fatigue information, medical context, camera frames, and account information may be sensitive. The project should minimise the data it collects and uses.

The prototype's intended approach is to keep user records on the user's device where the relevant implementation supports local storage. This does **not** mean that information included in a request to an external AI provider remains on the device. When an external provider is used, the information included in the request may be transmitted to and processed by that provider.

Before sending real user information to an external AI service, the application must clearly explain what is sent and why, obtain appropriate user consent, minimise the information shared, and document the provider's applicable data handling and retention terms. Do not use identifiable or health-related user data for AI testing without appropriate authorisation and safeguards.

API keys, access tokens, passwords, and other secrets must never be committed to this repository. Use an appropriate local secret or environment-variable mechanism during development.

## 5. Accuracy, verification, and third-party material

Generative AI can produce incorrect, incomplete, outdated, or fabricated information and code. Contributors should:

- Verify technical guidance against the actual dependency versions, source code, and official documentation.
- Test generated or AI-modified code where practical and review security-sensitive changes carefully.
- Check factual claims against reliable sources before including them in project documentation.
- Review the licences and attribution requirements for third-party code, datasets, images, and other assets.

An AI-generated answer is not, by itself, evidence that a feature works or that a recommendation is safe.

## 6. Keeping this statement current

Update this statement when the project's AI-development workflow, user-facing AI capabilities, model providers, or categories of data sent to external services materially change. Individual prototypes should also document whether their AI behaviour is live, simulated, based on fallback content, or not yet connected.

---

For the current engineering and safety requirements, see [AGENTS.md](../AGENTS.md). For design-documentation conventions, see [design/README.md](design/README.md).
