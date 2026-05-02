package net.androidgaming.millionaire2024

import android.Manifest
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

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
                    "grantCurrency" -> {
                        val coins = call.argument<Int>("coins") ?: 0
                        val gems = call.argument<Int>("gems") ?: 0
                        if (coins != 0) {
                            PlayerProgress.addCoins(this, coins)
                        }
                        if (gems != 0) {
                            PlayerProgress.addGems(this, gems)
                        }
                        result.success(
                            mapOf(
                                "coins" to PlayerProgress.getCoins(this),
                                "gems" to PlayerProgress.getGems(this)
                            )
                        )
                    }
                    "launchRoomMatch" -> {
                        val matchMode = call.argument<String>("matchMode") ?: "battle"
                        val activityClass = when (matchMode) {
                            "elimination" -> EliminationGameActivity::class.java
                            "blitz"       -> BlitzGameActivity::class.java
                            "survival"    -> SurvivalGameActivity::class.java
                            "series"      -> SeriesGameActivity::class.java
                            "team_battle" -> TeamBattleGameActivity::class.java
                            else          -> BattleGameActivity::class.java
                        }
                        val intent = Intent(this, activityClass).apply {
                            putExtra("roomId", call.argument<String>("roomId") ?: "")
                            putExtra("mode", "online")
                            putExtra("opponentsJson", call.argument<String>("opponentsJson") ?: "[]")
                            putExtra("meOwner", call.argument<Boolean>("meOwner") ?: false)
                            putExtra("matchMode", matchMode)
                            putExtra("seriesTarget", call.argument<Int>("seriesTarget") ?: 2)
                            putExtra("roundDurationSeconds", call.argument<Int>("roundDurationSeconds") ?: 30)
                            putExtra("myTeam", call.argument<String>("myTeam") ?: "")
                            putExtra("roomRoundNumber", call.argument<Int>("roomRoundNumber") ?: 1)
                            putExtra("resumeExistingGame", call.argument<Boolean>("resumeExistingGame") ?: false)
                            putExtra("seatSourceId", call.argument<String>("seatSourceId") ?: "")
                            putExtra("initialScore", call.argument<Int>("initialScore") ?: 0)
                            putExtra("initialAnsweredCount", call.argument<Int>("initialAnsweredCount") ?: 0)
                            putExtra("initialRoundWins", call.argument<Int>("initialRoundWins") ?: 0)
                            putExtra("initialLivesRemaining", call.argument<Int>("initialLivesRemaining") ?: 0)
                            putExtra("initiallyEliminated", call.argument<Boolean>("initiallyEliminated") ?: false)
                        }
                        startActivity(intent)
                        result.success(true)
                        finish()
                    }
                    "announceRoomSeatClaim" -> {
                        Data.announceRoomSeatClaim(
                            call.argument<String>("roomId") ?: "",
                            call.argument<String>("matchMode") ?: "battle",
                            call.argument<Int>("roomRoundNumber") ?: 1,
                            call.argument<String>("seatId") ?: "",
                            call.argument<String>("userId") ?: "",
                            call.argument<String>("username") ?: "لاعب",
                            call.argument<String>("photoUrl") ?: "",
                            call.argument<String>("teamId") ?: "",
                            call.argument<Int>("initialScore") ?: 0,
                            call.argument<Int>("initialRoundWins") ?: 0,
                            call.argument<Int>("initialLivesRemaining") ?: 0,
                            call.argument<Boolean>("initiallyEliminated") ?: false
                        )
                        result.success(true)
                    }
                    "consumePendingRoomMatchResult" -> {
                        result.success(AppPrefs.consumePendingRoomMatchResult(this))
                    }
                    "getPendingRoomMatchResult" -> {
                        result.success(AppPrefs.getPendingRoomMatchResult(this))
                    }
                    "clearPendingRoomMatchResult" -> {
                        AppPrefs.clearPendingRoomMatchResult(this)
                        result.success(true)
                    }
                    "syncLegacyUser" -> {
                        val uid = call.argument<String>("uid") ?: "guest_local"
                        val username = call.argument<String>("username") ?: "لاعب"
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
                        val bestStreak    = PlayerStats.getBestStreak(this)
                        val winStreak     = PlayerStats.getCurrentWinStreak(this)
                        val bestWinStreak = PlayerStats.getBestWinStreak(this)
                        val highest       = PlayerStats.getHighestMoney(this)
                        val totalEarnings = PlayerStats.getTotalEarnings(this)
                        val onlineWins    = PlayerProgress.getOnlineWins(this)
                        val xp            = PlayerProgress.getXp(this)
                        val level         = PlayerProgress.getLevel(this)
                        val winPct        = if (games > 0) (wins * 100 / games) else 0
                        val accPct        = if (total > 0) (correct * 100 / total) else 0
                        result.success(mapOf(
                            "gamesPlayed"    to games,
                            "wins"           to wins,
                            "losses"         to losses,
                            "correctAnswers" to correct,
                            "wrongAnswers"   to wrong,
                            "totalAnswered"  to total,
                            "bestStreak"     to bestStreak,
                            "winStreak"      to winStreak,
                            "bestWinStreak"  to bestWinStreak,
                            "highestMoney"   to highest,
                            "totalEarnings"  to totalEarnings,
                            "onlineWins"     to onlineWins,
                            "xp"             to xp,
                            "level"          to level,
                            "winPercent"     to winPct,
                            "accuracy"       to accPct
                        ))
                    }
                    "getSettings" -> {
                        result.success(mapOf(
                            "sfx"                 to AppPrefs.isSoundEnabled(this),
                            "music"               to AppPrefs.isMusicEnabled(this),
                            "haptic"              to AppPrefs.isHapticEnabled(this),
                            "notifications"       to AppPrefs.isNotificationsEnabled(this),
                            "systemNotifications" to NotificationManagerCompat.from(this).areNotificationsEnabled(),
                            "dialogs"             to AppPrefs.isDialogsEnabled(this),
                            "language"            to AppPrefs.getLanguageCode(this)
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
                    "setNotificationsEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        AppPrefs.setNotificationsEnabled(this, enabled)
                        if (enabled) {
                            NotificationScheduler.scheduleDailyReminder(this)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7401)
                            }
                        } else {
                            NotificationScheduler.cancelDailyReminder(this)
                        }
                        result.success(true)
                    }
                    "setDialogsEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        AppPrefs.setDialogsEnabled(this, enabled)
                        result.success(true)
                    }
                    "setLanguage" -> {
                        val language = call.argument<String>("language") ?: "ar"
                        AppPrefs.setLanguageCode(this, language)
                        result.success(true)
                    }
                    "openNotificationSettings" -> {
                        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "resetLocalProgress" -> {
                        AppPrefs.resetLocalProgress(this)
                        result.success(true)
                    }
                    "deliverPurchase" -> {
                        val productId = call.argument<String>("productId") ?: ""
                        val deliveryKey = call.argument<String>("deliveryKey") ?: ""
                        if (deliveryKey.isNotBlank() && AppPrefs.isPurchaseDelivered(this, deliveryKey)) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        var delivered = true
                        when (productId) {
                            "gems_80"    -> PlayerProgress.addGems(this, 80)
                            "gems_500"   -> PlayerProgress.addGems(this, 500)
                            "gems_1200"  -> PlayerProgress.addGems(this, 1200)
                            "gems_2500"  -> PlayerProgress.addGems(this, 2500)
                            "gems_6500"  -> PlayerProgress.addGems(this, 6500)
                            "gems_14000" -> PlayerProgress.addGems(this, 14000)
                            "pack_starter" -> {
                                PlayerProgress.addGems(this, 120)
                                PlayerProgress.addCoins(this, 500)
                                PlayerProgress.addInventory(this, "5050", 2)
                            }
                            "pack_value" -> {
                                PlayerProgress.addGems(this, 600)
                                PlayerProgress.addCoins(this, 2000)
                                PlayerProgress.addInventory(this, "5050", 3)
                                PlayerProgress.addInventory(this, "audience", 2)
                            }
                            "pack_champion" -> {
                                PlayerProgress.addGems(this, 1800)
                                PlayerProgress.addCoins(this, 10000)
                                PlayerProgress.addInventory(this, "5050", 5)
                                PlayerProgress.addInventory(this, "audience", 3)
                                PlayerProgress.addInventory(this, "call", 2)
                            }
                            else -> delivered = false
                        }
                        if (delivered && deliveryKey.isNotBlank()) {
                            AppPrefs.markPurchaseDelivered(this, deliveryKey)
                        }
                        result.success(delivered)
                    }
                    "buyCurrency" -> {
                        val coinAmount = call.argument<Int>("coinAmount") ?: 0
                        val gemCost    = call.argument<Int>("gemCost")    ?: 0
                        val ok         = coinAmount > 0 && gemCost > 0 && PlayerProgress.spendGems(this, gemCost)
                        if (ok) PlayerProgress.addCoins(this, coinAmount)
                        result.success(ok)
                    }
                    "restorePurchases" -> {
                        // Consumable items on Google Play don't need restore.
                        result.success(false)
                    }
                    "getAchievements" -> {
                        PlayerProgress.checkMilestoneAchievements(this)

                        val games = PlayerStats.getGamesPlayed(this)
                        val wins  = PlayerStats.getWins(this)
                        val losses = PlayerStats.getLosses(this)
                        val correct = PlayerStats.getCorrectAnswers(this)
                        val wrong = PlayerStats.getWrongAnswers(this)
                        val totalAnswered = PlayerStats.getTotalAnswered(this)
                        val accuracy = if (totalAnswered > 0) (correct * 100 / totalAnswered) else 0
                        val onlineWins = PlayerProgress.getOnlineWins(this)
                        val blitzFinishes = PlayerProgress.getBlitzFinishes(this)
                        val eliminationWins = PlayerProgress.getEliminationWins(this)
                        val survivalWins = PlayerProgress.getSurvivalWins(this)
                        val seriesWins = PlayerProgress.getSeriesWins(this)
                        val teamBattleWins = PlayerProgress.getTeamBattleWins(this)
                        val inventoryTotal =
                            PlayerProgress.getInventory5050(this) +
                            PlayerProgress.getInventoryAudience(this) +
                            PlayerProgress.getInventoryCall(this)
                        val map = mutableMapOf<String, Any>()
                        for (k in PlayerProgress.getAllAchievementKeys()) {
                            map[k] = PlayerProgress.isAchievementUnlocked(this, k)
                            map["${k}_CLAIMED"] = PlayerProgress.isAchievementRewardClaimed(this, k)
                        }
                        map["unclaimedAchievements"] = PlayerProgress.getUnclaimedAchievementCount(this)

                        map["gamesPlayed"]    = games
                        map["wins"]           = wins
                        map["losses"]          = losses
                        map["correctAnswers"] = correct
                        map["wrongAnswers"]   = wrong
                        map["totalAnswered"]  = totalAnswered
                        map["accuracy"]       = accuracy
                        map["bestStreak"]     = PlayerStats.getBestStreak(this)
                        map["winStreak"]      = PlayerStats.getCurrentWinStreak(this)
                        map["bestWinStreak"]  = PlayerStats.getBestWinStreak(this)
                        map["coins"]          = PlayerProgress.getCoins(this)
                        map["gems"]           = PlayerProgress.getGems(this)
                        map["level"]          = PlayerProgress.getLevel(this)
                        map["highestMoney"]   = PlayerStats.getHighestMoney(this)
                        map["totalEarnings"]  = PlayerStats.getTotalEarnings(this)
                        map["inventoryTotal"] = inventoryTotal
                        map["onlineWins"]     = onlineWins
                        map["blitzFinishes"]  = blitzFinishes
                        map["eliminationWins"] = eliminationWins
                        map["survivalWins"]   = survivalWins
                        map["seriesWins"]     = seriesWins
                        map["teamBattleWins"] = teamBattleWins

                        result.success(map)
                    }
                    "claimAchievementReward" -> {
                        PlayerProgress.checkMilestoneAchievements(this)
                        val key = call.argument<String>("key") ?: ""
                        val claim = PlayerProgress.claimAchievementReward(this, key)
                        result.success(mapOf(
                            "success" to claim.success,
                            "coins" to claim.coins,
                            "xp" to claim.xp,
                            "totalCoins" to claim.totalCoins,
                            "totalGems" to claim.totalGems,
                            "totalXp" to claim.totalXp,
                            "unclaimedAchievements" to PlayerProgress.getUnclaimedAchievementCount(this)
                        ))
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
                        if (!isValidPowerUp(type) || quantity <= 0 || cost <= 0 || (payWith != "coins" && payWith != "gems")) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
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
                    "grantPowerUp" -> {
                        val type     = call.argument<String>("type") ?: ""
                        val quantity = call.argument<Int>("quantity") ?: 1
                        if (!isValidPowerUp(type) || quantity <= 0) {
                            result.success(false)
                        } else {
                            PlayerProgress.grantInventory(this, type, quantity)
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isValidPowerUp(type: String): Boolean {
        return type == "5050" || type == "audience" || type == "call"
    }
}
