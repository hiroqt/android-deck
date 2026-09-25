package com.macdeck.client.ui.deck

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.macdeck.client.ui.theme.*

@Composable
fun ConnectionDialog(
    currentHost: String,
    isUsbMode: Boolean,
    errorMessage: String? = null,
    onConnectUsb: () -> Unit,
    onConnectLan: (String) -> Unit,
    onDismiss: () -> Unit
) {
    var lanIpInput by remember { mutableStateOf(if (!isUsbMode && currentHost != "127.0.0.1") currentHost else "192.168.1.3") }
    var selectedTab by remember { mutableStateOf(if (isUsbMode) 0 else 1) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = DeckSurface),
            border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(DeckSurfaceBorder)),
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "MacDeck Connection",
                    color = TextPrimary,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Tab Selector: Wi-Fi (LAN) vs USB
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(DeckBackground)
                        .padding(4.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (selectedTab == 1) DeckAccent else DeckBackground)
                            .clickable { selectedTab = 1 }
                            .padding(vertical = 8.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "📡 Wi-Fi (LAN)",
                            color = if (selectedTab == 1) TextPrimary else TextSecondary,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 13.sp
                        )
                    }

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (selectedTab == 0) DeckAccent else DeckBackground)
                            .clickable { selectedTab = 0 }
                            .padding(vertical = 8.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "🔌 USB Cable",
                            color = if (selectedTab == 0) TextPrimary else TextSecondary,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 13.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                if (!errorMessage.isNullOrBlank()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(DeckError.copy(alpha = 0.15f))
                            .border(1.dp, DeckError.copy(alpha = 0.4f), RoundedCornerShape(10.dp))
                            .padding(10.dp)
                    ) {
                        Text(
                            text = "⚠️ $errorMessage",
                            color = DeckError,
                            fontSize = 12.sp,
                            lineHeight = 16.sp
                        )
                    }
                    Spacer(modifier = Modifier.height(14.dp))
                }

                if (selectedTab == 1) {
                    // LAN Mode Input
                    Text(
                        text = "Enter your Mac's IP address (shown on MacDeck terminal):",
                        color = TextSecondary,
                        fontSize = 13.sp,
                        modifier = Modifier.align(Alignment.Start)
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedTextField(
                        value = lanIpInput,
                        onValueChange = { lanIpInput = it },
                        singleLine = true,
                        placeholder = { Text("e.g. 192.168.1.3") },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = DeckAccent,
                            unfocusedBorderColor = DeckSurfaceBorder,
                            focusedTextColor = TextPrimary,
                            unfocusedTextColor = TextPrimary,
                            cursorColor = DeckAccent
                        ),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(18.dp))

                    Button(
                        onClick = {
                            if (lanIpInput.isNotBlank()) {
                                onConnectLan(lanIpInput.trim())
                                onDismiss()
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = DeckAccent),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Connect via Wi-Fi", fontWeight = FontWeight.Bold)
                    }
                } else {
                    // USB Mode Description
                    Text(
                        text = "Connects via USB reverse tunnel (127.0.0.1:8765).\nRequires USB Debugging and running ./scripts/usb/connect.sh on your Mac.",
                        color = TextSecondary,
                        fontSize = 13.sp,
                        lineHeight = 18.sp
                    )

                    Spacer(modifier = Modifier.height(18.dp))

                    Button(
                        onClick = {
                            onConnectUsb()
                            onDismiss()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = DeckAccent),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Connect via USB", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}
