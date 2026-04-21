# Exercise 6: Drawable Shapes

A practical demonstration of **Interfaces** in Kotlin.

## Task
Define an interface `Drawable` with a function `draw()`. Create classes `Circle` and `Square` that implement `Drawable`.

## Implementation
```kotlin
interface Drawable {
    fun draw(): String
}

class Circle(val radius: Int) : Drawable {
    override fun draw() = "   ***   \n *     * \n*       *"
}
```

## UI Features
-   **Terminal Visualization**: Shapes are rendered using ASCII art in a terminal-like environment within the app.
-   **Structure Display**: Details like radius and side length are shown alongside the drawings.
-   **Tech**: Built with Jetpack Compose and Material 3.
