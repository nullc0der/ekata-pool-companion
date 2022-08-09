package io.ekata.ekatapoolcompanion.utils

import android.util.Log
import java.util.*

class ProcessObserver(process: Process) : Thread() {
    private var process: Process? = null
    private val listeners: MutableList<ProcessListener> = ArrayList()

    fun interface ProcessListener : EventListener {
        fun onProcessFinished()
    }

    init {
        try {
            process.exitValue()
            throw IllegalArgumentException("The process is already ended")
        } catch (exc: IllegalThreadStateException) {
            this.process = process
        }
    }

    override fun run() {
        try {
            process!!.waitFor()
            for (listener in listeners) {
                listener.onProcessFinished()
            }
        } catch (e: InterruptedException) {
        }
    }

    fun addProcessListener(listener: ProcessListener) {
        listeners.add(listener)
    }

    fun removeProcessListener(listener: ProcessListener) {
        listeners.remove(listener)
    }
}