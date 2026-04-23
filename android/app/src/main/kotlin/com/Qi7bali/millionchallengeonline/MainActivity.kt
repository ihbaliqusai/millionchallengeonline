package net.androidgaming.millionaire2024

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
                        }
                        startActivity(intent)
                        result.success(true)
                        finish()
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
                    "deliverPurchase" -> {
                        val productId = call.argument<String>("productId") ?: ""
                        val deliveryKey = call.argument<String>("deliveryKey") ?: ""
                        if (deliveryKey.isNotBlank() && AppPrefs.isPurchaseDelivered(this, deliveryKey)) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
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
                        }
                        if (deliveryKey.isNotBlank()) {
                            AppPrefs.markPurchaseDelivered(this, deliveryKey)
                        }
                        result.success(true)
                    }
                    "buyCurrency" -> {
                        val coinAmount = call.argument<Int>("coinAmount") ?: 0
                        val gemCost    = call.argument<Int>("gemCost")    ?: 0
                        val ok         = PlayerProgress.spendGems(this, gemCost)
                        if (ok) PlayerProgress.addCoins(this, coinAmount)
                        result.success(ok)
                    }
                    "restorePurchases" -> {
                        // Consumable items on Google Play don't need restore.
                        result.success(false)
                    }
                    "getAchievements" -> {
                        // Check count-based achievements before returning statuses
                        val games = PlayerStats.getGamesPlayed(this)
                        val wins  = PlayerStats.getWins(this)
                        val correct = PlayerStats.getCorrectAnswers(this)
                        val onlineWins = PlayerProgress.getOnlineWins(this)
                        val blitzFinishes = PlayerProgress.getBlitzFinishes(this)
                        val eliminationWins = PlayerProgress.getEliminationWins(this)
                        val survivalWins = PlayerProgress.getSurvivalWins(this)
                        val seriesWins = PlayerProgress.getSeriesWins(this)
                        val teamBattleWins = PlayerProgress.getTeamBattleWins(this)
                        if (games >= 10)  PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_GAMES_10)
                        if (games >= 25)  PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_GAMES_25)
                        if (games >= 50)  PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_GAMES_50)
                        if (games >= 100) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_GAMES_100)
                        if (wins >= 5)    PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_WIN_5)
                        if (wins >= 10)   PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_WIN_10)
                        if (wins >= 25)   PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_WIN_25)
                        if (wins >= 50)   PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_WIN_50)
                        if (wins >= 100)  PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_WIN_100)
                        if (correct >= 50)   PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_CORRECT_50)
                        if (correct >= 100)  PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_CORRECT_100)
                        if (correct >= 500)  PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_CORRECT_500)
                        if (correct >= 1000) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_CORRECT_1000)
                        if (correct >= 5000) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_CORRECT_5000)
                        if (onlineWins >= 5) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_ONLINE_WIN_5)
                        if (onlineWins >= 10) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_ONLINE_WIN_10)
                        if (blitzFinishes >= 5) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_BLITZ_FINISH_5)
                        if (eliminationWins >= 3) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_ELIMINATION_WIN_3)
                        if (survivalWins >= 3) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_SURVIVAL_WIN_3)
                        if (seriesWins >= 3) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_SERIES_WIN_3)
                        if (teamBattleWins >= 5) PlayerProgress.unlockAchievement(this, PlayerProgress.ACH_TEAM_BATTLE_WIN_5)

                        // Check ACH_ALL_DONE after updating
                        PlayerProgress.checkAllDone(this)

                        val allKeys = listOf(
                            "ACH_FIRST_GAME", "ACH_FIRST_WIN", "ACH_FIRST_ONLINE", "ACH_BUY_POWERUP",
                            "ACH_LEVEL_5", "ACH_LEVEL_10", "ACH_LEVEL_20", "ACH_LEVEL_30", "ACH_LEVEL_50",
                            "ACH_WIN_5", "ACH_WIN_10", "ACH_WIN_25", "ACH_WIN_50", "ACH_WIN_100",
                            "ACH_CORRECT_50", "ACH_CORRECT_100", "ACH_CORRECT_500", "ACH_CORRECT_1000", "ACH_CORRECT_5000",
                            "ACH_PRIZE_1000", "ACH_PRIZE_32000", "ACH_PRIZE_500000", "ACH_PRIZE_1000000",
                            "ACH_STREAK_3", "ACH_STREAK_5", "ACH_STREAK_10", "ACH_STREAK_15",
                            "ACH_GAMES_10", "ACH_GAMES_25", "ACH_GAMES_50", "ACH_GAMES_100",
                            "ACH_COINS_1000", "ACH_COINS_5000", "ACH_COINS_10000", "ACH_GEMS_50", "ACH_GEMS_500",
                            "ACH_USE_5050", "ACH_USE_AUDIENCE", "ACH_USE_CALL", "ACH_USE_ALL_HELPS",
                            "ACH_PERFECT_GAME", "ACH_ONLINE_WIN_5", "ACH_ONLINE_WIN_10",
                            "ACH_BLITZ_FINISH_5", "ACH_ELIMINATION_WIN_3", "ACH_SURVIVAL_WIN_3",
                            "ACH_SERIES_WIN_3", "ACH_TEAM_BATTLE_WIN_5", "ACH_ALL_DONE"
                        )
                        val map = mutableMapOf<String, Any>()
                        for (k in allKeys) map[k] = PlayerProgress.isAchievementUnlocked(this, k)

                        // Progress counters
                        map["gamesPlayed"]    = games
                        map["wins"]           = wins
                        map["correctAnswers"] = correct
                        map["bestStreak"]     = PlayerStats.getBestStreak(this)
                        map["coins"]          = PlayerProgress.getCoins(this)
                        map["gems"]           = PlayerProgress.getGems(this)
                        map["level"]          = PlayerProgress.getLevel(this)
                        map["totalEarnings"]  = PlayerStats.getTotalEarnings(this).toInt()
                        map["onlineWins"]     = onlineWins
                        map["blitzFinishes"]  = blitzFinishes
                        map["eliminationWins"] = eliminationWins
                        map["survivalWins"]   = survivalWins
                        map["seriesWins"]     = seriesWins
                        map["teamBattleWins"] = teamBattleWins

                        result.success(map)
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
