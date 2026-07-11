# FocusFlow

Android productivity and digital-wellbeing project built as an academic software-engineering application.

## One-Sentence Value Proposition
FocusFlow helps students manage focus sessions and task prioritization while integrating sensor-aware wellbeing indicators.

## Problem Statement
Students often combine long study periods, weak task prioritization, and unhealthy device usage habits.

## Proposed Solution
FocusFlow combines timer-based focus sessions, task management, and wellbeing-oriented signals in one Android experience.

## Real-World Context
The app is designed for student daily study workflows where productivity and healthy digital behavior need to be balanced.

## Implemented Features
- Focus session timer workflow (`FocusScreen`, `FocusViewModel`)
- Task management with Eisenhower-style quadrants (`TasksScreen`, `TaskDao`, `TaskEntity`)
- Local persistence with Room (`AppDatabase`, entities for tasks/logs/plants)
- Jetpack Compose navigation (`Dashboard`, `Focus`, `Tasks`, `Social`)
- Sensor integration foundations:
  - ambient light sensor
  - accelerometer-based sedentary indicator
- Dependency injection with Hilt

## Planned / Partially Implemented Features
- Camera-based face distance monitoring (currently stubbed)
- Microphone-based noise detection (currently stubbed)
- Deeper analytics and recommendation workflows

## Architecture Overview
- **UI:** Jetpack Compose screens and reusable components
- **State and Logic:** ViewModels with Kotlin Flow
- **Data:** Room entities and DAO layer
- **DI:** Hilt modules
- **Pattern:** MVVM

## Technology Stack
- Kotlin
- Android SDK (min 26)
- Jetpack Compose
- Room
- Hilt
- Coroutines / StateFlow

## Repository Structure
- `app/src/main/java/com/nguendarthurjohann/focusflow/` — app source code
- `app/src/main/java/.../ui/` — screens, theme, navigation, viewmodels
- `app/src/main/java/.../data/local/` — database, DAO, entities

## Installation and Running
1. Open `FocusFlow/` in Android Studio.
2. Sync Gradle dependencies.
3. Run the `app` module on emulator or device.

## Testing
Use Android/Gradle standard tasks in a configured Android environment:
- unit tests: `test`
- instrumentation tests: `connectedAndroidTest`

## Deployment Status
Academic project; no production deployment pipeline is currently documented.

## Project Status
Prototype-to-implementation hybrid: core workflows implemented, advanced sensor intelligence still in progress.

## Limitations
- Some sensor features are placeholder implementations.
- Behavior depends on device sensor availability and calibration.

## Future Improvements
- Complete camera and microphone sensor pipelines
- Add integration tests and broader persistence tests
- Expand data insights and recommendation engine

## Contributions
- **Lead Developer:** Nguend Arthur Johann
- **Quality Test Developer (as documented):** Madongue Jeanne Lesline

## Licence
Educational project context (no standalone license file currently provided in this folder).

## Contact
- GitHub: [NGUEND-ARTHUR](https://github.com/NGUEND-ARTHUR)
