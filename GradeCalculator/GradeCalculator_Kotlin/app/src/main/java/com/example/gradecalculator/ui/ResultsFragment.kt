package com.example.gradecalculator.ui

import android.app.AlertDialog
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.ImageButton
import android.widget.PopupMenu
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.RecyclerView
import com.example.gradecalculator.R
import com.example.gradecalculator.databinding.FragmentResultsBinding
import com.example.gradecalculator.model.Student
import com.example.gradecalculator.utils.ExcelUtils
import com.example.gradecalculator.utils.GradeUtils
import com.example.gradecalculator.viewmodel.StudentViewModel

class ResultsFragment : Fragment() {

    private var _binding: FragmentResultsBinding? = null
    private val binding get() = _binding!!
    private val viewModel: StudentViewModel by viewModels()

    private val exportExcelLauncher = registerForActivityResult(ActivityResultContracts.CreateDocument("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")) { uri: Uri? ->
        uri?.let {
            val students = viewModel.allStudents.value ?: emptyList()
            if (students.isNotEmpty()) {
                ExcelUtils.exportStudentsToExcel(requireContext(), it, students)
                Toast.makeText(requireContext(), "Results exported successfully!", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(requireContext(), "No data to export", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentResultsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val adapter = StudentAdapter { student, view ->
            showPopupMenu(view, student)
        }
        binding.rvStudents.adapter = adapter

        viewModel.allStudents.observe(viewLifecycleOwner) { students ->
            adapter.submitList(students)
        }

        binding.fabExport.setOnClickListener {
            if (viewModel.allStudents.value.isNullOrEmpty()) {
                Toast.makeText(requireContext(), "No students to export", Toast.LENGTH_SHORT).show()
            } else {
                exportExcelLauncher.launch("GradeResults.xlsx")
            }
        }
    }

    private fun showPopupMenu(view: View, student: Student) {
        val popup = PopupMenu(requireContext(), view)
        popup.menuInflater.inflate(R.menu.student_item_menu, popup.menu)
        popup.setOnMenuItemClickListener { menuItem ->
            when (menuItem.itemId) {
                R.id.action_edit -> {
                    showEditDialog(student)
                    true
                }
                R.id.action_delete -> {
                    viewModel.deleteStudent(student)
                    Toast.makeText(requireContext(), "Student deleted", Toast.LENGTH_SHORT).show()
                    true
                }
                else -> false
            }
        }
        popup.show()
    }

    private fun showEditDialog(student: Student) {
        val dialogView = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_edit_student, null)
        val etName = dialogView.findViewById<EditText>(R.id.etEditName)
        val etScore = dialogView.findViewById<EditText>(R.id.etEditScore)

        etName.setText(student.name)
        etScore.setText(student.score?.toString() ?: "")

        AlertDialog.Builder(requireContext())
            .setTitle("Edit Student")
            .setView(dialogView)
            .setPositiveButton("Update") { _, _ ->
                val newName = etName.text.toString()
                val scoreStr = etScore.text.toString()
                val newScore = if (scoreStr.isNotEmpty()) scoreStr.toDoubleOrNull() else null
                
                if (newName.isNotEmpty()) {
                    viewModel.updateStudent(student, newName, newScore)
                    Toast.makeText(requireContext(), "Student updated", Toast.LENGTH_SHORT).show()
                } else {
                    Toast.makeText(requireContext(), "Name cannot be empty", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    inner class StudentAdapter(private val onMenuClick: (Student, View) -> Unit) : RecyclerView.Adapter<StudentAdapter.ViewHolder>() {
        private var students: List<Student> = emptyList()

        fun submitList(list: List<Student>) {
            students = list
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val view = LayoutInflater.from(parent.context).inflate(R.layout.item_student, parent, false)
            return ViewHolder(view)
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            val student = students[position]
            holder.tvName.text = student.name
            holder.tvScore.text = "Score: ${GradeUtils.formatScore(student.score)}"
            holder.tvGrade.text = student.grade
            holder.btnMenu.setOnClickListener { onMenuClick(student, it) }
        }

        override fun getItemCount() = students.size

        inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            val tvName: TextView = view.findViewById(R.id.tvName)
            val tvScore: TextView = view.findViewById(R.id.tvScore)
            val tvGrade: TextView = view.findViewById(R.id.tvGrade)
            val btnMenu: ImageButton = view.findViewById(R.id.btnMenu)
        }
    }
}
