package com.example.gradecalculator

/**
 * PROJECT: Grade Calculator Mobile Application
 * MILESTONE 3: Object-Oriented Domain Model
 * SUBMITTED BY: Arthur Johann
 * 
 * Objective: Refine the app's data model using OOP principles.
 */

// 1. Interface defining common behavior
interface GradeReportable {
    fun generateReport(): String
}

// 2. Abstract class representing the core entity "Person" in the academic system
abstract class AcademicEntity(val name: String) : GradeReportable {
    // 3. Proper inheritance: Subclasses must define how they are identified
    abstract val identificationType: String
    
    // 4. Override toString() to provide a base string representation
    override fun toString(): String {
        return "[$identificationType] Name: $name"
    }
}

// 5. Data class implementation for Student (Milestone requirement)
data class StudentEntity(
    val studentName: String,
    val studentID: Int,
    val finalScore: Double,
    val letterGrade: String
) : AcademicEntity(studentName) {
    
    override val identificationType: String = "STUDENT_ID: $studentID"

    // Implementation of the interface method
    override fun generateReport(): String {
        return "Academic Report for $name: Score = $finalScore, Grade = $letterGrade"
    }
    
    // Data classes already provide a good toString(), but we can still rely on it or customize
    override fun toString(): String {
        return "${super.toString()} | Result: $letterGrade"
    }
}

// 6. Another concrete subclass to demonstrate inheritance and polymorphism
class Instructor(name: String, val department: String) : AcademicEntity(name) {
    override val identificationType: String = "FACULTY"

    override fun generateReport(): String {
        return "Instructor $name managing the $department department."
    }
}

/**
 * Main function showcasing the OOP hierarchy, inheritance, and polymorphism.
 */
fun main() {
    println("--- Milestone 3: Object-Oriented Domain Model Showcase ---\n")

    // 7. Demonstrate Polymorphism: Storing different subclass instances in a collection
    val academicEntities: List<AcademicEntity> = listOf(
        StudentEntity("Alice Johnson", 1001, 92.5, "A"),
        StudentEntity("Bob Smith", 1002, 78.0, "B"),
        Instructor("Dr. Sarah Williams", "Computer Science"),
        StudentEntity("Charlie Davis", 1003, 65.4, "D")
    )

    // 8. Iterate and call overridden methods (Polymorphism in action)
    academicEntities.forEach { entity ->
        println("Entity Info: $entity") // Calls overridden toString()
        println("Action: ${entity.generateReport()}") // Calls polymorphic generateReport()
        println("--------------------------------------------------")
    }

    // Showcase: Accessing data class specific features (copying)
    val topStudent = StudentEntity("Alice Johnson", 1001, 92.5, "A")
    val updatedStudent = topStudent.copy(finalScore = 95.0)
    println("\nData Class Feature (copy): Original = ${topStudent.finalScore}, Updated = ${updatedStudent.finalScore}")
}
