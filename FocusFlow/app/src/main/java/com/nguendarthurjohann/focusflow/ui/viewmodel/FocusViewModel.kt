package com.nguendarthurjohann.focusflow.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class FocusViewModel @Inject constructor() : ViewModel() {
    private val _timerValue = MutableStateFlow("25:00")
    val timerValue = _timerValue.asStateFlow()

    private val _isTimerRunning = MutableStateFlow(false)
    val isTimerRunning = _isTimerRunning.asStateFlow()

    private val _seeds = MutableStateFlow(0)
    val seeds = _seeds.asStateFlow()

    private var timerJob: Job? = null
    private var secondsLeft = 25 * 60

    fun startTimer() {
        if (_isTimerRunning.value) return
        _isTimerRunning.value = true
        timerJob = viewModelScope.launch {
            while (secondsLeft > 0) {
                delay(1000L)
                secondsLeft--
                _timerValue.value = formatTime(secondsLeft)
            }
            _isTimerRunning.value = false
            _seeds.value += 10 // Earn seeds after session
        }
    }

    fun pauseTimer() {
        timerJob?.cancel()
        _isTimerRunning.value = false
    }

    private fun formatTime(seconds: Int): String {
        val minutes = seconds / 60
        val remainingSeconds = seconds % 60
        return "%02d:%02d".format(minutes, remainingSeconds)
    }
}
