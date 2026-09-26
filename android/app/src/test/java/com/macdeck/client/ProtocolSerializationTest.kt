package com.macdeck.client

import com.macdeck.client.core.model.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class ProtocolSerializationTest {

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    @Test
    fun testHelloSerialization() {
        val hello = Envelope(
            type = "hello",
            requestId = "1234-uuid",
            payload = HelloPayload(clientName = "Pixel 7 Pro", platform = "Android", appVersion = "1.0.0")
        )

        val jsonStr = json.encodeToString(hello)
        val decoded = json.decodeFromString<Envelope<HelloPayload>>(jsonStr)

        assertEquals("hello", decoded.type)
        assertEquals("1234-uuid", decoded.requestId)
        assertEquals("Pixel 7 Pro", decoded.payload.clientName)
    }

    @Test
    fun testProfileSnapshotDeserialization() {
        val rawJson = """
        {
          "protocolVersion": 1,
          "type": "profile.snapshot",
          "requestId": "8f2441d8-348e-4a69-a1b4-239debf00940",
          "timestamp": 1780000000100,
          "payload": {
            "id": "main-deck",
            "name": "My Apps",
            "revision": 1,
            "maxColumns": 3,
            "maxRows": 3,
            "controls": [
              {
                "id": "app-1",
                "label": "VS Code",
                "bundleId": "com.microsoft.VSCode",
                "iconPngBase64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
              }
            ]
          }
        }
        """.trimIndent()

        val decoded = json.decodeFromString<Envelope<ProfileSnapshotPayload>>(rawJson)

        assertEquals("profile.snapshot", decoded.type)
        assertEquals(1, decoded.payload.controls.size)
        assertEquals("VS Code", decoded.payload.controls[0].label)
        assertEquals("com.microsoft.VSCode", decoded.payload.controls[0].bundleId)
        assertNotNull(decoded.payload.controls[0].iconPngBase64)
    }

    @Test
    fun testActionInvokeSerialization() {
        val invoke = Envelope(
            type = "action.invoke",
            requestId = "req-1",
            payload = ActionInvokePayload(controlId = "app-vscode", event = "tap")
        )

        val jsonStr = json.encodeToString(invoke)
        val decoded = json.decodeFromString<Envelope<ActionInvokePayload>>(jsonStr)

        assertEquals("action.invoke", decoded.type)
        assertEquals("app-vscode", decoded.payload.controlId)
        assertEquals("tap", decoded.payload.event)
    }

    @Test
    fun testActionResultDeserialization() {
        val rawJson = """
        {
          "protocolVersion": 1,
          "type": "action.result",
          "requestId": "req-1",
          "timestamp": 1780000001025,
          "payload": {
            "controlId": "app-vscode",
            "status": "OK",
            "errorCode": null,
            "errorMessage": null
          }
        }
        """.trimIndent()

        val decoded = json.decodeFromString<Envelope<ActionResultPayload>>(rawJson)

        assertEquals("action.result", decoded.type)
        assertEquals("OK", decoded.payload.status)
        assertEquals("app-vscode", decoded.payload.controlId)
    }

    @Test
    fun testSystemControlActionInvokeSerialization() {
        val actions = listOf(
            ActionInvokePayload("sys_bluetooth", "on"),
            ActionInvokePayload("sys_wifi", "off"),
            ActionInvokePayload("sys_volume", "set:80"),
            ActionInvokePayload("sys_audio_device", "select:AirPods Pro"),
            ActionInvokePayload("sys_brightness", "set:65")
        )

        for (action in actions) {
            val envelope = Envelope(
                type = "action.invoke",
                requestId = "sys-req-${action.controlId}",
                payload = action
            )
            val jsonStr = json.encodeToString(envelope)
            val decoded = json.decodeFromString<Envelope<ActionInvokePayload>>(jsonStr)

            assertEquals("action.invoke", decoded.type)
            assertEquals(action.controlId, decoded.payload.controlId)
            assertEquals(action.event, decoded.payload.event)
        }
    }

    @Test
    fun testProfileRefreshSerialization() {
        val refreshEnvelope = Envelope(
            type = "profile.refresh",
            requestId = "ref-123",
            payload = EmptyPayload()
        )

        val jsonStr = json.encodeToString(refreshEnvelope)
        val decoded = json.decodeFromString<Envelope<EmptyPayload>>(jsonStr)

        assertEquals("profile.refresh", decoded.type)
        assertEquals("ref-123", decoded.requestId)
    }

    @Test
    fun testHelloWithBatterySerialization() {
        val hello = Envelope(
            type = "hello",
            requestId = "hello-batt-1",
            payload = HelloPayload(
                clientName = "Pixel 8 Pro",
                platform = "Android",
                appVersion = "1.0.0",
                batteryLevel = 92,
                isCharging = true
            )
        )
        val jsonStr = json.encodeToString(hello)
        val decoded = json.decodeFromString<Envelope<HelloPayload>>(jsonStr)

        assertEquals(92, decoded.payload.batteryLevel)
        assertEquals(true, decoded.payload.isCharging)
    }

    @Test
    fun testDeviceBatterySerialization() {
        val batteryEnv = Envelope(
            type = "device.battery",
            requestId = "batt-123",
            payload = DeviceBatteryPayload(
                level = 85,
                isCharging = true,
                plugged = "usb"
            )
        )
        val jsonStr = json.encodeToString(batteryEnv)
        val decoded = json.decodeFromString<Envelope<DeviceBatteryPayload>>(jsonStr)

        assertEquals("device.battery", decoded.type)
        assertEquals(85, decoded.payload.level)
        assertEquals(true, decoded.payload.isCharging)
        assertEquals("usb", decoded.payload.plugged)
    }
}

