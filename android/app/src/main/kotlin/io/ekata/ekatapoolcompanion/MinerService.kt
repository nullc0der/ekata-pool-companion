package io.ekata.ekatapoolcompanion

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import io.ekata.ekatapoolcompanion.events.MiningStartEvent
import io.ekata.ekatapoolcompanion.events.MiningStopEvent
import io.ekata.ekatapoolcompanion.utils.MinerLogger
import io.ekata.ekatapoolcompanion.utils.ProcessObserver
import org.greenrobot.eventbus.EventBus

const val NOTIFICATION_CHANNEL_ID = "io.ekata.ekatapoolcompanion"
private const val NOTIFICATION_ID = 1

class MinerService : Service() {
    private lateinit var wakeLock: PowerManager.WakeLock
    private lateinit var process: Process

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val walletAddress = intent?.getStringExtra(WALLET_ADDRESS)
        val coinAlgo = intent?.getStringExtra(COIN_ALGO)
        val poolHost = intent?.getStringExtra(POOL_HOST)
        val poolPort = intent?.getIntExtra(POOL_PORT, 3333)
        val threadCount = intent?.getIntExtra(THREAD_COUNT, 0)
        val pendingIntent: PendingIntent = Intent(
            this,
            MainActivity::class.java
        ).let { notificationIntent ->
            PendingIntent.getActivity(
                this,
                0,
                notificationIntent,
                PendingIntent.FLAG_IMMUTABLE
            )
        }
        val notification: Notification = Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(getText(R.string.mining_notification_title))
            .setContentText(getText(R.string.mining_notification_text))
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentIntent(pendingIntent)
            .setTicker(getText(R.string.mining_notification_ticker))
            .build()
        if (walletAddress != null && coinAlgo != null && poolHost != null && poolPort != null) {
            startForeground(NOTIFICATION_ID, notification)
            startMiner(walletAddress, coinAlgo, poolHost, poolPort, threadCount)
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
        address: String,
        coinAlgo: String,
        poolHost: String,
        poolPort: Int,
        threadCount: Int?
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
                ".${applicationInfo.nativeLibraryDir}/libxmrig.so",
                "--url=$poolHost:$poolPort",
                "--algo=$coinAlgo",
                "--user=$address",
                "--http-host=127.0.0.1",
                "--http-port=45580",
                "--no-color",
                "--cpu-no-yield",
            )
            Log.d("MinerService", threadCount.toString())
            if (threadCount != null && threadCount > 0) {
                args.add("--threads=$threadCount")
            }
            Log.d("MinerService", args.joinToString(","));
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