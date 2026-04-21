package com.example.gradecalculator

import com.example.gradecalculator.utils.GradeUtils
import java.util.Scanner

/**
 * An interactive console-based runner.
 * Allows you to enter student names and scores to get their grades.
 */
fun main() {
    val scanner = Scanner(System.`in`)
    println("==============================================")
    println("   STUDENT GRADE CALCULATOR - INTERACTIVE     ")
    println("==============================================")
    
    while (true) {
        print("\nEnter student name (or type 'exit' to quit): ")
        val name = scanner.nextLine()
        if (name.lowercase() == "exit") break
        
        print("Enter score for $name (leave blank for no score): ")
        val scoreInput = scanner.nextLine()
        
        val score = if (scoreInput.isBlank()) {
            null
        } else {
            scoreInput.toDoubleOrNull()
        }
        
        if (scoreInput.isNotBlank() && score == null) {
            println("Invalid score format. Please enter a number.")
            continue
        }
        
        val grade = GradeUtils.calculateGrade(score)
        val scoreDisplay = GradeUtils.formatScore(score)
        
        println("----------------------------------------------")
        if (score != null) {
            println("$name scored $scoreDisplay : Grade $grade")
        } else {
            println("No score for $name : Grade $grade")
        }
        println("----------------------------------------------")
    }
    
    println("\nExiting. Goodbye!")
    println("==============================================")
}
