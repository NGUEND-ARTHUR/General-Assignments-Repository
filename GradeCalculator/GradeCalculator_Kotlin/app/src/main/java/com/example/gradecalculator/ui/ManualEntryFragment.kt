package com.example.gradecalculator.ui

import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.example.gradecalculator.databinding.FragmentManualEntryBinding
import com.example.gradecalculator.utils.ExcelUtils
import com.example.gradecalculator.viewmodel.StudentViewModel

class ManualEntryFragment : Fragment() {

    private var _binding: FragmentManualEntryBinding? = null
    private val binding get() = _binding!!
    private val viewModel: StudentViewModel by viewModels()

    private val importExcelLauncher = registerForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        uri?.let {
            val students = ExcelUtils.parseStudentsFromExcel(requireContext(), it)
            if (students.isNotEmpty()) {
                viewModel.addAll(students)
                Toast.makeText(requireContext(), "Imported ${students.size} students!", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(requireContext(), "No students found or invalid file.", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private val createTestFileLauncher = registerForActivityResult(ActivityResultContracts.CreateDocument("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")) { uri: Uri? ->
        uri?.let {
            ExcelUtils.createTestExcelFile(requireContext(), it)
            Toast.makeText(requireContext(), "Test file created successfully!", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentManualEntryBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.btnCalculate.setOnClickListener {
            val name = binding.etName.text.toString()
            val scoreStr = binding.etScore.text.toString()

            if (name.isEmpty()) {
                Toast.makeText(requireContext(), "Please enter a name", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val score = if (scoreStr.isNotEmpty()) scoreStr.toDoubleOrNull() else null

            if (scoreStr.isNotEmpty() && (score == null || score < 0 || score > 100)) {
                Toast.makeText(requireContext(), "Enter a valid score (0-100)", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            viewModel.addStudent(name, score)
            binding.etName.text?.clear()
            binding.etScore.text?.clear()
            Toast.makeText(requireContext(), "Student added!", Toast.LENGTH_SHORT).show()
        }

        binding.btnImportExcel.setOnClickListener {
            importExcelLauncher.launch("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        }

        binding.btnCreateTestFile.setOnClickListener {
            createTestFileLauncher.launch("test_students.xlsx")
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
