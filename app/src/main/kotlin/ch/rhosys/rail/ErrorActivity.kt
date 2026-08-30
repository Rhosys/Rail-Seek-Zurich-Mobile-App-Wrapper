package ch.rhosys.rail

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

/**
 * Catches uncaught exceptions and displays them so crashes are diagnosable
 * instead of silent. Never shows in production to end users — once the TWA
 * is stable this screen should never appear.
 */
class ErrorActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val message = intent.getStringExtra("error_message") ?: "Unknown error"
        val stacktrace = intent.getStringExtra("error_stacktrace") ?: ""

        val padding = (16 * resources.displayMetrics.density).toInt()

        val titleView = TextView(this).apply {
            text = "Rail & Seek crashed"
            textSize = 20f
            setTextColor(0xFF1B2440.toInt())
            setPadding(0, 0, 0, padding / 2)
        }

        val messageView = TextView(this).apply {
            text = message
            textSize = 16f
            setTextColor(0xFF1B2440.toInt())
            setPadding(0, 0, 0, padding)
        }

        val stackView = TextView(this).apply {
            text = stacktrace
            textSize = 11f
            setTextColor(0xFF1B2440.toInt())
            setTypeface(android.graphics.Typeface.MONOSPACE)
        }

        val copyButton = Button(this).apply {
            text = "Copy to clipboard"
            setOnClickListener {
                val clip = ClipData.newPlainText("Rail & Seek crash", "$message\n\n$stacktrace")
                (getSystemService(CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(clip)
                Toast.makeText(this@ErrorActivity, "Copied", Toast.LENGTH_SHORT).show()
            }
        }

        val retryButton = Button(this).apply {
            text = "Retry"
            setOnClickListener {
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                if (intent != null) {
                    startActivity(intent)
                }
                finish()
            }
        }

        val scrollContent = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
            addView(titleView)
            addView(messageView)
            addView(copyButton)
            addView(retryButton)
            addView(stackView)
        }

        val scrollView = ScrollView(this).apply {
            setBackgroundColor(0xFFF6F2E7.toInt())
            addView(scrollContent)
        }

        setContentView(scrollView)
    }
}
