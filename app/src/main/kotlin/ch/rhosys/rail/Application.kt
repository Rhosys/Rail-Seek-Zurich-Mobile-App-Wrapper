package ch.rhosys.rail

import android.app.Application as AndroidApplication
import android.util.Log

class Application : AndroidApplication() {
    override fun onCreate() {
        super.onCreate()

        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            Log.e("RailAndSeek", "Uncaught exception on ${thread.name}", throwable)
            try {
                val intent = android.content.Intent(this, ErrorActivity::class.java).apply {
                    addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    putExtra("error_message", throwable.message ?: "Unknown error")
                    putExtra("error_stacktrace", throwable.stackTraceToString())
                }
                startActivity(intent)
            } catch (e: Exception) {
                Log.e("RailAndSeek", "Failed to launch error activity", e)
            }
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }
}
