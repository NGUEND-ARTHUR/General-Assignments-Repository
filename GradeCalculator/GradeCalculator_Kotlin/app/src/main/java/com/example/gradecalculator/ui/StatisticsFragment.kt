package com.example.gradecalculator.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.example.gradecalculator.databinding.FragmentStatisticsBinding
import com.example.gradecalculator.viewmodel.StudentViewModel

class StatisticsFragment : Fragment() {

    private var _binding: FragmentStatisticsBinding? = null
    private val binding get() = _binding!!
    private val viewModel: StudentViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentStatisticsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        viewModel.averageScore.observe(viewLifecycleOwner) {
            binding.tvAverage.text = String.format("%.2f", it)
        }

        viewModel.highestScore.observe(viewLifecycleOwner) {
            binding.tvHighest.text = String.format("%.2f", it)
        }

        viewModel.lowestScore.observe(viewLifecycleOwner) {
            binding.tvLowest.text = String.format("%.2f", it)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
