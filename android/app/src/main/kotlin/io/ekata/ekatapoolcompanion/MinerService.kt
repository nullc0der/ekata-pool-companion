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

const val NOTIFICATION_CHANNEL_ID = "io.ekata.ekatapoolcompanion"
private const val NOTIFICATION_ID = 1
const val FROM_MINER_SERVICE_NOTIFICATION =
    "io.ekata.ekatapoolcompanion.FROM_MINER_SERVICE_NOTIFICATION"
const val STOP_MINING = "io.ekata.ekatapoolcompanion.STOP_MINING"

class MinerService : Service() {
    private lateinit var wakeLock: PowerManager.WakeLock
    private lateinit var process: Process

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val walletAddress = intent?.getStringExtra(WALLET_ADDRESS)
        val coinAlgo = intent?.getStringExtra(COIN_ALGO)
        val poolHost = intent?.getStringExtra(POOL_HOST)
        val poolPort = intent?.getIntExtra(POOL_PORT, 3333)
        val threadCount = intent?.getIntExtra(THREAD_COUNT, 0)
        val coinName = intent?.getStringExtra(COIN_NAME)

        val stopMiningPendingIntent =
            Intent(this, StopMiningReceiver::class.java).let { stopMiningIntent ->
                stopMiningIntent.action = STOP_MINING
                PendingIntent.getBroadcast(
                    this, 0, stopMiningIntent, PendingIntent.FLAG_IMMUTABLE
                )
            }

        val pendingIntent: PendingIntent = Intent(
            this,
            MainActivity::class.java
        ).let { notificationIntent ->
            notificationIntent.action = FROM_MINER_SERVICE_NOTIFICATION
            notificationIntent.putExtra(WALLET_ADDRESS, walletAddress)
            notificationIntent.putExtra(COIN_NAME, coinName)
            notificationIntent.putExtra(COIN_ALGO, coinAlgo)
            notificationIntent.putExtra(POOL_HOST, poolHost)
            notificationIntent.putExtra(POOL_PORT, poolPort)
            notificationIntent.putExtra(THREAD_COUNT, threadCount)
            PendingIntent.getActivity(
                this,
                0,
                notificationIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
        val notification: Notification = Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(getText(R.string.mining_notification_title))
            .setContentText(getString(R.string.mining_notification_text, coinName))
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentIntent(pendingIntent)
            .setTicker(getText(R.string.mining_notification_ticker))
            .addAction(
                R.drawable.ic_baseline_power_settings_new_24,
                getString(R.string.stop_mining),
                stopMiningPendingIntent
            )
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
            if (threadCount != null && threadCount > 0) {
                args.add("--threads=$threadCount")
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