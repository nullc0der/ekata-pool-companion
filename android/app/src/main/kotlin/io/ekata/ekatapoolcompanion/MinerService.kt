package io.ekata.ekatapoolcompanion

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Build.VERSION
import android.os.IBinder
import android.os.PowerManager
import io.ekata.ekatapoolcompanion.events.MiningStartEvent
import io.ekata.ekatapoolcompanion.events.MiningStopEvent
import io.ekata.ekatapoolcompanion.models.CCMinerArgs
import io.ekata.ekatapoolcompanion.models.XmrigCCMinerArgs
import io.ekata.ekatapoolcompanion.models.XmrigMinerArgs
import io.ekata.ekatapoolcompanion.utils.MinerLogger
import io.ekata.ekatapoolcompanion.utils.ProcessObserver
import org.greenrobot.eventbus.EventBus

private const val NOTIFICATION_ID = 1

class MinerService : Service() {
    private lateinit var wakeLock: PowerManager.WakeLock
    private lateinit var process: Process

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val minerBinary = intent?.getStringExtra(Constants.MINER_BINARY)
        var minerConfigPath: String = ""
        var threadCount: Int = 0
        var minerProcessArgs: MutableList<String> = mutableListOf()
        if (minerBinary == "xmrig") {
            val xmrigMinerArgs = if (VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Constants.XMRIG_MINER_ARGS, XmrigMinerArgs::class.java)
            } else {
                intent.getParcelableExtra<XmrigMinerArgs>(Constants.XMRIG_MINER_ARGS)
            }
            if (xmrigMinerArgs != null && !xmrigMinerArgs.minerConfigPath.isNullOrEmpty()) {
                minerProcessArgs = mutableListOf(
                    ".${applicationInfo.nativeLibraryDir}/libxmrig.so",
                    "--config=${xmrigMinerArgs.minerConfigPath}",
                    "--http-host=127.0.0.1",
                    "--http-port=45580",
                    "--cpu-no-yield",
                )
                if (xmrigMinerArgs.threadCount > 0) {
                    minerProcessArgs.add(
                        "--threads=${xmrigMinerArgs.threadCount}"
                    )
                }
                minerConfigPath = xmrigMinerArgs.minerConfigPath
                threadCount = xmrigMinerArgs.threadCount
            }
        }
        if (minerBinary == "xmrigCC") {
            val xmrigCCMinerArgs = if (VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(
                    Constants.XMRIGCC_MINER_ARGS, XmrigCCMinerArgs::class.java
                )
            } else {
                intent.getParcelableExtra<XmrigCCMinerArgs>(Constants.XMRIGCC_MINER_ARGS)
            }
            if (xmrigCCMinerArgs != null && !xmrigCCMinerArgs.minerConfigPath.isNullOrEmpty()) {
                minerProcessArgs = mutableListOf(
                    ".${applicationInfo.nativeLibraryDir}/libxmrigDaemon.so",
                    "--config=${xmrigCCMinerArgs.minerConfigPath}",
                    "--cc-url=${xmrigCCMinerArgs.xmrigCCSeverUrl}",
                    "--cc-access-token=${xmrigCCMinerArgs.xmrigCCServerToken}",
                    "--http-host=127.0.0.1",
                    "--http-port=45580",
                    "--cpu-no-yield",
                )
                if (xmrigCCMinerArgs.threadCount > 0) {
                    minerProcessArgs.add(
                        "--threads=${xmrigCCMinerArgs.threadCount}"
                    )
                }
                if (!xmrigCCMinerArgs.xmrigCCWorkerId.isNullOrEmpty()) {
                    minerProcessArgs.add("--cc-worker-id=${xmrigCCMinerArgs.xmrigCCWorkerId}")
                }
                minerConfigPath = xmrigCCMinerArgs.minerConfigPath
                threadCount = xmrigCCMinerArgs.threadCount
            }
        }
        if (minerBinary == "ccminer") {
            val ccMinerArgs = if (VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Constants.CC_MINER_ARGS, CCMinerArgs::class.java)
            } else {
                intent.getParcelableExtra<CCMinerArgs>(Constants.CC_MINER_ARGS)
            }
            if (ccMinerArgs != null && !ccMinerArgs.minerConfigPath.isNullOrEmpty()) {
                minerProcessArgs = mutableListOf(
                    ".${applicationInfo.nativeLibraryDir}/lib${ccMinerArgs.ccMinerBinaryVariant}.so",
                    "--algo=${ccMinerArgs.algo}",
                    "--url=stratum+tcp://${ccMinerArgs.poolUrl}",
                    "--user=${ccMinerArgs.userName}.${
                        if (!ccMinerArgs.rigId.isNullOrEmpty()) {
                            ccMinerArgs.rigId
                        } else {
                            ""
                        }
                    }",
                    "--pass=${
                        if (!ccMinerArgs.passWord.isNullOrEmpty()) {
                            ccMinerArgs.passWord
                        } else {
                            ""
                        }
                    }",
                    "--api-bind=127.0.0.1:44690",
                    "--api-allow=127.0.0.1",
                )
                if (ccMinerArgs.threadCount > 0) {
                    minerProcessArgs.add(
                        "--threads=${ccMinerArgs.threadCount}"
                    )
                }
                minerConfigPath = ccMinerArgs.minerConfigPath
                threadCount = ccMinerArgs.threadCount
            }
        }

        val stopMiningPendingIntent =
            Intent(this, StopMiningReceiver::class.java).let { stopMiningIntent ->
                stopMiningIntent.action = Constants.STOP_MINING
                PendingIntent.getBroadcast(
                    this, 0, stopMiningIntent, PendingIntent.FLAG_IMMUTABLE
                )
            }

        val pendingIntent: PendingIntent = Intent(
            this, MainActivity::class.java
        ).let { notificationIntent ->
            notificationIntent.action = Constants.FROM_MINER_SERVICE_NOTIFICATION
            notificationIntent.putExtra(Constants.MINER_CONFIG_PATH, minerConfigPath)
            notificationIntent.putExtra(Constants.THREAD_COUNT, threadCount)
            notificationIntent.putExtra(Constants.MINER_BINARY, minerBinary)
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
                .setSmallIcon(R.mipmap.launcher_icon).setContentIntent(pendingIntent)
                .setTicker(getText(R.string.mining_notification_ticker)).addAction(
                    R.drawable.ic_baseline_power_settings_new_24,
                    getString(R.string.stop_mining),
                    stopMiningPendingIntent
                ).build()
        if (minerProcessArgs.isNotEmpty()) {
            startForeground(NOTIFICATION_ID, notification)
            startMiner(minerProcessArgs)
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
        minerProcessArgs: List<String>
    ) {
        wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
            newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK, "EkataPoolCompanion::WakeLock"
            ).apply { acquire() }
        }
        if (this::process.isInitialized && process.isAlive) {
            process.destroy()
        }
        try {
            ProcessBuilder(minerProcessArgs).apply { process = start() }
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
        if (this::wakeLock.isInitialized && wakeLock.isHeld) {
            wakeLock.release()
        }
        if (this::process.isInitialized && process.isAlive) {
            process.destroy()
        }
    }

    private fun getThreadCount(): Int {
        val availableProcessors = Runtime.getRuntime().availableProcessors()
        return availableProcessors * 2
    }
}