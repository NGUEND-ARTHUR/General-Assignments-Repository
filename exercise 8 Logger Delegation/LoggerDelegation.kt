package exercise_8_logger_delegation

/**
 * Exercise 8: Implement a Logger Using Delegation
 * 
 * Task:
 * Create a simple logging system using delegation:
 * 1. Define an interface Logger with a function log(message: String).
 * 2. Provide two implementations: ConsoleLogger and FileLogger.
 * 3. Create a class Application that delegates logging to a Logger.
 */

interface Logger {
    fun log(message: String)
}

class ConsoleLogger : Logger {
    override fun log(message: String) {
        println("Console: $message")
    }
}

class FileLogger : Logger {
    override fun log(message: String) {
        println("File: $message")
    }
}

// Class delegation using the 'by' keyword
class Application(logger: Logger) : Logger by logger

fun main() {
    println("--- Exercise 8: Logger Delegation ---")
    
    val app = Application(ConsoleLogger())
    app.log("App started") // prints to console
    
    val fileApp = Application(FileLogger())
    fileApp.log("Error occurred") // File: Error occurred
}
