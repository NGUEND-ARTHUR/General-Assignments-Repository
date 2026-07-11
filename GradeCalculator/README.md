# GradeCalculator (Kotlin + Flutter)

Multi-implementation academic software project for student grade management, analysis, persistence, and reporting.

## One-Sentence Value Proposition
GradeCalculator demonstrates parallel Kotlin and Flutter implementations of the same educational domain problem with practical export and sharing workflows.

## Problem Statement
Students and instructors need a simple way to record scores, compute grades, review performance, and export results.

## Proposed Solution
This project delivers equivalent grade-calculation workflows in:
- native Android Kotlin
- Flutter/Dart

## Real-World Context
The repository supports educational data handling tasks such as class-level grading, summary statistics, and report distribution.

## Implemented Features
### Shared Functional Scope
- Student record entry
- Grade calculation and display
- Milestone-based functional/OOP demonstrations
- Persistent local storage

### Kotlin Implementation
- Jetpack Compose UI
- Room database (`StudentDao`, `AppDatabase`)
- Statistics views and navigation
- Export utilities for PDF, Excel, CSV
- Sharing integration

### Flutter Implementation
- Material UI and Provider state management
- Local persistence via `sqflite`
- Import from Excel files
- Export/share to Excel and PDF
- Locale support (`en`, `fr`)

## Architecture Overview
- **Presentation:** Compose (Kotlin) / Flutter widgets
- **State:** ViewModel + LiveData (Kotlin), Provider (Flutter)
- **Data:** Room (Kotlin), sqflite (Flutter)
- **Utilities:** export/import and grade-calculation modules

## Technology Stack
- Kotlin, Android SDK, Jetpack Compose, Room
- Dart, Flutter, Provider, sqflite
- PDF/Excel export libraries

## Repository Structure
- `GradeCalculator_Kotlin/` — Android Kotlin app
- `GradeCalculator_Dart/` — Flutter app
- Project milestone files in both implementations

## Installation and Running
### Kotlin
1. Open `GradeCalculator_Kotlin/` in Android Studio.
2. Sync Gradle and run the app module.

### Flutter
1. Open `GradeCalculator_Dart/`.
2. Run:
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
   - `flutter run`

## Testing
- Kotlin: run Gradle test tasks in Android Studio/CLI
- Flutter: run `flutter test` and `flutter analyze`

## Deployment Status
Academic project; distributed as development/demo builds.

## Project Status
Feature-complete for current milestones, with room for additional validation and UX hardening.

## Limitations
- Local-device focused persistence (no shared backend service).
- Full CI automation for both implementations is not yet centralized.

## Future Improvements
- Add synchronized cloud-backed storage option
- Expand automated test coverage
- Add richer analytics and visualization modules

## Author and Contribution Context
This is an academic project demonstrating substantial implementation work by **Nguend Arthur Johann** across both Kotlin and Flutter tracks.

## Licence
No explicit license file is currently provided in this subproject.

## Contact
- GitHub: [NGUEND-ARTHUR](https://github.com/NGUEND-ARTHUR)
