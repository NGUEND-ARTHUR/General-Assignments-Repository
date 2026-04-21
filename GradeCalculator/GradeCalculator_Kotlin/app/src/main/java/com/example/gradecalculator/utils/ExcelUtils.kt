package com.example.gradecalculator.utils

import android.content.Context
import android.net.Uri
import com.example.gradecalculator.model.Student
import org.apache.poi.ss.usermodel.WorkbookFactory
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import java.io.File
import java.io.FileOutputStream
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
            
            for (row in sheet) {
                if (row.rowNum == 0) continue 
                
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

    private fun generateWorkbook(students: List<Student>): XSSFWorkbook {
        val workbook = XSSFWorkbook()
        val sheet = workbook.createSheet("Students")
        val headerRow = sheet.createRow(0)
        headerRow.createCell(0).setCellValue("Name")
        headerRow.createCell(1).setCellValue("Score")
        headerRow.createCell(2).setCellValue("Grade")
        
        students.forEachIndexed { index, student ->
            val row = sheet.createRow(index + 1)
            row.createCell(0).setCellValue(student.name)
            student.score?.let { row.createCell(1).setCellValue(it) } ?: row.createCell(1).setCellValue("No score")
            row.createCell(2).setCellValue(student.grade)
        }
        return workbook
    }

    fun exportStudentsToExcel(context: Context, uri: Uri, students: List<Student>) {
        context.contentResolver.openOutputStream(uri)?.use { outputStream ->
            val workbook = generateWorkbook(students)
            workbook.write(outputStream)
            workbook.close()
        }
        saveToInternalHistory(context, "grade_report_${System.currentTimeMillis()}.xlsx", students)
    }

    private fun saveToInternalHistory(context: Context, fileName: String, students: List<Student>) {
        val dir = File(context.getExternalFilesDir(null), "Exports")
        if (!dir.exists()) dir.mkdirs()
        val file = File(dir, fileName)
        FileOutputStream(file).use { out ->
            val workbook = generateWorkbook(students)
            workbook.write(out)
            workbook.close()
        }
    }

    fun createTestExcelFile(context: Context, uri: Uri) {
        val testStudents = listOf(
            Student(name = "Alice Johnson", score = 95.0, grade = "A"),
            Student(name = "Bob Smith", score = 82.0, grade = "B"),
            Student(name = "Charlie Brown", score = 74.0, grade = "C")
        )
        exportStudentsToExcel(context, uri, testStudents)
    }
}
