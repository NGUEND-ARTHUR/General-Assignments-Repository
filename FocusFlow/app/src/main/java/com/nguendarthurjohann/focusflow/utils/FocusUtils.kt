package com.nguendarthurjohann.focusflow.utils

/**
 * Advanced Kotlin: Generic Class
 * A generic wrapper for managing the state of any resource (Data, Error, Loading)
 */
sealed class Resource<T>(val data: T? = null, val message: String? = null) {
    class Success<T>(data: T) : Resource<T>(data)
    class Error<T>(message: String, data: T? = null) : Resource<T>(data, message)
    class Loading<T>(data: T? = null) : Resource<T>(data)
}

/**
 * Advanced Kotlin: Generic Function with Constraints
 * A function to find a specific session in any list of "Identifiable" objects
 */
interface Identifiable {
    val id: String
}

fun <T : Identifiable> findById(list: List<T>, id: String): T? {
    return list.find { it.id == id }
}

/**
 * Advanced Kotlin: Higher-Order Function
 * Processes focus data and applies a custom transformation
 */
fun <T, R> List<T>.processData(transform: (T) -> R): List<R> {
    return this.map { transform(it) }
}
