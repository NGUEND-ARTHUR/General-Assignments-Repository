package com.nguendarthurjohann.focusflow.utils

/**
 * Advanced Kotlin: Implementation by Delegation
 * FocusManager delegates logging to a Logger implementation
 */
interface FocusLogger {
    fun logFocusEvent(event: String)
}

class ConsoleFocusLogger : FocusLogger {
    override fun logFocusEvent(event: String) {
        println("[FOCUS_LOG]: $event")
    }
}

// FocusManager implements FocusLogger BY delegating to the provided logger
class FocusManager(logger: FocusLogger) : FocusLogger by logger {
    fun startSession() {
        logFocusEvent("Session started at ${System.currentTimeMillis()}")
    }
}
