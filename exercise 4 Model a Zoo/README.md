# Exercise 4: Model a Zoo

A practical demonstration of **Object-Oriented Programming (OOP)** hierarchy in Kotlin.

## Task
Create a class hierarchy for animals:
-   **Abstract Class**: `Animal` (with `name` and abstract `makeSound()`).
-   **Concrete Subclasses**: `Dog` and `Cat`.
-   **Polymorphism**: Iterate through a list of animals and call their unique sounds.

## Implementation
```kotlin
abstract class Animal(val name: String) {
    abstract val legs: Int
    abstract fun makeSound(): String
}

class Dog(name: String) : Animal(name) {
    override val legs = 4
    override fun makeSound() = "Woof!"
}
```

## UI Features
-   **Animal List**: Displays each animal with its name and calculated legs.
-   **Action Display**: Shows the polymorphic sound output (`Woof!` or `Meow!`) with custom styling.
-   **Tech**: Built with Jetpack Compose and Material 3.
