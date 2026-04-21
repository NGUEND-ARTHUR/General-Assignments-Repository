package com.example.gradecalculator.utils

import android.content.Context
import android.net.Uri
import com.example.gradecalculator.model.Student
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter

object CsvUtils {
    fun exportStudentsToCsv(context: Context, uri: Uri, students: List<Student>) {
        context.contentResolver.openOutputStream(uri)?.use { outputStream ->
            writeCsv(outputStream, students)
        }
        
        // Save to internal history
        val fileName = "grade_report_${System.currentTimeMillis()}.csv"
        val dir = File(context.getExternalFilesDir(null), "Exports")
        if (!dir.exists()) dir.mkdirs()
        val file = File(dir, fileName)
        FileOutputStream(file).use { out ->
            writeCsv(out, students)
        }
    }

    private fun writeCsv(outputStream: java.io.OutputStream, students: List<Student>) {
        OutputStreamWriter(outputStream).use { writer ->
            writer.write("Name,Score,Grade\n")
            students.forEach { student ->
                writer.write("${student.name},${student.score ?: ""},${student.grade}\n")
            }
        }
    }
}
