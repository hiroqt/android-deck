package com.macdeck.client.core.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class Envelope<T>(
    val protocolVersion: Int = 1,
    val type: String,
    val requestId: String,
    val timestamp: Long = System.currentTimeMillis(),
    val payload: T
)

@Serializable
data class RawEnvelope(
    val protocolVersion: Int = 1,
    val type: String,
    val requestId: String,
    val timestamp: Long = 0,
    val payload: JsonElement? = null
)

@Serializable
data class HelloPayload(
    val clientName: String = "Android Deck",
    val platform: String = "Android",
    val appVersion: String = "1.0.0",
    val batteryLevel: Int? = null,
    val isCharging: Boolean? = null
)

@Serializable
data class DeviceBatteryPayload(
    val level: Int,
    val isCharging: Boolean,
    val plugged: String? = null
)

@Serializable
data class HelloAckPayload(
    val serverName: String = "NotchDeck Host",
    val osVersion: String = "",
    val appVersion: String = "1.0.0"
)

@Serializable
data class DeckControl(
    val id: String,
    val label: String,
    val bundleId: String,
    val iconPngBase64: String? = null
)

@Serializable
data class ProfileSnapshotPayload(
    val id: String = "main-deck",
    val name: String = "My Apps",
    val revision: Int = 1,
    val maxColumns: Int = 3,
    val maxRows: Int = 3,
    val controls: List<DeckControl> = emptyList()
)

@Serializable
data class ActionInvokePayload(
    val controlId: String,
    val event: String = "tap"
)

@Serializable
data class ActionResultPayload(
    val controlId: String,
    val status: String, // "OK" or "ERROR"
    val errorCode: String? = null,
    val errorMessage: String? = null
)

@Serializable
class EmptyPayload
