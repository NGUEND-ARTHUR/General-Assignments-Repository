package com.example.gradecalculator.utils

import android.content.Context
import android.net.Uri
import com.example.gradecalculator.model.Student
import org.apache.poi.ss.usermodel.WorkbookFactory
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import java.io.InputStream
import java.io.OutputStream

object ExcelUtils {
    fun parseStudentsFromExcel(context: Context, uri: Uri): List<Student> {
        val students = mutableListOf<Student>()
        var inputStream: InputStream? = null
        try {
            inputStream = context.contentResolver.openInputStream(uri)
            val workbook = WorkbookFactory.create(inputStream)
            val sheet = workbook.getSheetAt(0)
            
            // Assuming 1st column is name and 2nd is score
            for (row in sheet) {
                if (row.rowNum == 0) continue // Skip header
                
                val name = row.getCell(0)?.toString() ?: ""
                val scoreStr = row.getCell(1)?.toString() ?: ""
                val score = scoreStr.toDoubleOrNull()
                
                if (name.isNotEmpty()) {
                    val grade = GradeUtils.calculateGrade(score)
                    students.add(Student(name = name, score = score, grade = grade))
                }
            }
            workbook.close()
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            inputStream?.close()
        }
        return students
    }

    fun exportStudentsToExcel(context: Context, uri: Uri, students: List<Student>) {
        var outputStream: OutputStream? = null
        try {
            val workbook = XSSFWorkbook()
            val sheet = workbook.createSheet("Students")
            
            // Header
            val headerRow = sheet.createRow(0)
            headerRow.createCell(0).setCellValue("Name")
            headerRow.createCell(1).setCellValue("Score")
            headerRow.createCell(2).setCellValue("Grade")
            
            // Data
            students.forEachIndexed { index, student ->
                val row = sheet.createRow(index + 1)
                row.createCell(0).setCellValue(student.name)
                student.score?.let {
                    row.createCell(1).setCellValue(it)
                } ?: run {
                    row.createCell(1).setCellValue("No score")
                }
                row.createCell(2).setCellValue(student.grade)
            }
            
            outputStream = context.contentResolver.openOutputStream(uri)
            workbook.write(outputStream)
            workbook.close()
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            outputStream?.close()
        }
    }

    fun createTestExcelFile(context: Context, uri: Uri) {
        val testStudents = listOf(
            Student(name = "Alice Johnson", score = 95.0, grade = "A"),
            Student(name = "Bob Smith", score = 82.0, grade = "B"),
            Student(name = "Charlie Brown", score = 74.0, grade = "C"),
            Student(name = "Daisy Miller", score = 68.0, grade = "D"),
            Student(name = "Ethan Hunt", score = 55.0, grade = "F"),
            Student(name = "Fiona Gallagher", score = null, grade = "No Grade"),
            Student(name = "George Costanza", score = 40.0, grade = "F"),
            Student(name = "Hannah Abbott", score = 91.0, grade = "A"),
            Student(name = "Ian Wright", score = 88.0, grade = "B"),
            Student(name = "Julia Roberts", score = 77.0, grade = "C")
        )
        exportStudentsToExcel(context, uri, testStudents)
    }
}
