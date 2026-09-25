package com.macdeck.client.ui.deck

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.macdeck.client.core.model.DeckControl
import com.macdeck.client.core.network.TileStatus
import com.macdeck.client.ui.theme.DeckSurface
import com.macdeck.client.ui.theme.DeckSurfaceBorder

@Composable
fun AdaptiveDeckGrid(
    controls: List<DeckControl>,
    tileStates: Map<String, TileStatus>,
    onControlTap: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    BoxWithConstraints(modifier = modifier.fillMaxSize()) {
        val isLandscape = maxWidth > maxHeight
        val cols = if (isLandscape) 3 else 2
        val rows = if (isLandscape) 2 else 3

        val horizontalPadding = if (isLandscape) 24.dp else 16.dp
        val verticalPadding = if (isLandscape) 12.dp else 16.dp
        val spacing = if (isLandscape) 14.dp else 12.dp

        val totalHorizontalSpacing = spacing * (cols - 1)
        val totalVerticalSpacing = spacing * (rows - 1)

        val availableWidth = maxWidth - (horizontalPadding * 2) - totalHorizontalSpacing
        val availableHeight = maxHeight - (verticalPadding * 2) - totalVerticalSpacing

        val cellWidth = availableWidth / cols
        val cellHeight = availableHeight / rows

        // Compute adaptive icon size based on cell dimensions
        val iconSize = minOf(cellWidth * 0.46f, cellHeight * 0.46f).coerceIn(48.dp, 120.dp)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = horizontalPadding, vertical = verticalPadding),
            verticalArrangement = Arrangement.spacedBy(spacing)
        ) {
            for (r in 0 until rows) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(spacing)
                ) {
                    for (c in 0 until cols) {
                        val index = r * cols + c
                        if (index < controls.size) {
                            val control = controls[index]
                            val status = tileStates[control.id] ?: TileStatus.IDLE

                            DeckAppTile(
                                control = control,
                                status = status,
                                iconSize = iconSize,
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxHeight(),
                                onTap = { onControlTap(control.id) }
                            )
                        } else {
                            // Blank inactive slot
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxHeight()
                                    .clip(RoundedCornerShape(22.dp))
                                    .background(DeckSurface.copy(alpha = 0.25f))
                                    .border(
                                        width = 1.dp,
                                        color = DeckSurfaceBorder.copy(alpha = 0.3f),
                                        shape = RoundedCornerShape(22.dp)
                                    )
                            )
                        }
                    }
                }
            }
        }
    }
}
