package com.example.gradecalculator.utils

/**
 * Base abstract class demonstrating Abstraction and Inheritance.
 * Every calculator in the app should extend this class.
 */
abstract class Calculator(val name: String) {
    /**
     * Every sub-class must provide its own implementation of the calculation logic.
     */
    abstract fun calculate(input: Double?): String
}
