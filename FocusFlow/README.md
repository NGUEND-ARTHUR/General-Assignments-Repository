# FocusFlow

FocusFlow is a modern Android application built to optimize user productivity by monitoring environmental factors and user behavior to maintain high focus levels.

## Milestone 1: Data Modeling
The current phase of the project focuses on establishing a robust data model to capture and process environmental and behavioral data.

### Key Features
- **Environmental Monitoring**: Tracks ambient light levels (Lux) and background noise (dB).
- **Behavioral Tracking**: Monitors user distance from the screen (cm) and sedentary status to prevent fatigue.
- **Session Management**: Each focus period is uniquely identified for data analysis.

### Data Architecture
The core of the system is the `FocusState` data model, which encapsulates the following attributes:
- `lightLevelLux`: Ambient light intensity to detect eye strain risks.
- `faceDistanceCm`: Real-time proximity monitoring.
- `noiseDb`: Background noise measurement to ensure a quiet environment.
- `isSedentary`: A Boolean flag to prompt movement breaks.
- `sessionID`: Unique identifier for each session.

## Tech Stack
- **Kotlin**: Used for data modeling and logic.
- **Jetpack Compose**: For a modern and responsive user interface.
- **Material Design 3**: For a clean, professional aesthetic.

## How to Run
1. Open the `/FocusFlow` directory in Android Studio.
2. Sync the project with Gradle.
3. Run the `app` module on an Android emulator or physical device.
