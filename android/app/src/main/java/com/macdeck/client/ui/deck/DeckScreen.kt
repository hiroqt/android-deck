package com.macdeck.client.ui.deck

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.macdeck.client.core.model.DeckControl
import com.macdeck.client.core.network.ConnectionState
import com.macdeck.client.core.network.DeckWebSocketClient
import com.macdeck.client.core.network.NetworkGatewayUtils
import com.macdeck.client.ui.theme.*
import kotlinx.coroutines.launch

private const val PREFS_NAME = "notchdeck_settings"
private const val KEY_HOST = "saved_host"
private const val KEY_IS_USB = "saved_is_usb"

@Composable
fun DeckScreen(
    client: DeckWebSocketClient,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE) }

    val connectionState by client.connectionState.collectAsState()
    val currentProfile by client.currentProfile.collectAsState()
    val tileStates by client.tileStates.collectAsState()
    val lastError by client.lastErrorMessage.collectAsState()
    val isRefreshing by client.isRefreshing.collectAsState()

    var isUsbMode by remember {
        mutableStateOf(prefs.getBoolean(KEY_IS_USB, false))
    }
    var currentHost by remember {
        mutableStateOf(
            prefs.getString(KEY_HOST, null)?.takeIf { it.isNotBlank() }
                ?: NetworkGatewayUtils.getDhcpGatewayIp(context)
                ?: "192.168.1.3"
        )
    }
    var showDialog by remember { mutableStateOf(false) }
    var isSearchingHost by remember { mutableStateOf(false) }

    // Connect initially using saved host
    LaunchedEffect(currentHost, isUsbMode) {
        val targetHost = if (isUsbMode) "127.0.0.1" else currentHost
        client.connect(targetHost, NetworkGatewayUtils.WS_PORT)
    }

    // Auto-discover NotchDeck host on Wi-Fi if disconnected
    LaunchedEffect(connectionState, isUsbMode) {
        if (!isUsbMode && connectionState != ConnectionState.CONNECTED && currentProfile == null) {
            isSearchingHost = true
            val discovered = NetworkGatewayUtils.discoverMacHost(context)
            isSearchingHost = false
            if (discovered != null && discovered != currentHost) {
                currentHost = discovered
                prefs.edit().putString(KEY_HOST, discovered).apply()
                client.connect(discovered, NetworkGatewayUtils.WS_PORT)
            }
        }
    }

    // Default starter placeholders if no profile received yet
    val displayControls = remember(currentProfile) {
        currentProfile?.controls?.take(6) ?: listOf(
            DeckControl("app-1", "VS Code", "com.microsoft.VSCode"),
            DeckControl("app-2", "Terminal", "com.apple.Terminal"),
            DeckControl("app-3", "Safari", "com.apple.Safari"),
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
            // Top Compact Connection Bar with Refresh
            ConnectionBar(
                connectionState = connectionState,
                currentHost = if (isUsbMode) "127.0.0.1" else currentHost,
                isUsbMode = isUsbMode,
                onOpenSettings = { showDialog = true },
                onRefresh = { client.refreshProfile() },
                isRefreshing = isRefreshing
            )

            // Prominent notification banner if disconnected
            if (connectionState != ConnectionState.CONNECTED) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(
                            if (connectionState == ConnectionState.RECONNECTING)
                                DeckWarning.copy(alpha = 0.15f)
                            else
                                DeckAccent.copy(alpha = 0.15f)
                        )
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = when {
                                isSearchingHost -> "🔍 Auto-detecting Notch on your Wi-Fi..."
                                connectionState == ConnectionState.CONNECTING -> "🔄 Connecting to $currentHost:8765..."
                                connectionState == ConnectionState.RECONNECTING -> "⚠️ Reconnecting to $currentHost:8765..."
                                else -> "📡 Tap to set Mac Wi-Fi IP (currently: $currentHost)"
                            },
                            color = if (connectionState == ConnectionState.RECONNECTING) DeckWarning else TextPrimary,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier
                                .weight(1f)
                                .clickable { showDialog = true }
                        )

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "Refresh",
                                color = DeckAccent,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier
                                    .clickable { client.refreshProfile() }
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            )

                            Spacer(modifier = Modifier.width(4.dp))

                            Text(
                                text = "Change",
                                color = TextSecondary,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium,
                                modifier = Modifier
                                    .clickable { showDialog = true }
                                    .padding(horizontal = 4.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
            }

            val pagerState = rememberPagerState(initialPage = 0, pageCount = { 2 })
            val coroutineScope = rememberCoroutineScope()

            // Main Content: Horizontal Pager between 6 Apps and Control Panel
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
            ) {
                HorizontalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxSize()
                ) { page ->
                    if (page == 0) {
                        AdaptiveDeckGrid(
                            controls = displayControls,
                            tileStates = tileStates,
                            onControlTap = { controlId ->
                                client.sendActionInvoke(controlId, "tap")
                            }
                        )
                    } else {
                        ControlPanelView(
                            client = client,
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }
            }

            // Subtle Page Dots Indicator (Swipe left / right feedback)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 6.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                repeat(2) { pageIndex ->
                    val isSelected = pagerState.currentPage == pageIndex
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 4.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(if (isSelected) DeckAccent else DeckSurfaceBorder)
                            .clickable {
                                coroutineScope.launch {
                                    pagerState.animateScrollToPage(pageIndex)
                                }
                            }
                            .size(
                                width = if (isSelected) 18.dp else 7.dp,
                                height = 5.dp
                            )
                    )
                }
            }
        }

        // Connection Selector Dialog
        if (showDialog) {
            ConnectionDialog(
                currentHost = currentHost,
                isUsbMode = isUsbMode,
                errorMessage = lastError,
                onConnectUsb = {
                    isUsbMode = true
                    currentHost = "127.0.0.1"
                    prefs.edit()
                        .putBoolean(KEY_IS_USB, true)
                        .putString(KEY_HOST, "127.0.0.1")
                        .apply()
                    client.connect("127.0.0.1", 8765)
                },
                onConnectLan = { ip ->
                    isUsbMode = false
                    currentHost = ip
                    prefs.edit()
                        .putBoolean(KEY_IS_USB, false)
                        .putString(KEY_HOST, ip)
                        .apply()
                    client.connect(ip, 8765)
                },
                onDismiss = { showDialog = false }
            )
        }
    }
}
