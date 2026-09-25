package com.macdeck.client.ui.deck

import android.view.HapticFeedbackConstants
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.macdeck.client.core.model.DeckControl
import com.macdeck.client.core.network.TileStatus
import com.macdeck.client.ui.theme.*

@Composable
fun DeckAppTile(
    control: DeckControl,
    status: TileStatus,
    iconSize: Dp,
    modifier: Modifier = Modifier,
    onTap: () -> Unit
) {
    var isPressed by remember { mutableStateOf(false) }
    val view = LocalView.current

    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.93f else 1.0f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = 600f),
        label = "tile_scale"
    )

    val borderColor by animateColorAsState(
        targetValue = when (status) {
            TileStatus.SUCCESS -> DeckSuccess
            TileStatus.ERROR -> DeckError
            TileStatus.PENDING -> DeckAccent
            else -> if (isPressed) DeckAccent.copy(alpha = 0.8f) else DeckSurfaceBorder
        },
        label = "tile_border"
    )

    val backgroundColor by animateColorAsState(
        targetValue = when {
            isPressed -> DeckSurfacePressed
            status == TileStatus.SUCCESS -> DeckSuccess.copy(alpha = 0.12f)
            status == TileStatus.ERROR -> DeckError.copy(alpha = 0.12f)
            else -> DeckSurface
        },
        label = "tile_background"
    )

    val imageBitmap = remember(control.iconPngBase64) {
        BitmapDecoder.decodeBase64ToImageBitmap(control.iconPngBase64)
    }

    Box(
        modifier = modifier
            .scale(scale)
            .clip(RoundedCornerShape(22.dp))
            .background(backgroundColor)
            .border(
                width = if (status != TileStatus.IDLE || isPressed) 2.dp else 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(22.dp)
            )
            .pointerInput(control.id) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                        tryAwaitRelease()
                        isPressed = false
                        onTap()
                    }
                )
            }
            .padding(12.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxSize()
        ) {
            // App Icon
            if (imageBitmap != null) {
                Image(
                    bitmap = imageBitmap,
                    contentDescription = control.label,
                    modifier = Modifier
                        .size(iconSize)
                        .clip(RoundedCornerShape(iconSize * 0.22f))
                )
            } else {
                // Fallback letter avatar
                Box(
                    modifier = Modifier
                        .size(iconSize)
                        .clip(RoundedCornerShape(iconSize * 0.22f))
                        .background(DeckAccent.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = control.label.take(1).uppercase(),
                        color = DeckAccent,
                        fontSize = (iconSize.value * 0.45f).sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // App Name Label
            Text(
                text = control.label,
                color = TextPrimary,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
