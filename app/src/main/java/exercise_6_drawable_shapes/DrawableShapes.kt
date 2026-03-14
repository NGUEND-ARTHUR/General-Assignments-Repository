package exercise_6_drawable_shapes

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Exercise 6: Drawable Shapes with Interfaces
 * 
 * Task:
 * Define an interface Drawable with a function draw().
 * Create classes Circle and Square that implement Drawable.
 * Each should have appropriate properties (radius, side length) and print a simple ASCII representation.
 */

interface Drawable {
    fun draw(): String
}

class Circle(val radius: Int) : Drawable {
    override fun draw(): String {
        return "   ***   \n *     * \n*       *\n *     * \n   ***   "
    }
}

class Square(val sideLength: Int) : Drawable {
    override fun draw(): String {
        return "*******\n*     *\n*     *\n*     *\n*******"
    }
}

@Composable
fun DrawableShapesScreen() {
    val circle = Circle(5)
    val square = Square(10)

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Drawable Shapes",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Interfaces & Implementations",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline
            )

            Spacer(modifier = Modifier.height(32.dp))

            ShapeCard(name = "Circle (radius: ${circle.radius})", ascii = circle.draw(), isCircle = true)
            
            Spacer(modifier = Modifier.height(24.dp))
            
            ShapeCard(name = "Square (side: ${square.sideLength})", ascii = square.draw(), isCircle = false)
        }
    }
}

@Composable
fun ShapeCard(name: String, ascii: String, isCircle: Boolean) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = name,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.align(Alignment.Start)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // ASCII Representation Box
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = Color.Black,
                shape = androidx.compose.foundation.shape.RoundedCornerShape(8.dp)
            ) {
                Text(
                    text = ascii,
                    color = Color.Green,
                    fontFamily = FontFamily.Monospace,
                    modifier = Modifier.padding(16.dp),
                    lineHeight = 20.sp,
                    fontSize = 18.sp
                )
            }
        }
    }
}
