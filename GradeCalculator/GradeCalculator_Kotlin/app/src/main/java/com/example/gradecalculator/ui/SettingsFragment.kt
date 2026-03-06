package com.example.gradecalculator.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.example.gradecalculator.R
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
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("en"))
            Toast.makeText(requireContext(), "Language changed to English", Toast.LENGTH_SHORT).show()
        }

        binding.btnFrench.setOnClickListener {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("fr"))
            Toast.makeText(requireContext(), "Langue changée en Français", Toast.LENGTH_SHORT).show()
        }

        binding.btnClearData.setOnClickListener {
            AlertDialog.Builder(requireContext())
                .setTitle(getString(R.string.clear_data_title))
                .setMessage(getString(R.string.clear_data_message))
                .setPositiveButton(getString(R.string.clear)) { _, _ ->
                    viewModel.clearAll()
                    Toast.makeText(requireContext(), getString(R.string.records_cleared), Toast.LENGTH_SHORT).show()
                }
                .setNegativeButton(getString(R.string.cancel), null)
                .show()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
