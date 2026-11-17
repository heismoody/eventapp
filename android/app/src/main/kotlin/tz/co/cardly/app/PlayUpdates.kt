package tz.co.cardly.app

import android.app.Activity
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Google Play in-app updates for the Dart side (play_update_service.dart).
 *
 * Methods: `check`, `start` ({type: "flexible" | "immediate"}), `complete`.
 * Calls back `onInstallState` with the download's progress while a flexible
 * update downloads. Only does anything for a copy installed from Play.
 */
class PlayUpdates(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "cardly/play_update")
    private val manager: AppUpdateManager = AppUpdateManagerFactory.create(activity)

    private val listener: InstallStateUpdatedListener = InstallStateUpdatedListener { state ->
        channel.invokeMethod(
            "onInstallState",
            mapOf(
                "status" to statusName(state.installStatus()),
                "downloaded" to state.bytesDownloaded(),
                "total" to state.totalBytesToDownload(),
            ),
        )
        if (state.installStatus() == InstallStatus.INSTALLED ||
            state.installStatus() == InstallStatus.FAILED ||
            state.installStatus() == InstallStatus.CANCELED
        ) {
            manager.unregisterListener(listener)
        }
    }

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "check" -> check(result)
            "start" -> start(call.argument<String>("type") ?: "flexible", result)
            "complete" -> {
                manager.completeUpdate()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun check(result: MethodChannel.Result) {
        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                result.success(
                    mapOf(
                        "availability" to when (info.updateAvailability()) {
                            UpdateAvailability.UPDATE_AVAILABLE -> "available"
                            UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS -> "in_progress"
                            UpdateAvailability.UPDATE_NOT_AVAILABLE -> "none"
                            else -> "unknown"
                        },
                        "versionCode" to info.availableVersionCode(),
                        "priority" to info.updatePriority(),
                        "staleDays" to info.clientVersionStalenessDays(),
                        "flexibleAllowed" to info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE),
                        "immediateAllowed" to info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE),
                        "installStatus" to statusName(info.installStatus()),
                    ),
                )
            }
            // Not installed from Play, no Play Store, offline: just no update.
            .addOnFailureListener { result.success(mapOf("availability" to "unknown")) }
    }

    private fun start(type: String, result: MethodChannel.Result) {
        val updateType =
            if (type == "immediate") AppUpdateType.IMMEDIATE else AppUpdateType.FLEXIBLE
        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                val inProgress = info.updateAvailability() ==
                    UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
                val available = info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                if (!(available || inProgress) || !info.isUpdateTypeAllowed(updateType)) {
                    result.success("unavailable")
                    return@addOnSuccessListener
                }
                if (updateType == AppUpdateType.FLEXIBLE) manager.registerListener(listener)
                manager.startUpdateFlow(
                    info,
                    activity,
                    AppUpdateOptions.newBuilder(updateType).build(),
                ).addOnSuccessListener { code ->
                    result.success(if (code == Activity.RESULT_OK) "accepted" else "declined")
                }.addOnFailureListener {
                    result.success("failed")
                }
            }
            .addOnFailureListener { result.success("failed") }
    }

    private fun statusName(status: Int): String = when (status) {
        InstallStatus.PENDING -> "pending"
        InstallStatus.DOWNLOADING -> "downloading"
        InstallStatus.DOWNLOADED -> "downloaded"
        InstallStatus.INSTALLING -> "installing"
        InstallStatus.INSTALLED -> "installed"
        InstallStatus.FAILED -> "failed"
        InstallStatus.CANCELED -> "canceled"
        else -> "unknown"
    }
}
