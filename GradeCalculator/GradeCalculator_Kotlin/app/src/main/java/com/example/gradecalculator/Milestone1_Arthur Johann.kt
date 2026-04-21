package com.example.gradecalculator

import com.example.gradecalculator.model.Student
import com.example.gradecalculator.utils.GradeUtils

/**
 * Milestone 1: Functional Programming Concepts in Kotlin
 * This file demonstrates functions operating on data classes, higher-order functions, 
 * lambdas, and collection operations.
 */

// 1. Two functions that operate on the data class
fun Student.formatDetails(): String {
    val scoreText = score?.toString() ?: "No score"
    return "Student: $name | Score: $scoreText | Grade: $grade"
}

fun Student.isValid(): Boolean {
    return name.isNotBlank() && (score == null || score in 0.0..100.0)
}

// 2. Custom higher-order function
fun processStudents(students: List<Student>, action: (Student) -> Unit) {
    for (student in students) {
        action(student)
    }
}

fun main() {
    println("--- Milestone 1: Student Grade Calculator Demonstration ---")

    val studentList = listOf(
        Student(name = "Alice", score = 95.0, grade = "A"),
        Student(name = "Bob", score = 82.0, grade = "B"),
        Student(name = "Charlie", score = 74.0, grade = "C"),
        Student(name = "Daisy", score = 68.0, grade = "D"),
        Student(name = "Ethan", score = 55.0, grade = "F"),
        Student(name = "Fiona", score = null, grade = "No Grade"),
        Student(name = "Invalid", score = 150.0, grade = "F")
    )

    // 3. Showcase: Collection operation (filter a list of items)
    println("\n1. Filtering valid students (score between 0 and 100 or null):")
    val validStudents = studentList.filter { it.isValid() }
    validStudents.forEach { println(it.formatDetails()) }

    // 4. Showcase: Lambda passed to a custom higher-order function
    println("\n2. Processing students with a lambda (printing only those with grades):")
    processStudents(validStudents) { student ->
        if (student.grade != "No Grade") {
            println("Verified Result: ${student.name} -> ${student.grade}")
        }
    }

    // 5. Showcase: Using map (higher-order function) to get names
    val names = validStudents.map { it.name }
    println("\n3. Student Names List: $names")
}
