package com.example.gradecalculator.utils

object GradeUtils {
    fun calculateGrade(score: Double?): String {
        if (score == null) return "No Grade"
        return when {
            score >= 90 -> "A"
            score >= 80 -> "B"
            score >= 70 -> "C"
            score >= 60 -> "D"
            else -> "F"
        }
    }

    fun getPerformance(score: Double?): String {
        if (score == null) return "No score for student"
        return when {
            score >= 90 -> "Excellent"
            score >= 80 -> "Very Good"
            score >= 70 -> "Good"
            score >= 60 -> "Pass"
            else -> "Fail"
        }
    }

    fun formatScore(score: Double?): String {
        return score?.toString() ?: "No score"
    }
}
