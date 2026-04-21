# General Assignments Repository

This monorepo contains coursework and production-style app projects across Kotlin, Android, and Flutter.

## Main Project Folders

### Diplomax CM

Path: `diplomax_cm/`

Current state:

- Full stack monorepo with a FastAPI backend and three Flutter clients.
- Clients: `diplomax_student`, `diplomax_university`, `diplomax_recruiter`.
- Production default API target in apps: `https://api.diplomax.cm/v1`.
- Local/staging override supported via `--dart-define=API_BASE_URL=...`.
- CI/CD workflows are configured in `.github/workflows` for backend tests, Flutter checks, APK builds, release publishing, and backend image publish.

Useful docs:

- `diplomax_cm/RUNNING.md`
- `diplomax_cm/CI-CD.md`

### FocusFlow

Path: `FocusFlow/`

Current state:

- Android productivity and digital wellbeing app.
- Milestone 1 data-model work is documented and implemented.

### GradeCalculator

Path: `GradeCalculator/`

Current state:

- Kotlin and Flutter variants are both present.
- Functional programming and OOP milestones are documented.
- Dart app includes grade management, persistence, PDF/export, and sharing dependencies.

## Technical Exercises

The following folders contain completed Kotlin exercise solutions with dedicated documentation:

1. `exercise 1 Higher Order Function/`
2. `exercise 2 Transforming Between Collection Types/`
3. `exercise 3 Complex Data Processing/`
4. `exercise 4 Model a Zoo/`
5. `exercise 5 Network State/`
6. `exercise 6 Drawable Shapes/`
7. `exercise 7 Generic Function with Constraints/`
8. `exercise 8 Logger Delegation/`
9. `filtering and transforming with lambdas/`

## Getting Started

- Open any project folder directly in Android Studio or VS Code.
- For Diplomax CM, start with `diplomax_cm/RUNNING.md`.
- For CI/CD and release automation, see `diplomax_cm/CI-CD.md`.
