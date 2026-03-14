package com.nguendarthurjohann.focusflow.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.PlaylistAddCheck
import androidx.compose.material.icons.filled.Timer
import androidx.compose.ui.graphics.vector.ImageVector

sealed class Screen(val route: String, val title: String, val icon: ImageVector) {
    object Dashboard : Screen("dashboard", "Dashboard", Icons.Default.Dashboard)
    object Focus : Screen("focus", "Focus", Icons.Default.Timer)
    object Tasks : Screen("tasks", "Tasks", Icons.Default.PlaylistAddCheck)
    object Social : Screen("social", "Social", Icons.Default.Group)
}
