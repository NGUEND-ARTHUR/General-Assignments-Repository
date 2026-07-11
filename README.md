# Software Engineering Project Portfolio (General-Assignments-Repository)

This repository is a **major academic software-engineering portfolio** that consolidates three substantial projects: **Diplomax CM**, **FocusFlow**, and **GradeCalculator**.

## Value Proposition
A single portfolio repository demonstrating full-stack engineering, Android/Flutter mobile development, backend services, security-aware system design, and applied academic software delivery.

## Problem Statement
The previous repository presentation looked like a generic assignment dump, which hid the strongest engineering work and made portfolio evaluation difficult.

## Proposed Solution
This repository is now documented as a structured portfolio where major projects are primary, and technical exercises are clearly marked as secondary supporting work.

## Real-World Context
The core projects address practical needs in academic credential verification, digital wellbeing and productivity, and grade analytics/reporting in education workflows.

## Featured Projects

### 1) Diplomax CM (Full-Stack Platform)
- **Folder:** [`diplomax_cm/`](./diplomax_cm)
- **Summary:** Multi-client academic credential issuance and verification platform.
- **Architecture (implemented):** FastAPI backend + PostgreSQL + Redis + Celery + Nginx + multiple Flutter clients.
- **Clients:**
  - [`diplomax_student`](./diplomax_cm/diplomax_student)
  - [`diplomax_university`](./diplomax_cm/diplomax_university)
  - [`diplomax_recruiter`](./diplomax_cm/diplomax_recruiter)
  - [`diplomax_admin`](./diplomax_cm/diplomax_admin)
- **Core docs:**
  - [`diplomax_cm/README.md`](./diplomax_cm/README.md)
  - [`diplomax_cm/RUNNING.md`](./diplomax_cm/RUNNING.md)
  - [`diplomax_cm/CI-CD.md`](./diplomax_cm/CI-CD.md)

### 2) FocusFlow (Android/Kotlin)
- **Folder:** [`FocusFlow/`](./FocusFlow)
- **Summary:** Digital wellbeing and focus management app with sensor-aware workflow foundations.
- **Architecture (implemented):** Kotlin + Jetpack Compose + MVVM + Room + Hilt.
- **Core docs:** [`FocusFlow/README.md`](./FocusFlow/README.md)

### 3) GradeCalculator (Kotlin + Flutter)
- **Folder:** [`GradeCalculator/`](./GradeCalculator)
- **Summary:** Cross-implementation grade management and reporting project with persistence and export workflows.
- **Implementations:**
  - [`GradeCalculator_Kotlin`](./GradeCalculator/GradeCalculator_Kotlin)
  - [`GradeCalculator_Dart`](./GradeCalculator/GradeCalculator_Dart)
- **Core docs:**
  - [`GradeCalculator/README.md`](./GradeCalculator/README.md)
  - [`GradeCalculator/GradeCalculator_Dart/README.md`](./GradeCalculator/GradeCalculator_Dart/README.md)

## Secondary Technical Exercises
The following folders remain part of the repository as supporting coursework artifacts:
- `exercise 1 Higher Order Function`
- `exercise 2 Transforming Between Collection Types`
- `exercise 3 Complex Data Processing`
- `exercise 4 Model a Zoo`
- `exercise 5 Network State`
- `exercise 6 Drawable Shapes`
- `exercise 7 Generic Function with Constraints`
- `exercise 8 Logger Delegation`
- `filtering and transforming with lambdas`

## Repository Structure
- `diplomax_cm/` — full-stack monorepo project
- `FocusFlow/` — Android project
- `GradeCalculator/` — Kotlin and Flutter grade-calculation projects
- `app/` + exercise folders — technical coursework modules

## Installation and Running (by project)
Because this is a multi-project repository, setup is project-specific:
- Diplomax CM: start with [`diplomax_cm/RUNNING.md`](./diplomax_cm/RUNNING.md)
- FocusFlow: open `FocusFlow/` in Android Studio and run the app module
- GradeCalculator Kotlin: open `GradeCalculator/GradeCalculator_Kotlin/` in Android Studio
- GradeCalculator Flutter: open `GradeCalculator/GradeCalculator_Dart/` and run standard Flutter commands

## Testing and Quality Checks
- Diplomax backend provides pytest smoke tests in `diplomax_cm/backend/tests/`.
- Diplomax CI workflows are available in [`.github/workflows`](./.github/workflows).
- Mobile projects include Gradle/Flutter lint-test configurations, dependent on local SDK/toolchain availability.

## Deployment Status
- **Diplomax CM:** CI/CD workflows configured for backend checks, APK builds, release assets, and backend image publication.
- **FocusFlow / GradeCalculator:** primarily academic-development and demonstration builds.

## Project Status
- **Diplomax CM:** active multi-component implementation.
- **FocusFlow:** implemented core app structure with some planned sensor features still stubbed/TODO.
- **GradeCalculator:** implemented Kotlin and Flutter milestone-aligned versions with export and persistence features.

## Limitations
- Some components are academic prototypes and may require production hardening.
- Full cross-project local validation requires Android, Flutter, Docker, and backend environment setup.

## Future Improvements
- Add screenshot assets for all three major projects under versioned documentation folders.
- Expand automated tests in mobile modules.
- Add cross-project architecture diagrams in markdown form.

## Authorship and Contribution Context
These projects are academic works with substantial personal design and implementation by **Nguend Arthur Johann**. Where collaborators exist, their roles should remain explicitly documented at project level.

## Licence
No repository-wide licence file is currently present. Add an explicit LICENSE file for clearer reuse terms.

## Contact
- GitHub: [NGUEND-ARTHUR](https://github.com/NGUEND-ARTHUR)

## Repository Naming Recommendation (not applied automatically)
Recommended new name for stronger portfolio readability:
- `software-engineering-project-portfolio`

Alternative names evaluated:
- `mobile-and-fullstack-projects`
- `academic-software-engineering-projects`
