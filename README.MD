# FORGE — AI-Powered Mobile Fitness Coach

**FORGE** is an AI-powered mobile fitness coaching application designed to help users build personalized workout routines, track real-time exercise form and repetitions using on-device computer vision, monitor body recovery and hydration status, and collaborate safely with human trainers through a Human-in-the-Loop review workflow.

---

## Team Members — Group 23 (Trauma Squad)

| Student ID | Full Name | GitHub Account | Primary Responsibilities |
| :--- | :--- | :--- | :--- |
| `6931503043` | Thammachot Rukkatekit | [@6931503043-TR](https://github.com/6931503043-TR) | System Architecture, Flutter App (`app/forge`), Repository Management |
| `6931503046` | Naratip Chalee | [@github-username](https://github.com/github-username) | AI Motion & Pose Estimation (`ai/motion_proto`), SRS & Design Diagrams |
| `6931503033` | Thitapa Chaichan | [@github-username](https://github.com/github-username) | UI/UX Interactive Prototypes (`Prototype/`), Body Metrics & Chat Flows |

> *Note: Please update `@github-username` above with the actual GitHub handles of all team members.*

---

## How to Open the Interactive Prototype

The interactive prototype is maintained as a single HTML file under `docs/prototypes/unified/`. The `Prototype/index.html` file is the entry point that redirects to that Unified Prototype.

1. **Via GitHub Pages (Recommended):**
   - Open the [AI Fitness Coach Prototype](https://6931503043-tr.github.io/AI-fitness-Project1/Prototype/).
   - This is the live demo URL. It opens the entry point and redirects to the latest Unified Prototype deployed from the `main` branch.

2. **Via Local Browser:**
   - Clone or download the **entire repository** and extract it without changing the folder structure.
   - Open `Prototype/index.html` in a modern web browser (Chrome, Edge, Safari, or Firefox).
   - The entry point uses a relative path to load `docs/prototypes/unified/ai-fitness-coach-unified-prototype.html`, so both folders must remain in the repository structure. No local server or build step is required.

3. **Unified Prototype Source:**
   - [View the Unified Prototype file on GitHub](https://github.com/6931503043-TR/AI-fitness-Project1/blob/main/docs/prototypes/unified/ai-fitness-coach-unified-prototype.html).

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
├── README.MD                  # Project overview, team info, and quick-start guide
├── .gitignore                 # Ignore build artifacts, dependencies, and OS files
├── docs/                      # Software engineering documentation and prototypes
│   ├── M1-team-charter.pdf    # Team charter and roles
│   ├── M2-srs.pdf             # Software Requirements Specification
│   ├── final-report.md        # Final summary report & Golden Thread traceability
│   ├── ai-use-statement.md    # Disclosure of AI tools used during development
│   └── design/                # UML & Architecture diagrams
├── Prototype/                 # Browser entry point for the interactive prototype
│   └── index.html             # Redirects to the Unified Prototype
├── docs/
│   └── prototypes/
│       └── unified/
│           └── ai-fitness-coach-unified-prototype.html
│                                # Main standalone interactive HTML prototype
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
