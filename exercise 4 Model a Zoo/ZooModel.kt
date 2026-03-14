package exercise_4_model_a_zoo

/**
 * Exercise 4: Model a Zoo
 * 
 * Task:
 * Create a class hierarchy for animals:
 * Abstract class Animal with name and abstract makeSound().
 * Two concrete subclasses: Dog and Cat, each with their own sound.
 * Add a property legs to Animal.
 * 
 * Expected output:
 * Buddy says Woof!
 * Whiskers says Meow!
 */

abstract class Animal(val name: String) {
    abstract val legs: Int
    abstract fun makeSound(): String
}

class Dog(name: String) : Animal(name) {
    override val legs = 4
    override fun makeSound() = "Woof!"
}

class Cat(name: String) : Animal(name) {
    override val legs = 4
    override fun makeSound() = "Meow!"
}

fun main() {
    val animals = listOf(
        Dog("Buddy"),
        Cat("Whiskers")
    )
    
    animals.forEach { animal ->
        println("${animal.name} says ${animal.makeSound()}")
    }
}
