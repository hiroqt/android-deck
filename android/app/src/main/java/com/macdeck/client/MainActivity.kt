package com.macdeck.client

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.macdeck.client.core.battery.BatteryMonitor
import com.macdeck.client.core.network.DeckWebSocketClient
import com.macdeck.client.ui.deck.DeckScreen
import com.macdeck.client.ui.theme.MacDeckTheme

class MainActivity : ComponentActivity() {

    private val client by lazy { DeckWebSocketClient() }
    private lateinit var batteryMonitor: BatteryMonitor

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize battery monitoring and hook to WebSocket client
        batteryMonitor = BatteryMonitor(this)
        client.batteryProvider = { batteryMonitor.getCurrentBatteryInfo() }
        batteryMonitor.startMonitoring { info ->
            client.sendBatteryUpdate(info)
        }

        // Keep screen awake while docked
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Immersive sticky fullscreen: hide status bar and navigation bar
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val insetsController = WindowInsetsControllerCompat(window, window.decorView)
        insetsController.hide(WindowInsetsCompat.Type.systemBars())
        insetsController.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE

        setContent {
            MacDeckTheme {
                DeckScreen(client = client)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        batteryMonitor.stopMonitoring()
        client.disconnect()
    }
}
