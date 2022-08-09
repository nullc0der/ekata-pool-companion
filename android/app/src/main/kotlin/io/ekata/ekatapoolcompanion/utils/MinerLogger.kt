package io.ekata.ekatapoolcompanion.utils

import android.util.Log
import io.ekata.ekatapoolcompanion.events.MinerLogEvent
import org.greenrobot.eventbus.EventBus
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStream
import java.io.InputStreamReader

class MinerLogger(inputStream: InputStream) : Thread() {
    private var inputStream: InputStream? = null

    init {
        this.inputStream = inputStream
    }

    override fun run() {
        try {
            val bufferedReader: BufferedReader = BufferedReader(InputStreamReader(inputStream))
            var output: String = ""
            while (bufferedReader.readLine().also { output = it } != null) {
                EventBus.getDefault().post(MinerLogEvent(output))
                if (currentThread().isInterrupted) return
            }
        } catch (e: IOException) {

        }
    }
}