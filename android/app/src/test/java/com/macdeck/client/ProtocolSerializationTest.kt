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
}
