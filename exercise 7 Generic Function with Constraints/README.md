# Exercise 7: Generic Function with Constraints

A practical demonstration of **Generics** in Kotlin.

## Task
Write a generic function `maxOf` that returns the maximum element from a list. The function should work for any type that implements `Comparable<T>`.

## Implementation
```kotlin
fun <T : Comparable<T>> maxOf(list: List<T>): T? {
    if (list.isEmpty()) return null
    var max = list[0]
    for (i in 1 until list.size) {
        if (list[i] > max) max = list[i]
    }
    return max
}
```

## UI Features
-   **Multi-Type Support**: Shows the maximum value for a list of Integers and a list of Strings.
-   **Edge Case Handling**: Displays the behavior of the function when passed an empty list.
-   **Tech**: Built with Jetpack Compose and Material 3.
