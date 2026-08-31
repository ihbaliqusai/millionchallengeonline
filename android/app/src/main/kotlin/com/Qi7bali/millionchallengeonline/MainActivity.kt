package net.androidgaming.millionaire2024

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingLaunchAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        pendingLaunchAction = intent.getStringExtra("launchAction")
        syncDailyReminderSchedule()
    }

    override fun onResume() {
        super.onResume()
        syncDailyReminderSchedule()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingLaunchAction = intent.getStringExtra("launchAction")
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
                        val matchMode = call.argument<String>("matchMode") ?: ""
                        val friendCode = call.argument<String>("friendCode") ?: ""
                        val intent = Intent(this, OpponentActivity::class.java).apply {
                            if (matchMode.isNotEmpty()) putExtra("matchMode", matchMode)
                            if (friendCode.isNotEmpty()) putExtra("friendCode", friendCode)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "launchFriendChallenge" -> {
                        val friendCode = call.argument<String>("friendCode") ?: ""
                        val intent = Intent(this, OpponentActivity::class.java).apply {
                            putExtra("matchMode", "friend")
                            putExtra("friendCode", friendCode)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "getUserCurrency" -> {
                        val coins = AppPrefs.getCoins(this)
                        val gems  = AppPrefs.getGems(this)
                        result.success(mapOf("coins" to coins, "gems" to gems))
                    }
                    "consumeLaunchAction" -> {
                        val action = pendingLaunchAction
                        pendingLaunchAction = null
                        result.success(action)
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
                    "setUserCurrency" -> {
                        val coins = call.argument<Int>("coins") ?: 0
                        val gems = call.argument<Int>("gems") ?: 0
                        PlayerProgress.setCurrency(this, coins, gems)
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
                    }
                    "launchCampaignStage" -> {
                        try {
                            val stageId = stringArg(call.argument<Any>("stageId"), "")
                            val campaignMode = stringArg(call.argument<Any>("campaignMode"), "classic")
                            val winCondition = stringArg(call.argument<Any>("winCondition"), "completeQuestions")
                            Log.d(
                                "CampaignStage",
                                "CAMPAIGN_LAUNCH_CONFIG mode=$campaignMode winCondition=$winCondition stageId=$stageId"
                            )
                            val intent = Intent(this, GameActivity::class.java).apply {
                                putExtra("mode", "campaign")
                                putExtra("campaignId", stringArg(call.argument<Any>("campaignId"), "main_campaign"))
                                putExtra("stageId", stageId)
                                putExtra("stageType", stringArg(call.argument<Any>("stageType"), "classic"))
                                putExtra("campaignMode", campaignMode)
                                putExtra("winCondition", winCondition)
                                putIntegerArrayListExtra("questionIds", intArrayListArg(call.argument<Any>("questionIds")))
                                putStringArrayListExtra("allowedLevels", stringArrayListArg(call.argument<Any>("allowedLevels")))
                                putExtra("questionCount", intArg(call.argument<Any>("questionCount"), 10))
                                putExtra("timeLimitSeconds", intArg(call.argument<Any>("timeLimitSeconds"), 0))
                                putExtra("allow5050", boolArg(call.argument<Any>("allow5050"), true))
                                putExtra("allowAudience", boolArg(call.argument<Any>("allowAudience"), true))
                                putExtra("allowCall", boolArg(call.argument<Any>("allowCall"), true))
                                putExtra("bossBotName", stringArg(call.argument<Any>("bossBotName"), ""))
                                putExtra("bossBotIntelligence", intArg(call.argument<Any>("bossBotIntelligence"), 0))
                                putExtra("lives", intArg(call.argument<Any>("lives"), 0))
                                putExtra("maxWrongAnswers", intArg(call.argument<Any>("maxWrongAnswers"), 0))
                                putExtra("targetScore", intArg(call.argument<Any>("targetScore"), 0))
                                putExtra("opponentName", stringArg(call.argument<Any>("opponentName"), ""))
                                putExtra("opponentAccuracy", intArg(call.argument<Any>("opponentAccuracy"), 0))
                                putExtra("opponentStartScore", intArg(call.argument<Any>("opponentStartScore"), 0))
                                putExtra("seriesRounds", intArg(call.argument<Any>("seriesRounds"), 0))
                                putExtra("seriesWinsRequired", intArg(call.argument<Any>("seriesWinsRequired"), 0))
                                putExtra("teamAllyName", stringArg(call.argument<Any>("teamAllyName"), ""))
                                putExtra("teamEnemyName", stringArg(call.argument<Any>("teamEnemyName"), ""))
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CAMPAIGN_LAUNCH_FAILED", e.message, null)
                        }
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
                    "consumePendingCampaignStageResult" -> {
                        result.success(AppPrefs.consumePendingCampaignStageResult(this))
                    }
                    "getPendingCampaignStageResult" -> {
                        result.success(AppPrefs.getPendingCampaignStageResult(this))
                    }
                    "clearPendingCampaignStageResult" -> {
                        AppPrefs.clearPendingCampaignStageResult(this)
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
                            "hapticAvailable"     to AppHaptics.hasVibrator(this),
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
                        var played = false
                        if (enabled) {
                            played = AppHaptics.medium(this)
                        }
                        result.success(played)
                    }
                    "playHaptic" -> {
                        val style = call.argument<String>("style") ?: "light"
                        val played = if (AppPrefs.isHapticEnabled(this)) {
                            AppHaptics.play(this, style)
                        } else {
                            false
                        }
                        result.success(played)
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
                        openAppNotificationSettings()
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
                        val campaignCompletedStages = PlayerProgress.getCampaignCompletedStages(this)
                        val campaignStars = PlayerProgress.getCampaignStars(this)
                        val campaignBlitzCompletions = PlayerProgress.getCampaignBlitzCompletions(this)
                        val campaignSurvivalCompletions = PlayerProgress.getCampaignSurvivalCompletions(this)
                        val campaignRivalCompletions = PlayerProgress.getCampaignRivalCompletions(this)
                        val campaignSeriesCompletions = PlayerProgress.getCampaignSeriesCompletions(this)
                        val campaignTeamCompletions = PlayerProgress.getCampaignTeamCompletions(this)
                        val campaignNoHelpCompletions = PlayerProgress.getCampaignNoHelpCompletions(this)
                        val campaignBossWins = PlayerProgress.getCampaignBossWins(this)
                        val campaignPerfectCompletions = PlayerProgress.getCampaignPerfectCompletions(this)
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
                        map["campaignCompletedStages"] = campaignCompletedStages
                        map["campaignStars"] = campaignStars
                        map["campaignBlitzCompletions"] = campaignBlitzCompletions
                        map["campaignSurvivalCompletions"] = campaignSurvivalCompletions
                        map["campaignRivalCompletions"] = campaignRivalCompletions
                        map["campaignSeriesCompletions"] = campaignSeriesCompletions
                        map["campaignTeamCompletions"] = campaignTeamCompletions
                        map["campaignNoHelpCompletions"] = campaignNoHelpCompletions
                        map["campaignBossWins"] = campaignBossWins
                        map["campaignPerfectCompletions"] = campaignPerfectCompletions

                        result.success(map)
                    }
                    "recordCampaignAchievementProgress" -> {
                        PlayerProgress.onCampaignStageFinished(
                            this,
                            call.argument<String>("campaignId") ?: "main_campaign",
                            call.argument<String>("stageId") ?: "",
                            call.argument<String>("campaignMode") ?: "classic",
                            call.argument<Boolean>("completed") ?: false,
                            call.argument<Int>("stars") ?: 0,
                            call.argument<Boolean>("bossDefeated") ?: false,
                            call.argument<Int>("usedLifelines") ?: 0
                        )
                        result.success(true)
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
                    "isAppInstalled" -> {
                        val targetPkg = call.argument<String>("packageName") ?: ""
                        if (targetPkg.isBlank()) {
                            result.success(false)
                        } else {
                            try {
                                packageManager.getPackageInfo(targetPkg, 0)
                                result.success(true)
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "launchAppOrPlayStore" -> {
                        val targetPkg = call.argument<String>("packageName") ?: ""
                        val fallbackUrl = call.argument<String>("url") ?: "https://play.google.com/store/apps/details?id=$targetPkg"
                        var launched = false
                        if (targetPkg.isNotBlank()) {
                            try {
                                val launchIntent = packageManager.getLaunchIntentForPackage(targetPkg)
                                if (launchIntent != null) {
                                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    startActivity(launchIntent)
                                    launched = true
                                }
                            } catch (e: Exception) {
                                Log.w("MainActivity", "Failed to launch installed app: $targetPkg", e)
                            }
                        }
                        if (!launched) {
                            try {
                                val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$targetPkg")).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(marketIntent)
                                launched = true
                            } catch (e: Exception) {
                                try {
                                    val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(fallbackUrl)).apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(webIntent)
                                    launched = true
                                } catch (e2: Exception) {
                                    Log.e("MainActivity", "Failed to open Play Store / fallback URL", e2)
                                }
                            }
                        }
                        result.success(launched)
                    }
                    else -> result.notImplemented()
            }
    }
    }

    private fun openAppNotificationSettings() {
        val notificationIntent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        try {
            startActivity(notificationIntent)
        } catch (ignored: Exception) {
            val appSettingsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(appSettingsIntent)
        }
    }

    private fun syncDailyReminderSchedule() {
        if (AppPrefs.isNotificationsEnabled(this)) {
            NotificationScheduler.scheduleDailyReminder(this)
        } else {
            NotificationScheduler.cancelDailyReminder(this)
        }
    }

    private fun isValidPowerUp(type: String): Boolean {
        return type == "5050" || type == "audience" || type == "call"
    }

    private fun stringArg(value: Any?, defaultValue: String): String {
        val text = value?.toString()?.trim() ?: return defaultValue
        return text.ifEmpty { defaultValue }
    }

    private fun intArg(value: Any?, defaultValue: Int): Int {
        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is Number -> value.toInt()
            is String -> value.trim().toIntOrNull() ?: defaultValue
            else -> defaultValue
        }
    }

    private fun boolArg(value: Any?, defaultValue: Boolean): Boolean {
        return when (value) {
            is Boolean -> value
            is Number -> value.toInt() != 0
            is String -> {
                when (value.trim().lowercase()) {
                    "true", "1" -> true
                    "false", "0" -> false
                    else -> defaultValue
                }
            }
            else -> defaultValue
        }
    }

    private fun intArrayListArg(value: Any?): ArrayList<Int> {
        if (value !is Iterable<*>) return arrayListOf()
        val ids = arrayListOf<Int>()
        for (item in value) {
            when (item) {
                is Int -> ids.add(item)
                is Long -> ids.add(item.toInt())
                is Number -> ids.add(item.toInt())
                is String -> item.trim().toIntOrNull()?.let(ids::add)
            }
        }
        return ids
    }

    private fun stringArrayListArg(value: Any?): ArrayList<String> {
        if (value !is Iterable<*>) return arrayListOf()
        val values = arrayListOf<String>()
        for (item in value) {
            val text = item?.toString()?.trim().orEmpty()
            if (text.isNotEmpty()) values.add(text)
        }
        return values
    }
}
