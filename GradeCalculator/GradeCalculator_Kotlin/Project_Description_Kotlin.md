# Full Project Documentation: GradeCalculator (Kotlin Native)

This document provides a detailed technical breakdown of the Grade Calculator application implemented using Native Android technologies.

## 1. Architectural Overview: MVVM
The application is built using the **Model-View-ViewModel (MVVM)** architectural pattern, which is the industry standard for modern Android development. This ensures that the UI logic is separated from the data management.

### A. The Model Layer (`com.example.gradecalculator.model`)
The core of our data is the `Student` class.
```kotlin
@Entity(tableName = "students")
data class Student(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val score: Double?, // Nullable to support "No score" scenarios
    val grade: String
)
```
- **Explanation**: We use Room's `@Entity` annotation to define the database schema directly from this class. The `score` is a `Double?` (nullable), which is crucial for handling students who haven't received a mark yet, as specified in the requirements.

### B. The Data Layer (`com.example.gradecalculator.data`)
This layer handles all local storage operations using the **Room Persistence Library**.
- **StudentDao.kt**: This Interface defines the "Data Access Object." It uses annotations like `@Insert`, `@Update`, and `@Delete` to generate the necessary SQL code.
- **AppDatabase.kt**: The main database entry point.
```kotlin
@Database(entities = [Student::class], version = 2)
abstract class AppDatabase : RoomDatabase() {
    // Uses fallbackToDestructiveMigration() to allow schema changes 
    // without complex migration scripts during development.
}
```

### C. The ViewModel Layer (`com.example.gradecalculator.viewmodel`)
The `StudentViewModel` is the "Brain" of the app. It holds and manages UI-related data in a lifecycle-conscious way.
```kotlin
val averageScore: LiveData<Double> = allStudents.map { students ->
    val validScores = students.mapNotNull { it.score }
    if (validScores.isEmpty()) 0.0 else validScores.average()
}
```
- **Code Logic**: We use `mapNotNull` to filter out students without scores before calculating the average. This ensures that "No score" entries don't skew the mathematical results or cause errors.

### D. The View Layer (UI)
- **ManualEntryFragment.kt**: Implements the `ActivityResultContracts.GetContent()` for picking Excel files. It converts the selection into a URI that our `ExcelUtils` can process.
- **ResultsFragment.kt**: Uses a `RecyclerView` with a custom `StudentAdapter`. It implements a `PopupMenu` for selective record management (Edit/Delete).

## 2. External Integration: Apache POI (Excel)
We use the **Apache POI** library to bridge the gap between Android and Excel files.
- **Import Logic**: `WorkbookFactory.create(inputStream)` reads the file. We iterate through rows, skip the header (row 0), and extract Name (Col A) and Score (Col B).
- **Export Logic**: `XSSFWorkbook()` creates a new memory-based workbook. We populate it with data from our Room database and save it to a URI provided by the system's `CreateDocument` contract.

## 3. Core Logic: GradeUtils.kt
This utility class centralizes the grading business rules:
- **90-100**: A
- **80-89**: B
- **70-79**: C
- **60-69**: D
- **Below 60**: F
- **Null**: "No Grade"

## 4. Lifecycle & State Management
By using `LiveData` and `Flow`, the app is **Reactive**. When you import 10 students from an Excel file, the database updates, the ViewModel detects the change, and the UI (Results & Stats) refreshes automatically without any "reload" button.
