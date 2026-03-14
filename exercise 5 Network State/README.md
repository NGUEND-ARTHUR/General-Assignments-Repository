# Exercise 5: Network State Model

A practical demonstration of **Sealed Classes** in Kotlin.

## Task
Define a sealed class `NetworkState` representing:
-   **Loading**: A progress state.
-   **Success**: Containing data.
-   **Error**: Containing a message.

## Implementation
```kotlin
sealed class NetworkState {
    object Loading : NetworkState()
    data class Success(val data: String) : NetworkState()
    data class Error(val message: String) : NetworkState()
}
```

## UI Features
-   **State Management**: An interactive UI with buttons to switch states.
-   **Visual Feedback**: Distinct UI components for each state (progress indicators, success icons, and error alerts).
-   **Tech**: Built with Jetpack Compose and Material 3.
