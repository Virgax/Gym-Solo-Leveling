package com.virgax.arise

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.virgax.arise.ui.AriseApp
import com.virgax.arise.ui.theme.AriseTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AriseTheme {
                AriseApp()
            }
        }
    }
}
