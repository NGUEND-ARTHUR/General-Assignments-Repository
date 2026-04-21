package com.example.gradecalculator.viewmodel

import android.app.Application
import androidx.lifecycle.*
import com.example.gradecalculator.data.AppDatabase
import com.example.gradecalculator.model.Student
import com.example.gradecalculator.utils.GradeUtils
import kotlinx.coroutines.launch
import androidx.lifecycle.asLiveData

class StudentViewModel(application: Application) : AndroidViewModel(application) {
    private val studentDao = AppDatabase.getDatabase(application).studentDao()
    val allStudents: LiveData<List<Student>> = studentDao.getAllStudents().asLiveData()

    fun addStudent(name: String, score: Double?) {
        val grade = GradeUtils.calculateGrade(score)
        val student = Student(name = name, score = score, grade = grade)
        viewModelScope.launch {
            studentDao.insertStudent(student)
        }
    }

    fun updateStudent(student: Student, newName: String, newScore: Double?) {
        val newGrade = GradeUtils.calculateGrade(newScore)
        val updatedStudent = student.copy(name = newName, score = newScore, grade = newGrade)
        viewModelScope.launch {
            studentDao.updateStudent(updatedStudent)
        }
    }

    fun deleteStudent(student: Student) {
        viewModelScope.launch {
            studentDao.deleteStudent(student)
        }
    }

    fun addAll(students: List<Student>) {
        viewModelScope.launch {
            studentDao.insertAll(students)
        }
    }

    fun clearAll() {
        viewModelScope.launch {
            studentDao.deleteAll()
        }
    }

    val averageScore: LiveData<Double> = allStudents.map { students ->
        val validScores = students.mapNotNull { it.score }
        if (validScores.isEmpty()) 0.0 else validScores.average()
    }

    val highestScore: LiveData<Double> = allStudents.map { students ->
        students.mapNotNull { it.score }.maxOfOrNull { it } ?: 0.0
    }

    val lowestScore: LiveData<Double> = allStudents.map { students ->
        students.mapNotNull { it.score }.minOfOrNull { it } ?: 0.0
    }
}
