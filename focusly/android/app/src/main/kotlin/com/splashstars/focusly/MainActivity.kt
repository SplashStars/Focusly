package com.splashstars.focusly

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity - hosts Flutter and exposes a Do Not Disturb channel used by
 * Strict Mode on the Focus screen.
 *
 * Android will not let an app silence calls or messages directly; the only
 * sanctioned route is toggling the system interruption filter, which requires
 * the user to grant Do Not Disturb access once. We request it only at the
 * moment Strict Mode is switched on, and always restore the previous filter.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "focusly/dnd"
    private var previousFilter: Int? = null

    private val notificationManager: NotificationManager
        get() = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasAccess" -> result.success(hasDndAccess())

                    "openSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                        }
                        result.success(null)
                    }

                    "enable" -> {
                        if (!hasDndAccess()) {
                            result.success(false)
                        } else {
                            try {
                                previousFilter = notificationManager.currentInterruptionFilter
                                notificationManager.setInterruptionFilter(
                                    NotificationManager.INTERRUPTION_FILTER_NONE
                                )
                                result.success(true)
                            } catch (e: SecurityException) {
                                result.success(false)
                            }
                        }
                    }

                    "disable" -> {
                        restoreFilter()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun hasDndAccess(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            notificationManager.isNotificationPolicyAccessGranted
        else false

    private fun restoreFilter() {
        if (previousFilter != null && hasDndAccess()) {
            try {
                notificationManager.setInterruptionFilter(
                    previousFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                )
            } catch (e: SecurityException) {
                // User revoked access mid-session.
            }
        }
        previousFilter = null
    }

    /** Never leave the user stuck in DND if the app is killed mid-session. */
    override fun onDestroy() {
        restoreFilter()
        super.onDestroy()
    }
}
