package com.example.flutter_workspace

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.content.res.Configuration
import android.graphics.Typeface
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object TradexNotifications {
    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "tradex/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "showMarket") {
                    result.notImplemented()
                } else {
                    try {
                        show(context, call.arguments as? Map<*, *> ?: error("Missing market data"))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("notification_failed", e.message, null)
                    }
                }
            }
    }

    private fun show(context: Context, data: Map<*, *>) {
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            error("Permite las notificaciones de Tradex en Android.")
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        val ongoing = data["ongoing"] == true
        // Conserva el canal y el ID del servicio para actualizar su propia notificación.
        val channel = if (ongoing) "forex_live" else "tradex_market"
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channel,
                "Cotizaciones${if (ongoing) " en vivo" else ""}", NotificationManager.IMPORTANCE_LOW))
        }
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: error("No launch activity")
        val open = PendingIntent.getActivity(context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val prices = (data["prices"] as? List<*>)?.filterIsInstance<Map<*, *>>() ?: emptyList()
        val dark = (context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        fun quote(price: Map<*, *>): CharSequence {
            val symbol = price["symbol"]?.toString().orEmpty()
            val text = SpannableStringBuilder("$symbol · ${price["price"]}")
            text.setSpan(StyleSpan(Typeface.BOLD), 0, symbol.length, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
            if (data["showChanges"] == false) return text
            text.append(" · ")
            val start = text.length
            text.append(price["change"]?.toString().orEmpty())
            val up = price["up"] == true
            val color = if (up) {
                if (dark) 0xFF71E2B3.toInt() else 0xFF137A4B.toInt()
            } else {
                if (dark) 0xFFFF9BA8.toInt() else 0xFFB3261E.toInt()
            }
            if (text.length > start) {
                text.setSpan(ForegroundColorSpan(color), start, text.length, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
            return text
        }
        val selected = (data["selectedCount"] as? Number)?.toInt() ?: prices.size
        val detail = SpannableStringBuilder()
        fun addLine(text: CharSequence) {
            if (detail.isNotEmpty()) detail.append('\n')
            detail.append(text)
        }
        if (prices.isEmpty() && selected > 0) addLine("Sin precios disponibles")
        for (price in prices) addLine(quote(price))
        if (prices.size < selected) {
            addLine("${prices.size}/$selected precios disponibles")
        }
        val bob = data["bob"] as? String
        if (bob != null) addLine("USD/BOB · Bs $bob")
        val events = (data["events"] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
        if (events.isNotEmpty()) {
            detail.append('\n')
            val heading = SpannableStringBuilder("Eventos · alto impacto")
            heading.setSpan(StyleSpan(Typeface.BOLD), 0, heading.length,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
            addLine(heading)
            for (event in events) addLine(event)
        }
        if (detail.isEmpty()) addLine("Sin datos disponibles")
        val headline: CharSequence = prices.firstOrNull()?.let { quote(it) }
            ?: bob?.let { "USD/BOB · Bs $it" }
            ?: if (events.isNotEmpty()) "Próximo evento" else "Mercado"
        val preview: CharSequence = events.firstOrNull()?.let { "Próximo · $it" }
            ?: prices.getOrNull(1)?.let { quote(it) }
            ?: bob?.let { if (prices.isNotEmpty()) "USD/BOB · Bs $it" else "Cotización oficial" }
            ?: if (prices.isNotEmpty()) "Cotizaciones" else "Sin datos disponibles"

        val builder = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_tradex_notification)
            .setContentTitle(headline)
            .setContentText(preview)
            .setSubText(if (prices.isNotEmpty() && data["showChanges"] != false)
                "${data["time"]} · 24 h" else "${data["time"]}")
            .setColor(0xFF62D5B0.toInt())
            .setStyle(NotificationCompat.BigTextStyle()
                .setBigContentTitle("Mercado")
                .bigText(detail))
            .setContentIntent(open)
            .setOnlyAlertOnce(true)
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
        if (ongoing) {
            val refresh = PendingIntent.getBroadcast(context, 1,
                Intent(context, MarketRefreshReceiver::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            builder.addAction(R.drawable.ic_tradex_notification, "Actualizar", refresh)
        }
        manager.notify(if (ongoing) 100 else 2, builder.build())
    }
}
