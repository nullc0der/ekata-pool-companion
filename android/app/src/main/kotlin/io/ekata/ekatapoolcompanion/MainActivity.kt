package io.ekata.ekatapoolcompanion

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.ekata.ekatapoolcompanion.events.MinerLogEvent
import io.ekata.ekatapoolcompanion.events.MiningStartEvent
import io.ekata.ekatapoolcompanion.events.MiningStopEvent
import io.ekata.ekatapoolcompanion.events.NotificationTapEvent
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
            minerServiceIntent = Intent(this, MinerService::class.java)
            EventBus.getDefault()
                .postSticky(
                    NotificationTapEvent(
                        mapOf(
                            "minerConfigPath" to minerConfigPath.toString(),
                            "threadCount" to threadCount.toString(),
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
                minerServiceIntent.putExtra(
                    Constants.MINER_CONFIG_PATH, call.argument<String>(
                        Constants.MINER_CONFIG_PATH
                    )
                )
                minerServiceIntent.putExtra(
                    Constants.THREAD_COUNT,
                    call.argument<Int>(Constants.THREAD_COUNT)
                )
                startForegroundService(
                    minerServiceIntent
                )
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
