package io.ekata.ekatapoolcompanion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StopMiningReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == STOP_MINING) {
            val minerServiceIntent = Intent(context, MinerService::class.java)
            context.stopService(minerServiceIntent)
        }
    }
}