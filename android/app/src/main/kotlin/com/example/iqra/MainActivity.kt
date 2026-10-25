package com.example.iqra
import android.content.Intent
import android.os.Build
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyLockScreenFlags(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        applyLockScreenFlags(intent)
    }

    override fun onStop() {
        super.onStop()
        setLockScreenFlags(false)
    }

    // يُفعَّل العرض فوق القفل فقط إذا فُتح التطبيق من إشعار الأذان
    private fun applyLockScreenFlags(intent: Intent?) {
        setLockScreenFlags(intent?.action == "SELECT_NOTIFICATION")
    }

    private fun setLockScreenFlags(enabled: Boolean) {
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(enabled)
            setTurnScreenOn(enabled)
        }
    }
}