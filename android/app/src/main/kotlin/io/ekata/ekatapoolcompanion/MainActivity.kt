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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode


const val WALLET_ADDRESS = "io.ekata.ekatapoolcompanion.WALLET_ADDRESS"

class MainActivity : FlutterActivity() {
    private lateinit var minerServiceIntent: Intent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply { description = getString(R.string.notification_channel_description) }
        val notificationManager: NotificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "io.ekata.ekatapoolcompanion/miner_method_channel"
        ).setMethodCallHandler { call, _ ->
            if (call.method == "startMining") {
                minerServiceIntent = Intent(this, MinerService::class.java)
                minerServiceIntent.putExtra(WALLET_ADDRESS, call.argument<String>(WALLET_ADDRESS))
                startForegroundService(
                    minerServiceIntent
                )
            }
            if (call.method == "stopMining") {
                stopService(minerServiceIntent)
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
    }
}
