package io.ekata.ekatapoolcompanion

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.ekata.ekatapoolcompanion.events.MinerLogEvent
import io.ekata.ekatapoolcompanion.events.MiningStartEvent
import io.ekata.ekatapoolcompanion.events.MiningStopEvent
import io.ekata.ekatapoolcompanion.events.NotificationTapEvent
import io.ekata.ekatapoolcompanion.models.CCMinerArgs
import io.ekata.ekatapoolcompanion.models.XmrigCCMinerArgs
import io.ekata.ekatapoolcompanion.models.XmrigMinerArgs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode

class MainActivity : FlutterActivity() {
    private lateinit var minerServiceIntent: Intent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        onNewIntent(intent)
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            Constants.NOTIFICATION_CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply { description = getString(R.string.notification_channel_description) }
        val notificationManager: NotificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val intentExtras = intent.extras
        if (intentExtras != null && intent.action == Constants.FROM_MINER_SERVICE_NOTIFICATION
        ) {
            val minerConfigPath = intentExtras.getString(Constants.MINER_CONFIG_PATH)
            val threadCount = intentExtras.getInt(Constants.THREAD_COUNT, 0)
            val minerBinary = intentExtras.getString(Constants.MINER_BINARY)
            minerServiceIntent = Intent(this, MinerService::class.java)
            EventBus.getDefault()
                .postSticky(
                    NotificationTapEvent(
                        mapOf(
                            "minerConfigPath" to minerConfigPath.toString(),
                            "threadCount" to threadCount.toString(),
                            "minerBinary" to minerBinary.toString()
                        )
                    )
                )
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "io.ekata.ekatapoolcompanion/miner_method_channel"
        ).setMethodCallHandler { call, result ->
            if (call.method == "startMining") {
                minerServiceIntent = Intent(this, MinerService::class.java)
                val minerBinary = call.argument<String>(Constants.MINER_BINARY)
                minerServiceIntent.putExtra(Constants.MINER_BINARY, minerBinary)
                if (minerBinary == "xmrig") {
                    val xmrigMinerArgs = XmrigMinerArgs(
                        call.argument<String>(Constants.MINER_CONFIG_PATH),
                        call.argument<Int>(Constants.THREAD_COUNT) ?: 0
                    )
                    minerServiceIntent.putExtra(Constants.XMRIG_MINER_ARGS, xmrigMinerArgs)
                }
                if (minerBinary == "xmrigCC") {
                    val xmrigCCMinerArgs = XmrigCCMinerArgs(
                        call.argument<String>(Constants.MINER_CONFIG_PATH),
                        call.argument<Int>(Constants.THREAD_COUNT) ?: 0,
                        call.argument<String>(Constants.XMRIGCC_SERVER_URL),
                        call.argument<String>(Constants.XMRIGCC_SERVER_TOKEN),
                        call.argument<String>(Constants.XMRIGCC_WORKER_ID)
                    )
                    minerServiceIntent.putExtra(Constants.XMRIGCC_MINER_ARGS, xmrigCCMinerArgs)
                }
                if (minerBinary == "ccminer") {
                    val ccMinerArgs = CCMinerArgs(
                        call.argument<String>(Constants.CC_MINER_BINARY_VARIANT),
                        call.argument<String>(Constants.CC_MINER_ALGO),
                        call.argument<String>(Constants.CC_MINER_POOL_URL),
                        call.argument<String>(Constants.CC_MINER_USERNAME),
                        call.argument<String>(Constants.CC_MINER_RIGID),
                        call.argument<String>(Constants.CC_MINER_PASSWORD),
                        call.argument<Int>(Constants.THREAD_COUNT) ?: 0,
                        call.argument<String>(Constants.MINER_CONFIG_PATH),
                    )
                    minerServiceIntent.putExtra(Constants.CC_MINER_ARGS, ccMinerArgs)
                }
                startForegroundService(minerServiceIntent)
                result.success(true)
            }
            if (call.method == "stopMining") {
                stopService(minerServiceIntent)
                result.success(true)
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "io.ekata.ekatapoolcompanion/miner_log_channel"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            private var eventSink: EventChannel.EventSink? = null

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                EventBus.getDefault().register(this)
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                EventBus.getDefault().unregister(this)
            }

            @Subscribe(threadMode = ThreadMode.MAIN)
            fun onMinerLogEvent(minerLogEvent: MinerLogEvent) {
                eventSink?.success(minerLogEvent.log)
            }
        })

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "io.ekata.ekatapoolcompanion/miner_event_channel"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            private var eventSink: EventChannel.EventSink? = null

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                EventBus.getDefault().register(this)
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                EventBus.getDefault().unregister(this)
            }

            @Subscribe
            fun onStartMiningEvent(miningStartEvent: MiningStartEvent) {
                eventSink?.success(Constants.MINER_PROCESS_STARTED)
            }

            @Subscribe(threadMode = ThreadMode.MAIN)
            fun onStopMiningEvent(miningStopEvent: MiningStopEvent) {
                eventSink?.success(Constants.MINER_PROCESS_STOPPED)
            }
        })

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "io.ekata.ekatapoolcompanion/notification_tap_event_channel"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            private var eventSink: EventChannel.EventSink? = null

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                EventBus.getDefault().register(this)
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                EventBus.getDefault().unregister(this)
            }

            @Subscribe(sticky = true)
            fun onNotificationTapEvent(notificationTapEvent: NotificationTapEvent) {
                eventSink?.success(notificationTapEvent.data)
            }
        })
    }
}
