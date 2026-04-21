package exercise_7_generic_function

/**
 * Exercise 7: Generic Function with Constraints
 * 
 * Task:
 * Write a generic function maxOf that returns the maximum element from a list.
 * The function should work for any type that implements Comparable<T>.
 */

fun <T : Comparable<T>> maxOf(list: List<T>): T? {
    if (list.isEmpty()) return null
    var max = list[0]
    for (i in 1 until list.size) {
        if (list[i] > max) {
            max = list[i]
        }
    }
    return max
}

fun main() {
    println("--- Exercise 7: Generic maxOf Function ---")
    
    val intList = listOf(3, 7, 2, 9)
    println("Max of $intList: ${maxOf(intList)}") // 9
    
    val stringList = listOf("apple", "banana", "kiwi")
    println("Max of $stringList: ${maxOf(stringList)}") // "kiwi"
    
    val emptyList = emptyList<Int>()
    println("Max of empty list: ${maxOf(emptyList)}") // null
}
