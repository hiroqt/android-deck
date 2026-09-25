package com.macdeck.client.ui.deck

import android.view.HapticFeedbackConstants
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.*
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.macdeck.client.core.network.DeckWebSocketClient
import com.macdeck.client.ui.theme.*

@Composable
fun ControlPanelView(
    client: DeckWebSocketClient,
    modifier: Modifier = Modifier
) {
    val view = LocalView.current

    var isBluetoothOn by remember { mutableStateOf(true) }
    var isWifiOn by remember { mutableStateOf(true) }
    var volume by remember { mutableFloatStateOf(0.75f) }
    var brightness by remember { mutableFloatStateOf(0.80f) }

    val audioDevices = remember {
        listOf(
            "MacBook Air Speakers",
            "AirPods Pro",
            "PERSONA 2006",
            "DisplayPort (External)",
            "Headphones (3.5mm)"
        )
    }
    var selectedAudioDevice by remember { mutableStateOf(audioDevices[0]) }
    var showDeviceDialog by remember { mutableStateOf(false) }

    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        val isLandscape = maxWidth > maxHeight

        if (isLandscape) {
            // Landscape layout: 2 equal columns
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(bottom = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Left Column: Toggles + Brightness
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight(),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Top Row: Bluetooth & Wi-Fi
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        ToggleTile(
                            title = "Bluetooth",
                            subtitle = if (isBluetoothOn) "On" else "Off",
                            icon = if (isBluetoothOn) Icons.Rounded.Bluetooth else Icons.Rounded.BluetoothDisabled,
                            isActive = isBluetoothOn,
                            activeColor = DeckAccent,
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            onToggle = {
                                isBluetoothOn = !isBluetoothOn
                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                client.sendActionInvoke("sys_bluetooth", if (isBluetoothOn) "on" else "off")
                            }
                        )

                        ToggleTile(
                            title = "Wi-Fi",
                            subtitle = if (isWifiOn) "Connected" else "Off",
                            icon = if (isWifiOn) Icons.Rounded.Wifi else Icons.Rounded.WifiOff,
                            isActive = isWifiOn,
                            activeColor = DeckSuccess,
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            onToggle = {
                                isWifiOn = !isWifiOn
                                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                                client.sendActionInvoke("sys_wifi", if (isWifiOn) "on" else "off")
                            }
                        )
                    }

                    // Brightness Card
                    BrightnessControlCard(
                        brightness = brightness,
                        onBrightnessChange = { brightness = it },
                        onBrightnessChangeFinished = {
                            client.sendActionInvoke("sys_brightness", "set:${(brightness * 100).toInt()}")
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1.1f)
                    )
                }

                // Right Column: Volume + Output Device Selector
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                ) {
                    VolumeControlCard(
                        volume = volume,
                        selectedDevice = selectedAudioDevice,
                        onVolumeChange = { volume = it },
                        onVolumeChangeFinished = {
                            client.sendActionInvoke("sys_volume", "set:${(volume * 100).toInt()}")
                        },
                        onSelectDeviceClick = {
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            showDeviceDialog = true
                        },
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        } else {
            // Portrait layout: Vertical stack
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(bottom = 12.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Row: Bluetooth & Wi-Fi Toggles
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(96.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    ToggleTile(
                        title = "Bluetooth",
                        subtitle = if (isBluetoothOn) "On" else "Off",
                        icon = if (isBluetoothOn) Icons.Rounded.Bluetooth else Icons.Rounded.BluetoothDisabled,
                        isActive = isBluetoothOn,
                        activeColor = DeckAccent,
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight(),
                        onToggle = {
                            isBluetoothOn = !isBluetoothOn
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            client.sendActionInvoke("sys_bluetooth", if (isBluetoothOn) "on" else "off")
                        }
                    )

                    ToggleTile(
                        title = "Wi-Fi",
                        subtitle = if (isWifiOn) "Connected" else "Off",
                        icon = if (isWifiOn) Icons.Rounded.Wifi else Icons.Rounded.WifiOff,
                        isActive = isWifiOn,
                        activeColor = DeckSuccess,
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight(),
                        onToggle = {
                            isWifiOn = !isWifiOn
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            client.sendActionInvoke("sys_wifi", if (isWifiOn) "on" else "off")
                        }
                    )
                }

                // Volume Card with Audio Device Selector
                VolumeControlCard(
                    volume = volume,
                    selectedDevice = selectedAudioDevice,
                    onVolumeChange = { volume = it },
                    onVolumeChangeFinished = {
                        client.sendActionInvoke("sys_volume", "set:${(volume * 100).toInt()}")
                    },
                    onSelectDeviceClick = {
                        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                        showDeviceDialog = true
                    },
                    modifier = Modifier.fillMaxWidth()
                )

                // Brightness Card
                BrightnessControlCard(
                    brightness = brightness,
                    onBrightnessChange = { brightness = it },
                    onBrightnessChangeFinished = {
                        client.sendActionInvoke("sys_brightness", "set:${(brightness * 100).toInt()}")
                    },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }

    // Audio Output Device Selection Dialog
    if (showDeviceDialog) {
        AudioDeviceDialog(
            devices = audioDevices,
            selectedDevice = selectedAudioDevice,
            onSelectDevice = { device ->
                selectedAudioDevice = device
                showDeviceDialog = false
                view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                client.sendActionInvoke("sys_audio_device", "select:$device")
            },
            onDismiss = { showDeviceDialog = false }
        )
    }
}

@Composable
private fun ToggleTile(
    title: String,
    subtitle: String,
    icon: ImageVector,
    isActive: Boolean,
    activeColor: Color,
    modifier: Modifier = Modifier,
    onToggle: () -> Unit
) {
    var isPressed by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.94f else 1.0f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = 600f),
        label = "toggle_scale"
    )

    val backgroundColor by animateColorAsState(
        targetValue = if (isActive) activeColor.copy(alpha = 0.16f) else DeckSurface,
        label = "toggle_bg"
    )

    val borderColor by animateColorAsState(
        targetValue = if (isActive) activeColor.copy(alpha = 0.55f) else DeckSurfaceBorder,
        label = "toggle_border"
    )

    Box(
        modifier = modifier
            .scale(scale)
            .clip(RoundedCornerShape(22.dp))
            .background(backgroundColor)
            .border(
                width = if (isActive) 1.5.dp else 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(22.dp)
            )
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                        onToggle()
                    }
                )
            }
            .padding(14.dp),
        contentAlignment = Alignment.CenterStart
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(if (isActive) activeColor else DeckSurfaceBorder.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = title,
                    tint = if (isActive) Color.White else TextSecondary,
                    modifier = Modifier.size(22.dp)
                )
            }

            Column(verticalArrangement = Arrangement.Center) {
                Text(
                    text = title,
                    color = TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = subtitle,
                    color = if (isActive) activeColor else TextSecondary,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

@Composable
private fun VolumeControlCard(
    volume: Float,
    selectedDevice: String,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinished: () -> Unit,
    onSelectDeviceClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(22.dp))
            .background(DeckSurface)
            .border(1.dp, DeckSurfaceBorder, RoundedCornerShape(22.dp))
            .padding(16.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Header Row: Icon, Title, Percentage
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val volIcon = when {
                        volume <= 0.01f -> Icons.AutoMirrored.Rounded.VolumeMute
                        volume < 0.5f -> Icons.AutoMirrored.Rounded.VolumeDown
                        else -> Icons.AutoMirrored.Rounded.VolumeUp
                    }
                    Icon(
                        imageVector = volIcon,
                        contentDescription = "Volume",
                        tint = DeckAccent,
                        modifier = Modifier.size(20.dp)
                    )
                    Text(
                        text = "Volume",
                        color = TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Text(
                    text = "${(volume * 100).toInt()}%",
                    color = TextSecondary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            // Volume Slider
            Slider(
                value = volume,
                onValueChange = onVolumeChange,
                onValueChangeFinished = onVolumeChangeFinished,
                colors = SliderDefaults.colors(
                    thumbColor = TextPrimary,
                    activeTrackColor = DeckAccent,
                    inactiveTrackColor = DeckSurfaceBorder
                ),
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(4.dp))

            // Audio Output Device Selector Row
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(DeckBackground.copy(alpha = 0.7f))
                    .border(1.dp, DeckSurfaceBorder.copy(alpha = 0.8f), RoundedCornerShape(14.dp))
                    .clickable { onSelectDeviceClick() }
                    .padding(horizontal = 12.dp, vertical = 10.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        val deviceIcon = if (selectedDevice.contains("Headphone", ignoreCase = true) ||
                            selectedDevice.contains("AirPod", ignoreCase = true)
                        ) {
                            Icons.Rounded.Headphones
                        } else {
                            Icons.Rounded.Speaker
                        }

                        Icon(
                            imageVector = deviceIcon,
                            contentDescription = "Audio Device",
                            tint = DeckAccent,
                            modifier = Modifier.size(16.dp)
                        )

                        Column {
                            Text(
                                text = "Output Device",
                                color = TextSecondary,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Normal
                            )
                            Text(
                                text = selectedDevice,
                                color = TextPrimary,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }

                    Icon(
                        imageVector = Icons.Rounded.UnfoldMore,
                        contentDescription = "Select Device",
                        tint = TextSecondary,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun BrightnessControlCard(
    brightness: Float,
    onBrightnessChange: (Float) -> Unit,
    onBrightnessChangeFinished: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(22.dp))
            .background(DeckSurface)
            .border(1.dp, DeckSurfaceBorder, RoundedCornerShape(22.dp))
            .padding(16.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Header Row: Icon, Title, Percentage
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Rounded.LightMode,
                        contentDescription = "Brightness",
                        tint = DeckWarning,
                        modifier = Modifier.size(20.dp)
                    )
                    Text(
                        text = "Brightness",
                        color = TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Text(
                    text = "${(brightness * 100).toInt()}%",
                    color = TextSecondary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Brightness Slider
            Slider(
                value = brightness,
                onValueChange = onBrightnessChange,
                onValueChangeFinished = onBrightnessChangeFinished,
                colors = SliderDefaults.colors(
                    thumbColor = TextPrimary,
                    activeTrackColor = DeckWarning,
                    inactiveTrackColor = DeckSurfaceBorder
                ),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun AudioDeviceDialog(
    devices: List<String>,
    selectedDevice: String,
    onSelectDevice: (String) -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Box(
            modifier = Modifier
                .width(320.dp)
                .clip(RoundedCornerShape(24.dp))
                .background(DeckSurface)
                .border(1.dp, DeckSurfaceBorder, RoundedCornerShape(24.dp))
                .padding(20.dp)
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                // Title
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(
                            text = "Audio Output Device",
                            color = TextPrimary,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Select output for Mac audio",
                            color = TextSecondary,
                            fontSize = 11.sp
                        )
                    }

                    IconButton(
                        onClick = onDismiss,
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Close,
                            contentDescription = "Close",
                            tint = TextSecondary,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }

                HorizontalDivider(color = DeckSurfaceBorder, thickness = 1.dp)

                // List of Devices
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    devices.forEach { device ->
                        val isSelected = device == selectedDevice
                        val deviceIcon = if (device.contains("Headphone", ignoreCase = true) ||
                            device.contains("AirPod", ignoreCase = true)
                        ) {
                            Icons.Rounded.Headphones
                        } else {
                            Icons.Rounded.Speaker
                        }

                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(14.dp))
                                .background(if (isSelected) DeckAccent.copy(alpha = 0.16f) else DeckBackground)
                                .border(
                                    width = if (isSelected) 1.5.dp else 1.dp,
                                    color = if (isSelected) DeckAccent else DeckSurfaceBorder,
                                    shape = RoundedCornerShape(14.dp)
                                )
                                .clickable { onSelectDevice(device) }
                                .padding(horizontal = 14.dp, vertical = 12.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    Icon(
                                        imageVector = deviceIcon,
                                        contentDescription = null,
                                        tint = if (isSelected) DeckAccent else TextSecondary,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Text(
                                        text = device,
                                        color = if (isSelected) TextPrimary else TextSecondary,
                                        fontSize = 13.sp,
                                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
                                    )
                                }

                                if (isSelected) {
                                    Icon(
                                        imageVector = Icons.Rounded.Check,
                                        contentDescription = "Selected",
                                        tint = DeckAccent,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
