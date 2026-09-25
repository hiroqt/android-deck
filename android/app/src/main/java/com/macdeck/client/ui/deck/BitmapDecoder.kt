package com.macdeck.client.ui.deck

import android.graphics.BitmapFactory
import android.util.Base64
import android.util.LruCache
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap

object BitmapDecoder {
    private val cache = LruCache<String, ImageBitmap>(32)

    fun decodeBase64ToImageBitmap(base64Str: String?): ImageBitmap? {
        if (base64Str.isNullOrBlank()) return null

        cache.get(base64Str)?.let { return it }

        return try {
            val bytes = Base64.decode(base64Str, Base64.DEFAULT)
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            bitmap?.asImageBitmap()?.also {
                cache.put(base64Str, it)
            }
        } catch (e: Exception) {
            null
        }
    }
}
