package com.nguendarthurjohann.focusflow.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "plants")
data class PlantEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val type: String,
    val growthStage: Int, // 0 to 100
    val plantedAt: Long
)
