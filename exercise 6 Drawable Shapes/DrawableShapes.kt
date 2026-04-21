package exercise_6_drawable_shapes

/**
 * Exercise 6: Drawable Shapes with Interfaces
 * 
 * Task:
 * Define an interface Drawable with a function draw().
 * Create classes Circle and Square that implement Drawable.
 * Each should have appropriate properties (radius, side length) and print a simple ASCII representation.
 */

interface Drawable {
    fun draw()
}

class Circle(val radius: Int) : Drawable {
    override fun draw() {
        println("Circle with radius $radius:")
        println("   ***   ")
        println(" *     * ")
        println("*       *")
        println(" *     * ")
        println("   ***   ")
    }
}

class Square(val sideLength: Int) : Drawable {
    override fun draw() {
        println("Square with side length $sideLength:")
        println("*******")
        println("*     *")
        println("*     *")
        println("*     *")
        println("*******")
    }
}

fun main() {
    val shapes: List<Drawable> = listOf(
        Circle(5),
        Square(10)
    )
    
    shapes.forEach { it.draw() }
}
