package com.macdeck.client.ui.deck

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.macdeck.client.core.model.DeckControl
import com.macdeck.client.core.network.ConnectionState
import com.macdeck.client.core.network.DeckWebSocketClient
import com.macdeck.client.ui.theme.DeckBackground
import com.macdeck.client.ui.theme.TextDisabled

@Composable
fun DeckScreen(
    client: DeckWebSocketClient,
    modifier: Modifier = Modifier
) {
    val connectionState by client.connectionState.collectAsState()
    val currentProfile by client.currentProfile.collectAsState()
    val tileStates by client.tileStates.collectAsState()

    var isUsbMode by remember { mutableStateOf(true) }
    var currentHost by remember { mutableStateOf("127.0.0.1") }
    var showDialog by remember { mutableStateOf(false) }

    // Connect initially using USB mode
    LaunchedEffect(Unit) {
        client.connect(currentHost, 8765)
    }

    // Default starter placeholders if no profile received yet
    val displayControls = remember(currentProfile) {
        currentProfile?.controls?.take(6) ?: listOf(
            DeckControl("app-1", "VS Code", "com.microsoft.VSCode"),
            DeckControl("app-2", "Terminal", "com.apple.Terminal"),
            DeckControl("app-3", "Chrome", "com.google.Chrome"),
            DeckControl("app-4", "Finder", "com.apple.finder"),
            DeckControl("app-5", "Settings", "com.apple.systempreferences"),
            DeckControl("app-6", "Music", "com.apple.Music")
        )
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(DeckBackground)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Top Compact Connection Bar
            ConnectionBar(
                connectionState = connectionState,
                currentHost = currentHost,
                isUsbMode = isUsbMode,
                onOpenSettings = { showDialog = true }
            )

            // Main Adaptive Full-Screen Deck Grid
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
            ) {
                AdaptiveDeckGrid(
                    controls = displayControls,
                    tileStates = tileStates,
                    onControlTap = { controlId ->
                        client.sendActionInvoke(controlId, "tap")
                    }
                )
            }
        }

        // Connection Selector Dialog
        if (showDialog) {
            ConnectionDialog(
                currentHost = currentHost,
                isUsbMode = isUsbMode,
                onConnectUsb = {
                    isUsbMode = true
                    currentHost = "127.0.0.1"
                    client.connect(currentHost, 8765)
                },
                onConnectLan = { ip ->
                    isUsbMode = false
                    currentHost = ip
                    client.connect(currentHost, 8765)
                },
                onDismiss = { showDialog = false }
            )
        }
    }
}
