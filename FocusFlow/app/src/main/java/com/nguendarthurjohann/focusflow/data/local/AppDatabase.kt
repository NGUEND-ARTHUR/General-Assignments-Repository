package com.nguendarthurjohann.focusflow.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.nguendarthurjohann.focusflow.data.local.dao.TaskDao
import com.nguendarthurjohann.focusflow.data.local.entities.FocusLogEntity
import com.nguendarthurjohann.focusflow.data.local.entities.PlantEntity
import com.nguendarthurjohann.focusflow.data.local.entities.TaskEntity

@Database(
    entities = [TaskEntity::class, PlantEntity::class, FocusLogEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun taskDao(): TaskDao
}
