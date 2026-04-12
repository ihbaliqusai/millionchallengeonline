package com.Qi7bali.millionchallengeonline

import android.content.Intent
import android.provider.Settings
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
                    "launchOfflineGame" -> {
                        val intent = Intent(this, GameActivity::class.java).apply {
                            putExtra("mode", "mono")
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "launchStats" -> {
                        startActivity(Intent(this, StatsActivity::class.java))
                        result.success(true)
                    }
                    "launchAchievements" -> {
                        startActivity(Intent(this, AchievementsActivity::class.java))
                        result.success(true)
                    }
                    "launchStore" -> {
                        startActivity(Intent(this, StoreActivity::class.java))
                        result.success(true)
                    }
                    "launchSettings" -> {
                        startActivity(Intent(this, SettingsActivity::class.java))
                        result.success(true)
                    }
                    "launchSpeedBattle" -> {
                        // يفتح شاشة البحث عن خصم عشوائي مباشرة
                        val intent = Intent(this, OpponentActivity::class.java)
                        startActivity(intent)
                        result.success(true)
                    }
                    "getUserCurrency" -> {
                        val coins = AppPrefs.getCoins(this)
                        val gems  = AppPrefs.getGems(this)
                        result.success(mapOf("coins" to coins, "gems" to gems))
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
                    "getPlayerStats" -> {
                        val games         = PlayerStats.getGamesPlayed(this)
                        val wins          = PlayerStats.getWins(this)
                        val losses        = PlayerStats.getLosses(this)
                        val correct       = PlayerStats.getCorrectAnswers(this)
                        val wrong         = PlayerStats.getWrongAnswers(this)
                        val total         = correct + wrong
                        val streak        = PlayerStats.getBestStreak(this)
                        val highest       = PlayerStats.getHighestMoney(this)
                        val totalEarnings = PlayerStats.getTotalEarnings(this)
                        val winPct        = if (games > 0) (wins * 100 / games) else 0
                        val accPct        = if (total > 0) (correct * 100 / total) else 0
                        result.success(mapOf(
                            "gamesPlayed"    to games,
                            "wins"           to wins,
                            "losses"         to losses,
                            "correctAnswers" to correct,
                            "wrongAnswers"   to wrong,
                            "totalAnswered"  to total,
                            "bestStreak"     to streak,
                            "highestMoney"   to highest,
                            "totalEarnings"  to totalEarnings,
                            "winPercent"     to winPct,
                            "accuracy"       to accPct
                        ))
                    }
                    "getSettings" -> {
                        result.success(mapOf(
                            "sfx"    to AppPrefs.isSoundEnabled(this),
                            "music"  to AppPrefs.isMusicEnabled(this),
                            "haptic" to AppPrefs.isHapticEnabled(this)
                        ))
                    }
                    "setSoundEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        AppPrefs.setSoundEnabled(this, enabled)
                        result.success(true)
                    }
                    "setMusicEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        AppPrefs.setMusicEnabled(this, enabled)
                        result.success(true)
                    }
                    "setHapticEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        AppPrefs.setHapticEnabled(this, enabled)
                        result.success(true)
                    }
                    "openNotificationSettings" -> {
                        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "restorePurchases" -> {
                        // Placeholder: wire up to billing client when ready
                        result.success(false)
                    }
                    "getInventory" -> {
                        result.success(mapOf(
                            "inv5050"      to PlayerProgress.getInventory5050(this),
                            "invAudience"  to PlayerProgress.getInventoryAudience(this),
                            "invCall"      to PlayerProgress.getInventoryCall(this)
                        ))
                    }
                    "buyPowerUp" -> {
                        val type     = call.argument<String>("type")     ?: ""
                        val quantity = call.argument<Int>("quantity")    ?: 1
                        val payWith  = call.argument<String>("payWith")  ?: "coins"
                        val cost     = call.argument<Int>("cost")        ?: 0
                        val success  = if (payWith == "coins") {
                            PlayerProgress.spendCoins(this, cost)
                        } else {
                            PlayerProgress.spendGems(this, cost)
                        }
                        if (success) {
                            PlayerProgress.addInventory(this, type, quantity)
                        }
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}