package com.example.gradecalculator

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Input
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.gradecalculator.ui.screens.ManualEntryScreen
import com.example.gradecalculator.ui.screens.ResultsScreen
import com.example.gradecalculator.ui.screens.StatisticsScreen
import com.example.gradecalculator.ui.screens.SettingsScreen
import com.example.gradecalculator.ui.theme.GradeCalculatorTheme
import com.example.gradecalculator.viewmodel.StudentViewModel
import com.example.gradecalculator.utils.ExcelUtils
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            GradeCalculatorTheme {
                GradeCalculatorApp()
            }
        }
    }
}

sealed class Screen(val route: String, val label: String, val icon: ImageVector) {
    object ManualEntry : Screen("manual_entry", "Input", Icons.Default.Input)
    object Results : Screen("results", "Results", Icons.Default.History)
    object Statistics : Screen("statistics", "Stats", Icons.Default.BarChart)
    object Settings : Screen("settings", "Settings", Icons.Default.Settings)
}

@Composable
fun GradeCalculatorApp(viewModel: StudentViewModel = viewModel()) {
    val navController = rememberNavController()
    val context = LocalContext.current
    val items = listOf(
        Screen.ManualEntry,
        Screen.Results,
        Screen.Statistics,
        Screen.Settings
    )

    val students by viewModel.allStudents.observeAsState(initial = emptyList())
    val average by viewModel.averageScore.observeAsState(initial = 0.0)
    val highest by viewModel.highestScore.observeAsState(initial = 0.0)
    val lowest by viewModel.lowestScore.observeAsState(initial = 0.0)

    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination
                items.forEach { screen ->
                    NavigationBarItem(
                        icon = { Icon(screen.icon, contentDescription = null) },
                        label = { Text(screen.label) },
                        selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController, 
            startDestination = Screen.ManualEntry.route, 
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.ManualEntry.route) {
                ManualEntryScreen(
                    onCalculate = { name, score -> 
                        viewModel.addStudent(name, score)
                        navController.navigate(Screen.Results.route)
                    },
                    onImportExcel = { uri ->
                        val imported = ExcelUtils.parseStudentsFromExcel(context, uri)
                        viewModel.addAll(imported)
                        navController.navigate(Screen.Results.route)
                    },
                    onCreateTestFile = { uri ->
                        ExcelUtils.createTestExcelFile(context, uri)
                    }
                )
            }
            composable(Screen.Results.route) { 
                ResultsScreen(
                    students = students,
                    onExport = { uri ->
                        ExcelUtils.exportStudentsToExcel(context, uri, students)
                    },
                    onEdit = { student, newName, newScore -> 
                        viewModel.updateStudent(student, newName, newScore)
                    },
                    onDelete = { student -> viewModel.deleteStudent(student) }
                )
            }
            composable(Screen.Statistics.route) { 
                StatisticsScreen(
                    average = average,
                    highest = highest,
                    lowest = lowest
                )
            }
            composable(Screen.Settings.route) { 
                SettingsScreen(
                    onClearAll = { viewModel.clearAll() }
                )
            }
        }
    }
}
