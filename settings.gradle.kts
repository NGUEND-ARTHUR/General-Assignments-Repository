pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "General-Assignments-Repository"

// Main App for Technical Exercises
include(":app")

// FocusFlow Module
include(":focusflow")
project(":focusflow").projectDir = file("FocusFlow/app")

// GradeCalculator Module
include(":gradecalculator")
project(":gradecalculator").projectDir = file("GradeCalculator/GradeCalculator_Kotlin/app")
