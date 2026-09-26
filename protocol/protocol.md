# MacDeck Protocol Specification (v1)

This document formalizes the wire protocol for MacDeck over persistent WebSocket connections.

## 1. Envelope Structure

All messages sent over the WebSocket are JSON UTF-8 encoded envelopes:

```json
{
  "protocolVersion": 1,
  "type": "<message_type>",
  "requestId": "<uuid_v4>",
  "timestamp": 1780000000000,
  "payload": {}
}
```

- `protocolVersion` (integer): Must be `1` for this version.
- `type` (string): Identifies message payload schema.
- `requestId` (string, UUID): Correlates requests with responses/acknowledgements.
- `timestamp` (integer, epoch ms): Sending timestamp.
- `payload` (object): Message-specific dictionary.

---

## 2. Message Types

### 2.1 Handshake: `hello`
Sent by client upon WebSocket connection establishment.

```json
{
  "protocolVersion": 1,
  "type": "hello",
  "requestId": "c0e668ee-7013-4bf5-a7b3-6dc0f898a3e2",
  "timestamp": 1780000000000,
  "payload": {
    "clientName": "Pixel 7 Pro",
    "platform": "Android",
    "appVersion": "1.0.0",
    "batteryLevel": 85,
    "isCharging": true
  }
}
```

### 2.2 Handshake Ack: `hello.ack`
Sent by macOS host in response to `hello`.

```json
{
  "protocolVersion": 1,
  "type": "hello.ack",
  "requestId": "c0e668ee-7013-4bf5-a7b3-6dc0f898a3e2",
  "timestamp": 1780000000050,
  "payload": {
    "serverName": "MacBook Pro",
    "osVersion": "macOS 15.0",
    "appVersion": "1.0.0"
  }
}
```

### 2.3 Profile Delivery: `profile.snapshot` & `profile.changed`
Emitted by macOS host to push the current deck profile (maximum 6 apps).

```json
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
        "id": "app-vscode",
        "label": "Visual Studio Code",
        "bundleId": "com.microsoft.VSCode",
        "iconPngBase64": "iVBORw0KGgoAAAANSUhEUgAA..."
      }
    ]
  }
}
```

### 2.4 Action Invocation: `action.invoke`
Sent by Android client when an app button is tapped. Android only passes `controlId` and `event`; it NEVER passes raw command strings.

```json
{
  "protocolVersion": 1,
  "type": "action.invoke",
  "requestId": "df393df8-80e2-45e0-b639-65b5976b92a4",
  "timestamp": 1780000001000,
  "payload": {
    "controlId": "app-vscode",
    "event": "tap"
  }
}
```

### 2.5 Action Outcome: `action.result`
Sent by macOS host acknowledging execution outcome.

```json
{
  "protocolVersion": 1,
  "type": "action.result",
  "requestId": "df393df8-80e2-45e0-b639-65b5976b92a4",
  "timestamp": 1780000001025,
  "payload": {
    "controlId": "app-vscode",
    "status": "OK",
    "errorCode": null,
    "errorMessage": null
  }
}
```

Typed error codes when `status == "ERROR"`:
- `ACTION_UNKNOWN`: Control ID is not registered on host.
- `APP_NOT_FOUND`: Target application could not be found in macOS workspace.
- `LAUNCH_FAILED`: NSWorkspace failed to open application.
- `INTERNAL_ERROR`: Unhandled host error.

### 2.6 Ping / Pong
Heartbeat keepalive sent periodically.

```json
{
  "protocolVersion": 1,
  "type": "ping",
  "requestId": "5c1f5dd5-19e4-4d2b-b8f4-b2586b6a22aa",
  "timestamp": 1780000010000,
  "payload": {}
}
```
Response: `type: "pong"` with matching `requestId`.

---

### 2.7 Profile Refresh: `profile.refresh` / `profile.get`
Sent by client (e.g. upon user tapping the Refresh button on phone) to explicitly request a fresh profile snapshot from the macOS host.

```json
{
  "protocolVersion": 1,
  "type": "profile.refresh",
  "requestId": "9a38f7e2-4731-419b-a0d4-1a9829f032aa",
  "timestamp": 1780000020000,
  "payload": {}
}
```
Response: `type: "profile.snapshot"` with matching `requestId` and refreshed profile payload. The macOS host also reloads `~/.macdeck/profile.json` from disk and emits `profile.changed` to all connected clients.

---

### 2.8 Device Battery Telemetry: `device.battery`
Emitted by client periodically or on battery state changes to update the host on battery status.

```json
{
  "protocolVersion": 1,
  "type": "device.battery",
  "requestId": "d82046e7-1335-46aa-bd06-e7813a30c502",
  "timestamp": 1780000030000,
  "payload": {
    "level": 85,
    "isCharging": true,
    "plugged": "usb"
  }
}
```
Payload fields:
- `level` (integer, 0–100): Current battery percentage.
- `isCharging` (boolean): `true` if connected to power and charging.
- `plugged` (string, optional): `"usb"`, `"ac"`, `"wireless"`, or `"none"`.

