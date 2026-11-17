package tz.co.cardly.app

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Puts a push notification that arrived while the app is open into the
 * notification shade, the same as one that arrives while it's closed
 * (Firebase only does that part itself when the app isn't in front).
 *
 * Methods: `show` ({title, body, route}), `takeLaunchRoute`. Calls back
 * `open` with the route when one of these is tapped while the app runs.
 */
class LocalNotifications(private val activity: Activity, messenger: BinaryMessenger) {

    companion object {
        const val ROUTE_EXTRA = "cardly_route"
    }

    private val channel = MethodChannel(messenger, "cardly/notify")
    private var nextId = (System.currentTimeMillis() % 100_000).toInt()

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    show(
                        call.argument<String>("title") ?: "",
                        call.argument<String>("body") ?: "",
                        call.argument<String>("route"),
                    )
                    result.success(null)
                }
                "takeLaunchRoute" -> {
                    val route = activity.intent?.getStringExtra(ROUTE_EXTRA)
                    activity.intent?.removeExtra(ROUTE_EXTRA)
                    result.success(route)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** From MainActivity.onNewIntent: one of ours was tapped. */
    fun handleIntent(intent: Intent) {
        val route = intent.getStringExtra(ROUTE_EXTRA) ?: return
        intent.removeExtra(ROUTE_EXTRA)
        channel.invokeMethod("open", route)
    }

    private fun show(title: String, body: String, route: String?) {
        val id = nextId++
        val tap = Intent(activity, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (route != null) putExtra(ROUTE_EXTRA, route)
        }
        val pending = PendingIntent.getActivity(
            activity,
            id,
            tap,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(activity, "cardly")
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(activity.getColor(R.color.notification_brown))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()
        try {
            NotificationManagerCompat.from(activity).notify(id, notification)
        } catch (_: SecurityException) {
            // Notifications turned off for the app: nothing to show.
        }
    }
}
