package io.ekata.ekatapoolcompanion

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import io.ekata.ekatapoolcompanion.events.MiningStartEvent
import io.ekata.ekatapoolcompanion.events.MiningStopEvent
import io.ekata.ekatapoolcompanion.utils.MinerLogger
import io.ekata.ekatapoolcompanion.utils.ProcessObserver
import org.greenrobot.eventbus.EventBus

private const val NOTIFICATION_ID = 1

class MinerService : Service() {
    private lateinit var wakeLock: PowerManager.WakeLock
    private lateinit var process: Process

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val minerConfigPath = intent?.getStringExtra(Constants.MINER_CONFIG_PATH)
        val threadCount = intent?.getIntExtra(Constants.THREAD_COUNT, 0)
        val minerBinary = intent?.getStringExtra(Constants.MINER_BINARY)
        val xmrigCCServerUrl = intent?.getStringExtra(Constants.XMRIGCC_SERVER_URL)
        val xmrigCCServerToken = intent?.getStringExtra(Constants.XMRIGCC_SERVER_TOKEN)
        val xmrigCCWorkerId = intent?.getStringExtra(Constants.XMRIGCC_WORKER_ID)

        val stopMiningPendingIntent =
            Intent(this, StopMiningReceiver::class.java).let { stopMiningIntent ->
                stopMiningIntent.action = Constants.STOP_MINING
                PendingIntent.getBroadcast(
                    this, 0, stopMiningIntent, PendingIntent.FLAG_IMMUTABLE
                )
            }

        val pendingIntent: PendingIntent = Intent(
            this,
            MainActivity::class.java
        ).let { notificationIntent ->
            notificationIntent.action = Constants.FROM_MINER_SERVICE_NOTIFICATION
            notificationIntent.putExtra(Constants.MINER_CONFIG_PATH, minerConfigPath)
            notificationIntent.putExtra(Constants.THREAD_COUNT, threadCount)
            PendingIntent.getActivity(
                this,
                0,
                notificationIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
        val notification: Notification =
            Notification.Builder(this, Constants.NOTIFICATION_CHANNEL_ID)
                .setContentTitle(getText(R.string.mining_notification_title))
                .setContentText(getString(R.string.mining_notification_text))
                .setSmallIcon(R.mipmap.launcher_icon)
                .setContentIntent(pendingIntent)
                .setTicker(getText(R.string.mining_notification_ticker))
                .addAction(
                    R.drawable.ic_baseline_power_settings_new_24,
                    getString(R.string.stop_mining),
                    stopMiningPendingIntent
                )
                .build()
        if (minerConfigPath != null) {
            startForeground(NOTIFICATION_ID, notification)
            startMiner(
                minerConfigPath,
                threadCount,
                minerBinary,
                xmrigCCServerUrl,
                xmrigCCServerToken,
                xmrigCCWorkerId
            )
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onDestroy() {
        stopMiner()
        super.onDestroy()
    }

    @SuppressLint("WakelockTimeout")
    private fun startMiner(
        minerConfigPath: String,
        threadCount: Int?,
        minerBinary: String?,
        xmrigCCServerUrl: String?,
        xmrigCCServerToken: String?,
        xmrigCCWorkerId: String?
    ) {
        wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "EkataPoolCompanion::WakeLock"
            ).apply { acquire() }
        }
        if (this::process.isInitialized && process.isAlive) {
            process.destroy()
        }
        try {
            val args = mutableListOf(
                ".${applicationInfo.nativeLibraryDir}/lib${if (minerBinary != null && minerBinary == "xmrigCC") "xmrigDaemon" else "xmrig"}.so",
                "--config=$minerConfigPath",
                "--http-host=127.0.0.1",
                "--http-port=45580",
                "--cpu-no-yield",
            )
            if (threadCount != null && threadCount > 0) {
                args.add("--threads=$threadCount")
            }
            if (minerBinary != null && minerBinary == "xmrigCC") {
                args.add("--cc-url=$xmrigCCServerUrl")
                args.add("--cc-access-token=$xmrigCCServerToken")
                if (xmrigCCWorkerId != null && xmrigCCWorkerId.isNotEmpty()) {
                    args.add("--cc-worker-id=$xmrigCCWorkerId")
                }
            }
            ProcessBuilder(args).apply { process = start() }
            ProcessObserver(process).apply {
                addProcessListener { EventBus.getDefault().post(MiningStopEvent()) }
                start()
            }
            MinerLogger(process.inputStream).start()
            EventBus.getDefault().post(MiningStartEvent())
        } catch (e: Exception) {
            wakeLock.release()
        }
    }

    private fun stopMiner() {
        wakeLock.release()
        process.destroy()
    }

    private fun getThreadCount(): Int {
        val availableProcessors = Runtime.getRuntime().availableProcessors()
        return availableProcessors * 2
    }
}