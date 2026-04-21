# Exercise 8: Logger Delegation

A practical demonstration of **Class Delegation** in Kotlin.

## Task
Create a simple logging system using delegation:
1.  Define an interface `Logger` with a function `log(message: String)`.
2.  Provide two implementations: `ConsoleLogger` and `FileLogger`.
3.  Create a class `Application` that delegates logging to a `Logger`.

## Implementation
```kotlin
interface Logger {
    fun log(message: String)
}

class ConsoleLogger : Logger { ... }
class FileLogger : Logger { ... }

// Class delegation using the 'by' keyword
class Application(logger: Logger) : Logger by logger
```

## UI Features
-   **Log History**: Displays a history of all logged events.
-   **Dynamic Delegation**: Buttons to log via the `ConsoleLogger` or the `FileLogger`, showing how the application behaves differently based on the delegated logger.
-   **Tech**: Built with Jetpack Compose and Material 3.
