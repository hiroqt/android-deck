package com.macdeck.client.core.network

import android.util.Log
import com.macdeck.client.core.battery.BatteryInfo
import com.macdeck.client.core.model.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.*
import java.util.UUID
import java.util.concurrent.TimeUnit

enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    RECONNECTING
}

enum class TileStatus {
    IDLE,
    PRESSED,
    PENDING,
    SUCCESS,
    ERROR
}

class DeckWebSocketClient(
    private val scope: CoroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
) {
    companion object {
        private const val TAG = "NotchDeckWS"
    }

    var batteryProvider: (() -> BatteryInfo?)? = null

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    private val okHttpClient = OkHttpClient.Builder()
        .pingInterval(10, TimeUnit.SECONDS)
        .connectTimeout(5, TimeUnit.SECONDS)
        .readTimeout(0, TimeUnit.MILLISECONDS) // Keep-alive for WS
        .build()

    private var webSocket: WebSocket? = null
    private var currentUrl: String = ""
    private var shouldAutoReconnect: Boolean = true
    private var reconnectAttempt = 0

    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()

    private val _currentProfile = MutableStateFlow<ProfileSnapshotPayload?>(null)
    val currentProfile: StateFlow<ProfileSnapshotPayload?> = _currentProfile.asStateFlow()

    private val _systemStatus = MutableStateFlow<SystemStatusPayload?>(null)
    val systemStatus: StateFlow<SystemStatusPayload?> = _systemStatus.asStateFlow()

    private val _tileStates = MutableStateFlow<Map<String, TileStatus>>(emptyMap())
    val tileStates: StateFlow<Map<String, TileStatus>> = _tileStates.asStateFlow()

    private val _lastErrorMessage = MutableStateFlow<String?>(null)
    val lastErrorMessage: StateFlow<String?> = _lastErrorMessage.asStateFlow()

    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

    fun connect(host: String, port: Int = 8765) {
        val cleanHost = host.trim().removePrefix("ws://").removePrefix("http://")
        currentUrl = "ws://$cleanHost:$port"
        shouldAutoReconnect = true
        reconnectAttempt = 0
        initiateConnection()
    }

    private var batterySyncJob: Job? = null

    fun sendBatteryUpdate(info: BatteryInfo) {
        if (_connectionState.value != ConnectionState.CONNECTED) return
        val envelope = Envelope(
            type = "device.battery",
            requestId = UUID.randomUUID().toString(),
            payload = DeviceBatteryPayload(
                level = info.level,
                batteryLevel = info.level,
                isCharging = info.isCharging,
                plugged = info.plugged
            )
        )
        try {
            webSocket?.send(json.encodeToString(envelope))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send battery update", e)
        }
    }

    private fun startBatterySync() {
        batterySyncJob?.cancel()
        batterySyncJob = scope.launch {
            while (isActive && _connectionState.value == ConnectionState.CONNECTED) {
                delay(30_000L)
                if (_connectionState.value == ConnectionState.CONNECTED) {
                    batteryProvider?.invoke()?.let { info ->
                        sendBatteryUpdate(info)
                    }
                }
            }
        }
    }

    private fun stopBatterySync() {
        batterySyncJob?.cancel()
        batterySyncJob = null
    }

    private fun initiateConnection() {
        if (currentUrl.isEmpty()) return
        _connectionState.value = if (reconnectAttempt > 0) ConnectionState.RECONNECTING else ConnectionState.CONNECTING

        val request = Request.Builder().url(currentUrl).build()
        webSocket?.cancel()
        webSocket = okHttpClient.newWebSocket(request, createListener())
    }

    private fun createListener(): WebSocketListener {
        return object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.d(TAG, "WebSocket connected to $currentUrl")
                _connectionState.value = ConnectionState.CONNECTED
                _lastErrorMessage.value = null
                reconnectAttempt = 0

                // Send hello handshake
                val currentBattery = batteryProvider?.invoke()
                val helloEnvelope = Envelope(
                    type = "hello",
                    requestId = UUID.randomUUID().toString(),
                    payload = HelloPayload(
                        clientName = android.os.Build.MODEL ?: "Android Device",
                        platform = "Android",
                        appVersion = "1.0.0",
                        batteryLevel = currentBattery?.level,
                        level = currentBattery?.level,
                        isCharging = currentBattery?.isCharging
                    )
                )
                webSocket.send(json.encodeToString(helloEnvelope))

                // Immediately send explicit battery packet if available
                currentBattery?.let {
                    sendBatteryUpdate(it)
                }

                // Request initial system status (volume, brightness, toggles, devices)
                requestSystemStatus()

                // Start periodic battery sync while connected
                startBatterySync()
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                scope.launch {
                    handleIncomingJson(text)
                }
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "WebSocket closing: $code / $reason")
                stopBatterySync()
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "WebSocket closed: $code / $reason")
                stopBatterySync()
                if (shouldAutoReconnect) {
                    scheduleReconnect()
                } else {
                    _connectionState.value = ConnectionState.DISCONNECTED
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "WebSocket failure: ${t.message}")
                stopBatterySync()
                _lastErrorMessage.value = t.localizedMessage ?: t.message
                if (shouldAutoReconnect) {
                    scheduleReconnect()
                } else {
                    _connectionState.value = ConnectionState.DISCONNECTED
                }
            }
        }
    }

    private fun scheduleReconnect() {
        _connectionState.value = ConnectionState.RECONNECTING
        reconnectAttempt++
        val delayMs = (1000L * (1 shl minOf(reconnectAttempt, 4))).coerceAtMost(10000L)
        Log.d(TAG, "Scheduling reconnect #$reconnectAttempt in ${delayMs}ms")

        scope.launch {
            delay(delayMs)
            if (shouldAutoReconnect && _connectionState.value != ConnectionState.CONNECTED) {
                initiateConnection()
            }
        }
    }

    private fun handleIncomingJson(text: String) {
        try {
            val raw = json.decodeFromString<RawEnvelope>(text)
            when (raw.type) {
                "profile.snapshot", "profile.changed" -> {
                    val snapshotEnv = json.decodeFromString<Envelope<ProfileSnapshotPayload>>(text)
                    _currentProfile.value = snapshotEnv.payload
                    _isRefreshing.value = false
                    Log.d(TAG, "Received profile: ${snapshotEnv.payload.name} with ${snapshotEnv.payload.controls.size} controls")
                }
                "system.status" -> {
                    val statusEnv = json.decodeFromString<Envelope<SystemStatusPayload>>(text)
                    _systemStatus.value = statusEnv.payload
                    Log.d(TAG, "Received system status: vol=${statusEnv.payload.volume}%, bri=${statusEnv.payload.brightness}%, dev=${statusEnv.payload.currentAudioDevice}")
                }
                "action.result" -> {
                    val resultEnv = json.decodeFromString<Envelope<ActionResultPayload>>(text)
                    val result = resultEnv.payload
                    handleActionResult(result)
                }
                "hello.ack" -> {
                    Log.d(TAG, "Handshake acknowledged by Mac")
                    requestSystemStatus()
                }
                "pong" -> {
                    // Ping responded
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing message: ${e.message}", e)
        }
    }

    fun requestSystemStatus() {
        if (_connectionState.value == ConnectionState.CONNECTED) {
            val env = Envelope(
                type = "system.status.request",
                requestId = UUID.randomUUID().toString(),
                payload = EmptyPayload()
            )
            webSocket?.send(json.encodeToString(env))
        }
    }

    fun refreshProfile() {
        scope.launch {
            _isRefreshing.value = true
            if (_connectionState.value == ConnectionState.CONNECTED) {
                val env = Envelope(
                    type = "profile.refresh",
                    requestId = UUID.randomUUID().toString(),
                    payload = EmptyPayload()
                )
                val sent = webSocket?.send(json.encodeToString(env)) ?: false
                requestSystemStatus()
                if (!sent) {
                    initiateConnection()
                }
            } else {
                initiateConnection()
            }
            delay(1200)
            _isRefreshing.value = false
        }
    }

    fun sendActionInvoke(controlId: String, event: String = "tap") {
        setTileStatus(controlId, TileStatus.PENDING)

        val env = Envelope(
            type = "action.invoke",
            requestId = UUID.randomUUID().toString(),
            payload = ActionInvokePayload(controlId = controlId, event = event)
        )
        val jsonStr = json.encodeToString(env)
        val sent = webSocket?.send(jsonStr) ?: false
        if (!sent) {
            Log.w(TAG, "Failed to send action.invoke: socket not connected")
            setTileStatus(controlId, TileStatus.ERROR)
            clearTileStatusAfterDelay(controlId, 1500)
        }
    }

    private fun handleActionResult(result: ActionResultPayload) {
        val status = if (result.status.equals("OK", ignoreCase = true) || result.status.equals("success", ignoreCase = true)) TileStatus.SUCCESS else TileStatus.ERROR
        setTileStatus(result.controlId, status)
        clearTileStatusAfterDelay(result.controlId, if (status == TileStatus.SUCCESS) 600 else 1800)
    }

    fun setTileStatus(controlId: String, status: TileStatus) {
        val current = _tileStates.value.toMutableMap()
        current[controlId] = status
        _tileStates.value = current
    }

    private fun clearTileStatusAfterDelay(controlId: String, delayMs: Long) {
        scope.launch {
            delay(delayMs)
            val current = _tileStates.value.toMutableMap()
            if (current[controlId] != TileStatus.PENDING) {
                current.remove(controlId)
                _tileStates.value = current
            }
        }
    }

    fun disconnect() {
        shouldAutoReconnect = false
        stopBatterySync()
        webSocket?.close(1000, "User disconnected")
        webSocket = null
        _connectionState.value = ConnectionState.DISCONNECTED
    }
}
