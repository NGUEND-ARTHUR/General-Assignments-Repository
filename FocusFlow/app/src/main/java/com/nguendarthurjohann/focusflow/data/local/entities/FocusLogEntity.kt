package com.nguendarthurjohann.focusflow.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "focus_logs")
data class FocusLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val date: Long, // Timestamp for the day
    val focusMinutes: Int,
    val sessionType: String // "Pomodoro", "Study Room", etc.
)
