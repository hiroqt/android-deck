package com.macdeck.client.ui.deck

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.macdeck.client.core.network.ConnectionState
import com.macdeck.client.ui.theme.*

@Composable
fun ConnectionBar(
    connectionState: ConnectionState,
    currentHost: String,
    isUsbMode: Boolean,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier
) {
    val statusColor = when (connectionState) {
        ConnectionState.CONNECTED -> DeckSuccess
        ConnectionState.CONNECTING, ConnectionState.RECONNECTING -> DeckWarning
        ConnectionState.DISCONNECTED -> TextDisabled
    }

    val statusText = when (connectionState) {
        ConnectionState.CONNECTED -> if (isUsbMode) "USB Connected" else "LAN Connected"
        ConnectionState.CONNECTING -> "Connecting..."
        ConnectionState.RECONNECTING -> "Reconnecting..."
        ConnectionState.DISCONNECTED -> "Disconnected"
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        // Status indicator and mode label
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .clip(RoundedCornerShape(12.dp))
                .clickable { onOpenSettings() }
                .padding(horizontal = 10.dp, vertical = 6.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(10.dp)
                    .clip(CircleShape)
                    .background(statusColor)
            )

            Spacer(modifier = Modifier.width(8.dp))

            Text(
                text = "$statusText • $currentHost",
                color = TextSecondary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            )
        }

        // Settings gear button
        IconButton(
            onClick = onOpenSettings,
            modifier = Modifier.size(32.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Settings,
                contentDescription = "Connection Settings",
                tint = TextSecondary,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}
