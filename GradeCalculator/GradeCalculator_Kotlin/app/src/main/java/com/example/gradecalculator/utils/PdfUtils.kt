package com.example.gradecalculator.utils

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import android.net.Uri
import com.example.gradecalculator.model.Student
import java.io.File
import java.io.FileOutputStream

object PdfUtils {
    fun exportStudentsToPdf(context: Context, uri: Uri, students: List<Student>) {
        val pdfDocument = createPdf(students)
        context.contentResolver.openOutputStream(uri)?.use { outputStream ->
            pdfDocument.writeTo(outputStream)
        }
        
        // Save to internal history
        val fileName = "grade_report_${System.currentTimeMillis()}.pdf"
        val dir = File(context.getExternalFilesDir(null), "Exports")
        if (!dir.exists()) dir.mkdirs()
        val file = File(dir, fileName)
        FileOutputStream(file).use { out ->
            pdfDocument.writeTo(out)
        }
        
        pdfDocument.close()
    }

    private fun createPdf(students: List<Student>): PdfDocument {
        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(595, 842, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas: Canvas = page.canvas
        val paint = Paint()
        val titlePaint = Paint().apply {
            textSize = 20f
            isFakeBoldText = true
        }

        var y = 40f
        canvas.drawText("Grade Report", 40f, y, titlePaint)
        y += 40f

        paint.textSize = 12f
        canvas.drawText("Name", 40f, y, paint)
        canvas.drawText("Score", 300f, y, paint)
        canvas.drawText("Grade", 450f, y, paint)
        y += 10f
        canvas.drawLine(40f, y, 550f, y, paint)
        y += 20f

        students.forEach { student ->
            if (y > 800) return@forEach 
            canvas.drawText(student.name, 40f, y, paint)
            canvas.drawText(student.score?.toString() ?: "N/A", 300f, y, paint)
            canvas.drawText(student.grade, 450f, y, paint)
            y += 20f
        }

        pdfDocument.finishPage(page)
        return pdfDocument
    }
}
