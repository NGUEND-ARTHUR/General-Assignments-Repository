/**
 * PROJECT: Student Grade Calculator Mobile Application (Dart Version)
 * MILESTONE 3: Object-Oriented Domain Model
 * SUBMITTED BY: Arthur Johann
 * 
 * Objective: Refine the app's data model using OOP principles in Dart.
 */

// 1. Abstract class defining common behavior (Similar to Interface in Kotlin)
abstract class GradeReportable {
  String generateReport();
}

// 2. Base Abstract class representing "AcademicEntity"
abstract class AcademicEntity implements GradeReportable {
  final String name;

  AcademicEntity(this.name);

  // 3. Abstract property (getter in Dart) for identification type
  String get identificationType;

  // 4. Override toString() to provide a base string representation
  @override
  String toString() {
    return "[$identificationType] Name: $name";
  }
}

// 5. Concrete class implementation for Student (Similar to Kotlin Data Class)
// Note: Dart doesn't have "data classes", so we implement the constructor and toString manually.
class StudentEntity extends AcademicEntity {
  final int studentID;
  final double finalScore;
  final String letterGrade;

  StudentEntity({
    required String name,
    required this.studentID,
    required this.finalScore,
    required this.letterGrade,
  }) : super(name);

  @override
  String get identificationType => "STUDENT_ID: $studentID";

  // 6. Implementation of the abstract method
  @override
  String generateReport() {
    return "Academic Report for $name: Score = $finalScore, Grade = $letterGrade";
  }

  // 7. Manual override of toString() incorporating super
  @override
  String toString() {
    return "${super.toString()} | Result: $letterGrade";
  }

  // Dart equivalent of Kotlin's .copy() method
  StudentEntity copyWith({
    String? name,
    int? studentID,
    double? finalScore,
    String? letterGrade,
  }) {
    return StudentEntity(
      name: name ?? this.name,
      studentID: studentID ?? this.studentID,
      finalScore: finalScore ?? this.finalScore,
      letterGrade: letterGrade ?? this.letterGrade,
    );
  }
}

// 8. Another concrete subclass to demonstrate inheritance and polymorphism
class Instructor extends AcademicEntity {
  final String department;

  Instructor(String name, this.department) : super(name);

  @override
  String get identificationType => "FACULTY";

  @override
  String generateReport() {
    return "Instructor $name managing the $department department.";
  }
}

/**
 * Main function showcasing the OOP hierarchy, inheritance, and polymorphism in Dart.
 */
void main() {
  print("--- Milestone 3: Object-Oriented Domain Model Showcase (Dart) ---\n");

  // 9. Demonstrate Polymorphism: Storing different subclass instances in a collection
  final List<AcademicEntity> academicEntities = [
    StudentEntity(name: "Alice Johnson", studentID: 1001, finalScore: 92.5, letterGrade: "A"),
    StudentEntity(name: "Bob Smith", studentID: 1002, finalScore: 78.0, letterGrade: "B"),
    Instructor("Dr. Sarah Williams", "Computer Science"),
    StudentEntity(name: "Charlie Davis", studentID: 1003, finalScore: 65.4, letterGrade: "D"),
  ];

  // 10. Iterate and call overridden methods (Polymorphism in action)
  for (var entity in academicEntities) {
    print("Entity Info: $entity"); // Calls overridden toString()
    print("Action: ${entity.generateReport()}"); // Calls polymorphic generateReport()
    print("--------------------------------------------------");
  }

  // Showcase: Dart copyWith (equivalent to Kotlin data class .copy())
  final topStudent = StudentEntity(name: "Alice Johnson", studentID: 1001, finalScore: 92.5, letterGrade: "A");
  final updatedStudent = topStudent.copyWith(finalScore: 95.0);
  print("\nDart Feature (copyWith): Original = ${topStudent.finalScore}, Updated = ${updatedStudent.finalScore}");
}
