package com.Qi7bali.millionchallengeonline

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "millionaire/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchOriginal" -> {
                        startActivity(Intent(this, LegacyMainActivity::class.java))
                        result.success(true)
                        finish()
                    }
                    "launchRoomMatch" -> {
                        val intent = Intent(this, GameActivity::class.java).apply {
                            putExtra("mode", "online")
                            putExtra("opponentsJson", call.argument<String>("opponentsJson") ?: "[]")
                            putExtra("meOwner", call.argument<Boolean>("meOwner") ?: false)
                        }
                        startActivity(intent)
                        result.success(true)
                        finish()
                    }
                    "syncLegacyUser" -> {
                        val uid = call.argument<String>("uid") ?: "guest_local"
                        val username = call.argument<String>("username") ?: "Guest"
                        val photoUrl = call.argument<String>("photoUrl") ?: ""
                        val level = AppPrefs.getUserLevel(this)
                        val score = AppPrefs.getUserScore(this)
                        AppPrefs.setUser(
                            this,
                            uid,
                            username,
                            photoUrl,
                            level,
                            score
                        )
                        if (uid != "guest_local") {
                            Data.syncUserProfile(uid, username, photoUrl, level, score)
                            Data.setUserActive(uid)
                        }
                        result.success(true)
                    }
                    "resetLegacyUser" -> {
                        AppPrefs.setGuestUser(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
