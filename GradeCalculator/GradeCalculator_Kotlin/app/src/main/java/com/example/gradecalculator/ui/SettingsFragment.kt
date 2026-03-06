package com.example.gradecalculator.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.example.gradecalculator.databinding.FragmentSettingsBinding
import com.example.gradecalculator.viewmodel.StudentViewModel

class SettingsFragment : Fragment() {

    private var _binding: FragmentSettingsBinding? = null
    private val binding get() = _binding!!
    private val viewModel: StudentViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentSettingsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.btnEnglish.setOnClickListener {
            Toast.makeText(requireContext(), "Language changed to English", Toast.LENGTH_SHORT).show()
            // Logic for locale change would be implemented here
        }

        binding.btnFrench.setOnClickListener {
            Toast.makeText(requireContext(), "Langue changée en Français", Toast.LENGTH_SHORT).show()
            // Logic for locale change would be implemented here
        }

        binding.btnClearData.setOnClickListener {
            AlertDialog.Builder(requireContext())
                .setTitle("Clear All Data?")
                .setMessage("This action cannot be undone.")
                .setPositiveButton("Clear") { _, _ ->
                    viewModel.clearAll()
                    Toast.makeText(requireContext(), "All records cleared", Toast.LENGTH_SHORT).show()
                }
                .setNegativeButton("Cancel", null)
                .show()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
