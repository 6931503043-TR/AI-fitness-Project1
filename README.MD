# FORGE — AI-Powered Mobile Fitness Coach

**FORGE** is an AI-powered mobile fitness coaching application designed to help users build personalized workout routines, track real-time exercise form and repetitions using on-device computer vision, monitor body recovery and hydration status, and collaborate safely with human trainers through a Human-in-the-Loop review workflow.

---

## Team Members — Group 23 (Trauma Squad)

| Student ID | Full Name | GitHub Account | Primary Responsibilities |
| :--- | :--- | :--- | :--- |
| `6931503043` | Thammachot Rukkatekit | [@6931503043-TR](https://github.com/6931503043-TR) | System Architecture, Flutter App (`app/forge`), Repository Management |
| `6931503046` | Naratip Chalee | [@github-username](https://github.com/github-username) | AI Motion & Pose Estimation (`ai/motion_proto`), SRS & Design Diagrams |
| `6931503033` | Thitapa Chaichan | [@github-username](https://github.com/github-username) | UI/UX Interactive Prototypes (`prototype/`), Body Metrics & Chat Flows |

> *Note: Please update `@github-username` above with the actual GitHub handles of all team members.*

---

## How to Open the Interactive Prototype

The interactive UI prototype is built with standalone HTML, CSS, and JavaScript—**no backend server, database, or installation is required**.

1. **Via Local Browser (Recommended):**
   - Clone or download this repository.
   - Open the file [`prototype/index.html`](prototype/index.html) or [`docs/Prototypes/unified/ai-fitness-coach-unified-prototype.html`](docs/prototypes/unified/ai-fitness-coach-unified-prototype.html) directly in any modern web browser (Chrome, Edge, Safari, or Firefox).
   - Use the navigation hub on `index.html` to switch between all core screens:
     - **Workout Planner (`plan.html`)**: Browse templates, filter by muscle group, and generate/customize plans with AI.
     - **Body Status Dashboard (`body.html`)**: View muscle fatigue, recovery readiness, TDEE, and hydration status.
     - **Coach & AI Chat (`chat.html`)**: Chat with the AI Coach, human trainer, or friends, including high-risk escalation flows.
     - **Profile & Settings (`settings.html`)**: Manage personal fitness goals, units, and medical constraints.

2. **Via GitHub Pages (Optional):**
   - Live Demo URL: `https://6931503043-tr.github.io/AI-fitness-Project1/prototype/` *(Enable GitHub Pages on branch `main` to activate)*

---

## Project Documentation & Deliverables

All software engineering artifacts are organized under `docs/` and `slides/`:

- **Team Charter (Milestone 1):** [`docs/M1-team-charter.pdf`](docs/M1-team-charter.pdf)
- **Software Requirements Specification (Milestone 2):** [`docs/M2-srs.pdf`](docs/M2-srs.pdf)
- **System Design Diagrams:** [`docs/design/`](docs/design/)
  - Use-Case Diagram
  - System Architecture Diagram
  - UML Class Diagram
- **Final Project Report & Golden Thread:** [`docs/final-report.md`](docs/final-report.md)
- **AI Use Statement:** [`docs/ai-use-statement.md`](docs/ai-use-statement.md)
- **Demo Presentation Slides:** [`slides/demo-slides.pdf`](slides/demo-slides.pdf)

---

## Repository Structure

```text
AI-fitness-Project1/
├── README.md                  # Project overview, team info, and quick-start guide
├── .gitignore                 # Ignore build artifacts, dependencies, and OS files
├── docs/                      # Software engineering documentation
│   ├── M1-team-charter.pdf    # Team charter and roles
│   ├── M2-srs.pdf             # Software Requirements Specification
│   ├── final-report.md        # Final summary report & Golden Thread traceability
│   ├── ai-use-statement.md    # Disclosure of AI tools used during development
│   └── design/                # UML & Architecture diagrams
├── prototype/                 # Standalone interactive HTML prototype (no server needed)
│   ├── index.html             # Single entry point / main navigation hub
│   ├── plan.html              # Workout plan creator & AI assistant UI
│   ├── body.html              # Body status, recovery & hydration UI
│   ├── chat.html              # Trainer, friend & AI chat UI
│   └── settings.html          # Profile, preferences & medical constraints UI
├── slides/                    # Presentation materials
│   └── demo-slides.pdf        # Final demo presentation slides
├── app/                       # Main Flutter mobile application (Riverpod + Drift SQLite)
│   └── forge/
└── ai/                        # On-device computer vision & rep-counting prototypes
    └── motion_proto/
```

---

## Tech Stack & Implementation Highlights

- **Mobile Framework:** Flutter (Dart) with Riverpod state management and Drift (SQLite) local persistence (`app/forge/`).
- **On-Device Vision & Pose Estimation:** Real-time joint angle gauge, skeleton overlay, and automated rep counter (`ai/motion_proto/`).
- **Safety & Privacy by Design:** Video frames are processed locally on-device; high-risk user constraints or fatigue alerts escalate to a human trainer (`draft` $\rightarrow$ `pending_review` $\rightarrow$ `approved`).
