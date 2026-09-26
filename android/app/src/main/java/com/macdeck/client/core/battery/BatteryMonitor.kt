package com.macdeck.client.core.battery

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.util.Log

data class BatteryInfo(
    val level: Int,
    val isCharging: Boolean,
    val plugged: String? = null
)

class BatteryMonitor(private val context: Context) {
    companion object {
        private const val TAG = "BatteryMonitor"
    }

    private var receiver: BroadcastReceiver? = null
    private var lastEmittedInfo: BatteryInfo? = null

    fun getCurrentBatteryInfo(): BatteryInfo {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryIntent = context.registerReceiver(null, intentFilter)
        return parseBatteryIntent(batteryIntent)
    }

    fun startMonitoring(onBatteryChange: (BatteryInfo) -> Unit) {
        if (receiver != null) return

        val initial = getCurrentBatteryInfo()
        lastEmittedInfo = initial
        onBatteryChange(initial)

        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                    val info = parseBatteryIntent(intent)
                    if (info.level != lastEmittedInfo?.level || info.isCharging != lastEmittedInfo?.isCharging) {
                        lastEmittedInfo = info
                        Log.d(TAG, "Battery updated: ${info.level}%, charging: ${info.isCharging}")
                        onBatteryChange(info)
                    }
                }
            }
        }

        context.registerReceiver(receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    }

    fun stopMonitoring() {
        receiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                Log.w(TAG, "Error unregistering battery receiver", e)
            }
            receiver = null
        }
    }

    private fun parseBatteryIntent(intent: Intent?): BatteryInfo {
        if (intent == null) {
            return BatteryInfo(level = 100, isCharging = false, plugged = "none")
        }

        val rawLevel = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val level = if (rawLevel >= 0 && scale > 0) {
            ((rawLevel / scale.toFloat()) * 100).toInt()
        } else {
            100
        }

        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL

        val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
        val plugSource = when (plugged) {
            BatteryManager.BATTERY_PLUGGED_USB -> "usb"
            BatteryManager.BATTERY_PLUGGED_AC -> "ac"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "wireless"
            else -> "none"
        }

        return BatteryInfo(
            level = level.coerceIn(0, 100),
            isCharging = isCharging,
            plugged = plugSource
        )
    }
}
