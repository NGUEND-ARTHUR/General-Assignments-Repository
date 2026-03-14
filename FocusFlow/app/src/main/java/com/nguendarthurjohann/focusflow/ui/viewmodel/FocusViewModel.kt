package com.nguendarthurjohann.focusflow.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nguendarthurjohann.focusflow.utils.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class FocusViewModel @Inject constructor() : ViewModel() {
    // State Hoisting: Exposing state via Flow
    private val _timerState = MutableStateFlow<Resource<String>>(Resource.Success("25:00"))
    val timerState = _timerState.asStateFlow()

    private val _isTimerRunning = MutableStateFlow(false)
    val isTimerRunning = _isTimerRunning.asStateFlow()

    private val _seeds = MutableStateFlow(0)
    val seeds = _seeds.asStateFlow()

    private var timerJob: Job? = null
    private var secondsLeft = 25 * 60

    fun startTimer() {
        if (_isTimerRunning.value) return
        _isTimerRunning.value = true
        _timerState.value = Resource.Loading()
        
        timerJob = viewModelScope.launch {
            while (secondsLeft > 0) {
                delay(1000L)
                secondsLeft--
                _timerState.value = Resource.Success(formatTime(secondsLeft))
            }
            _isTimerRunning.value = false
            _seeds.value += 10
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
