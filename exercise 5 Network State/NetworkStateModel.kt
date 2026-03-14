package exercise_5_network_state

/**
 * Exercise 5: Model Network Request State with Sealed Class
 * 
 * Task:
 * Define a sealed class NetworkState representing:
 * Loading
 * Success(data: String)
 * Error(message: String)
 */

sealed class NetworkState {
    object Loading : NetworkState()
    data class Success(val data: String) : NetworkState()
    data class Error(val message: String) : NetworkState()
}

fun handleState(state: NetworkState) {
    when (state) {
        is NetworkState.Loading -> println("Status: Loading...")
        is NetworkState.Success -> println("Success: ${state.data}")
        is NetworkState.Error -> println("Error: ${state.message}")
    }
}

fun main() {
    val states = listOf(
        NetworkState.Loading,
        NetworkState.Success("User data loaded"),
        NetworkState.Error("Network timeout")
    )
    
    states.forEach { handleState(it) }
}
