package com.macdeck.client.core.network

import android.content.Context
import android.net.wifi.WifiManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.Socket
import java.util.Collections
import java.util.Locale
import java.util.concurrent.atomic.AtomicReference

object NetworkGatewayUtils {
    const val WS_PORT = 8765
    const val UDP_DISCOVERY_PORT = 8766
    const val PORTAL_PORT = 8080

    /**
     * Resolves the Wi-Fi or tethering DHCP gateway IP address.
     */
    fun getDhcpGatewayIp(context: Context): String? {
        try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            val dhcp = wifiManager?.dhcpInfo
            if (dhcp != null && dhcp.gateway != 0) {
                val g = dhcp.gateway
                return String.format(
                    Locale.US,
                    "%d.%d.%d.%d",
                    g and 0xff,
                    (g shr 8) and 0xff,
                    (g shr 16) and 0xff,
                    (g shr 24) and 0xff
                )
            }
        } catch (_: Exception) {}
        return null
    }

    /**
     * Returns the phone's current local IPv4 address across active non-loopback network interfaces.
     */
    fun getLocalDeviceIps(): List<String> {
        val ips = mutableListOf<String>()
        try {
            val interfaces = Collections.list(NetworkInterface.getNetworkInterfaces())
            for (intf in interfaces) {
                if (intf.isLoopback || !intf.isUp) continue
                val addrs = Collections.list(intf.inetAddresses)
                for (addr in addrs) {
                    if (!addr.isLoopbackAddress && addr is java.net.Inet4Address) {
                        val ip = addr.hostAddress ?: ""
                        if (!ip.startsWith("127.") && !ip.startsWith("169.254.")) {
                            ips.add(ip)
                        }
                    }
                }
            }
        } catch (_: Exception) {}
        return ips
    }

    /**
     * Automatically discovers the NotchDeck macOS host IP address on the local network.
     * Uses UDP Broadcast Discovery and Subnet Probing.
     */
    suspend fun discoverMacHost(context: Context): String? = withContext(Dispatchers.IO) {
        // 1. Try fast UDP broadcast discovery
        val udpHost = discoverViaUdp()
        if (udpHost != null) {
            return@withContext udpHost
        }

        // 2. Parallel TCP port probe on local subnet
        val discoveredHost = AtomicReference<String?>(null)
        val candidateIps = mutableListOf<String>()

        val gateway = getDhcpGatewayIp(context)
        if (gateway != null) {
            candidateIps.add(gateway)
        }

        val myIps = getLocalDeviceIps()
        for (myIp in myIps) {
            val lastDot = myIp.lastIndexOf('.')
            if (lastDot != -1) {
                val prefix = myIp.substring(0, lastDot + 1)
                // Add common static and DHCP ranges
                for (i in 1..254) {
                    val ip = "$prefix$i"
                    if (ip != myIp && ip != gateway) {
                        candidateIps.add(ip)
                    }
                }
            }
        }

        // Probe candidate IPs in concurrent chunks
        coroutineScope {
            val chunks = candidateIps.chunked(32)
            for (chunk in chunks) {
                if (discoveredHost.get() != null) break
                val jobs = chunk.map { ip ->
                    async {
                        if (discoveredHost.get() == null && probeHost(ip, WS_PORT, 180)) {
                            discoveredHost.compareAndSet(null, ip)
                        }
                    }
                }
                jobs.awaitAll()
            }
        }

        discoveredHost.get()
    }

    /**
     * Broadcasts a UDP query on port 8766 to find NotchDeck host.
     */
    private fun discoverViaUdp(): String? {
        var socket: DatagramSocket? = null
        try {
            socket = DatagramSocket()
            socket.broadcast = true
            socket.soTimeout = 350

            val queryMsg = "NOTCHDECK_DISCOVER\n".toByteArray(Charsets.UTF_8)
            val packet = DatagramPacket(
                queryMsg,
                queryMsg.size,
                InetAddress.getByName("255.255.255.255"),
                UDP_DISCOVERY_PORT
            )
            socket.send(packet)

            val buffer = ByteArray(1024)
            val responsePacket = DatagramPacket(buffer, buffer.size)
            socket.receive(responsePacket)

            val response = String(responsePacket.data, 0, responsePacket.length, Charsets.UTF_8).trim()
            if (response.startsWith("NOTCHDECK_HOST:")) {
                val parts = response.removePrefix("NOTCHDECK_HOST:").split(":")
                val hostIp = parts[0].trim()
                if (hostIp.isNotBlank()) {
                    return hostIp
                }
            }
        } catch (_: Exception) {
        } finally {
            socket?.close()
        }
        return null
    }

    /**
     * Tests if an IP has port open.
     */
    fun probeHost(ip: String, port: Int, timeoutMs: Int): Boolean {
        var sock: Socket? = null
        return try {
            sock = Socket()
            sock.connect(InetSocketAddress(ip, port), timeoutMs)
            true
        } catch (_: Exception) {
            false
        } finally {
            try { sock?.close() } catch (_: Exception) {}
        }
    }

    /**
     * Extracts an IPv4 address from any scanned text or URL (e.g. "http://192.168.68.134:8080/?auto=1").
     */
    fun extractIpFromText(input: String): String? {
        val trimmed = input.trim()
        val regex = Regex("""\b(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b""")
        return regex.find(trimmed)?.value
    }
}
