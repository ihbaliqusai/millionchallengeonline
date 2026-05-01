package net.androidgaming.millionaire2024;

import android.content.Context;
import android.content.SharedPreferences;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class PlayerProgress {
    private static final String PREF = "PlayerProgress";
    private static final int MATCH_COMPLETION_BONUS = 200;

    public static final String ACH_FIRST_GAME = "ACH_FIRST_GAME";
    public static final String ACH_FIRST_WIN = "ACH_FIRST_WIN";
    public static final String ACH_FIRST_ONLINE = "ACH_FIRST_ONLINE";
    public static final String ACH_BUY_POWERUP = "ACH_BUY_POWERUP";

    public static final String ACH_LEVEL_5 = "ACH_LEVEL_5";
    public static final String ACH_LEVEL_10 = "ACH_LEVEL_10";
    public static final String ACH_LEVEL_20 = "ACH_LEVEL_20";
    public static final String ACH_LEVEL_30 = "ACH_LEVEL_30";
    public static final String ACH_LEVEL_45 = "ACH_LEVEL_45";
    public static final String ACH_LEVEL_50 = "ACH_LEVEL_50";
    public static final String ACH_LEVEL_60 = "ACH_LEVEL_60";

    public static final String ACH_GAMES_10 = "ACH_GAMES_10";
    public static final String ACH_GAMES_25 = "ACH_GAMES_25";
    public static final String ACH_GAMES_50 = "ACH_GAMES_50";
    public static final String ACH_GAMES_100 = "ACH_GAMES_100";
    public static final String ACH_GAMES_250 = "ACH_GAMES_250";
    public static final String ACH_GAMES_500 = "ACH_GAMES_500";

    public static final String ACH_WIN_5 = "ACH_WIN_5";
    public static final String ACH_WIN_10 = "ACH_WIN_10";
    public static final String ACH_WIN_25 = "ACH_WIN_25";
    public static final String ACH_WIN_50 = "ACH_WIN_50";
    public static final String ACH_WIN_100 = "ACH_WIN_100";
    public static final String ACH_WIN_250 = "ACH_WIN_250";

    public static final String ACH_CORRECT_10 = "ACH_CORRECT_10";
    public static final String ACH_CORRECT_50 = "ACH_CORRECT_50";
    public static final String ACH_CORRECT_100 = "ACH_CORRECT_100";
    public static final String ACH_CORRECT_500 = "ACH_CORRECT_500";
    public static final String ACH_CORRECT_1000 = "ACH_CORRECT_1000";
    public static final String ACH_CORRECT_2500 = "ACH_CORRECT_2500";
    public static final String ACH_CORRECT_5000 = "ACH_CORRECT_5000";

    public static final String ACH_ACCURACY_70 = "ACH_ACCURACY_70";
    public static final String ACH_ACCURACY_80 = "ACH_ACCURACY_80";
    public static final String ACH_ACCURACY_90 = "ACH_ACCURACY_90";

    public static final String ACH_PRIZE_1000 = "ACH_PRIZE_1000";
    public static final String ACH_PRIZE_32000 = "ACH_PRIZE_32000";
    public static final String ACH_PRIZE_500000 = "ACH_PRIZE_500000";
    public static final String ACH_PRIZE_1000000 = "ACH_PRIZE_1000000";

    public static final String ACH_EARNINGS_100000 = "ACH_EARNINGS_100000";
    public static final String ACH_EARNINGS_1000000 = "ACH_EARNINGS_1000000";
    public static final String ACH_EARNINGS_10000000 = "ACH_EARNINGS_10000000";

    public static final String ACH_STREAK_3 = "ACH_STREAK_3";
    public static final String ACH_STREAK_5 = "ACH_STREAK_5";
    public static final String ACH_STREAK_10 = "ACH_STREAK_10";
    public static final String ACH_STREAK_15 = "ACH_STREAK_15";

    public static final String ACH_WIN_STREAK_3 = "ACH_WIN_STREAK_3";
    public static final String ACH_WIN_STREAK_5 = "ACH_WIN_STREAK_5";
    public static final String ACH_WIN_STREAK_10 = "ACH_WIN_STREAK_10";

    public static final String ACH_COINS_1000 = "ACH_COINS_1000";
    public static final String ACH_COINS_5000 = "ACH_COINS_5000";
    public static final String ACH_COINS_10000 = "ACH_COINS_10000";
    public static final String ACH_COINS_50000 = "ACH_COINS_50000";
    public static final String ACH_GEMS_50 = "ACH_GEMS_50";
    public static final String ACH_GEMS_500 = "ACH_GEMS_500";
    public static final String ACH_GEMS_1000 = "ACH_GEMS_1000";

    public static final String ACH_INVENTORY_5 = "ACH_INVENTORY_5";
    public static final String ACH_INVENTORY_15 = "ACH_INVENTORY_15";
    public static final String ACH_INVENTORY_30 = "ACH_INVENTORY_30";

    public static final String ACH_USE_5050 = "ACH_USE_5050";
    public static final String ACH_USE_AUDIENCE = "ACH_USE_AUDIENCE";
    public static final String ACH_USE_CALL = "ACH_USE_CALL";
    public static final String ACH_USE_ALL_HELPS = "ACH_USE_ALL_HELPS";
    public static final String ACH_PERFECT_GAME = "ACH_PERFECT_GAME";

    public static final String ACH_ONLINE_WIN_5 = "ACH_ONLINE_WIN_5";
    public static final String ACH_ONLINE_WIN_10 = "ACH_ONLINE_WIN_10";
    public static final String ACH_ONLINE_WIN_25 = "ACH_ONLINE_WIN_25";
    public static final String ACH_BLITZ_FINISH_5 = "ACH_BLITZ_FINISH_5";
    public static final String ACH_BLITZ_FINISH_15 = "ACH_BLITZ_FINISH_15";
    public static final String ACH_ELIMINATION_WIN_3 = "ACH_ELIMINATION_WIN_3";
    public static final String ACH_ELIMINATION_WIN_10 = "ACH_ELIMINATION_WIN_10";
    public static final String ACH_SURVIVAL_WIN_3 = "ACH_SURVIVAL_WIN_3";
    public static final String ACH_SURVIVAL_WIN_10 = "ACH_SURVIVAL_WIN_10";
    public static final String ACH_SERIES_WIN_3 = "ACH_SERIES_WIN_3";
    public static final String ACH_SERIES_WIN_10 = "ACH_SERIES_WIN_10";
    public static final String ACH_TEAM_BATTLE_WIN_5 = "ACH_TEAM_BATTLE_WIN_5";
    public static final String ACH_TEAM_BATTLE_WIN_15 = "ACH_TEAM_BATTLE_WIN_15";

    public static final String ACH_ALL_DONE = "ACH_ALL_DONE";

    private static final String[] ALL_ACHIEVEMENTS = {
            ACH_FIRST_GAME, ACH_FIRST_WIN, ACH_FIRST_ONLINE, ACH_BUY_POWERUP,
            ACH_LEVEL_5, ACH_LEVEL_10, ACH_LEVEL_20, ACH_LEVEL_30, ACH_LEVEL_45, ACH_LEVEL_60,
            ACH_GAMES_10, ACH_GAMES_25, ACH_GAMES_50, ACH_GAMES_100, ACH_GAMES_250, ACH_GAMES_500,
            ACH_WIN_5, ACH_WIN_10, ACH_WIN_25, ACH_WIN_50, ACH_WIN_100, ACH_WIN_250,
            ACH_CORRECT_10, ACH_CORRECT_50, ACH_CORRECT_100, ACH_CORRECT_500,
            ACH_CORRECT_1000, ACH_CORRECT_2500, ACH_CORRECT_5000,
            ACH_ACCURACY_70, ACH_ACCURACY_80, ACH_ACCURACY_90,
            ACH_PRIZE_1000, ACH_PRIZE_32000, ACH_PRIZE_500000, ACH_PRIZE_1000000,
            ACH_EARNINGS_100000, ACH_EARNINGS_1000000, ACH_EARNINGS_10000000,
            ACH_STREAK_3, ACH_STREAK_5, ACH_STREAK_10, ACH_STREAK_15,
            ACH_WIN_STREAK_3, ACH_WIN_STREAK_5, ACH_WIN_STREAK_10,
            ACH_COINS_1000, ACH_COINS_5000, ACH_COINS_10000, ACH_COINS_50000,
            ACH_GEMS_50, ACH_GEMS_500, ACH_GEMS_1000,
            ACH_INVENTORY_5, ACH_INVENTORY_15, ACH_INVENTORY_30,
            ACH_USE_5050, ACH_USE_AUDIENCE, ACH_USE_CALL, ACH_USE_ALL_HELPS, ACH_PERFECT_GAME,
            ACH_ONLINE_WIN_5, ACH_ONLINE_WIN_10, ACH_ONLINE_WIN_25,
            ACH_BLITZ_FINISH_5, ACH_BLITZ_FINISH_15,
            ACH_ELIMINATION_WIN_3, ACH_ELIMINATION_WIN_10,
            ACH_SURVIVAL_WIN_3, ACH_SURVIVAL_WIN_10,
            ACH_SERIES_WIN_3, ACH_SERIES_WIN_10,
            ACH_TEAM_BATTLE_WIN_5, ACH_TEAM_BATTLE_WIN_15
    };

    private static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences(PREF, Context.MODE_PRIVATE);
    }

    public static String[] getAllAchievementKeys() {
        String[] keys = new String[ALL_ACHIEVEMENTS.length + 1];
        System.arraycopy(ALL_ACHIEVEMENTS, 0, keys, 0, ALL_ACHIEVEMENTS.length);
        keys[ALL_ACHIEVEMENTS.length] = ACH_ALL_DONE;
        return keys;
    }

    public static int getXp(Context c) { return prefs(c).getInt("xp", 0); }
    public static int getCoins(Context c) { return prefs(c).getInt("coins", 0); }
    public static int getGems(Context c) { return prefs(c).getInt("gems", 0); }
    public static int getDailyClaimCount(Context c) { return prefs(c).getInt("dailyCount", 0); }
    public static int getInventory5050(Context c) { return prefs(c).getInt("inv5050", 0); }
    public static int getInventoryAudience(Context c) { return prefs(c).getInt("invAudience", 0); }
    public static int getInventoryCall(Context c) { return prefs(c).getInt("invCall", 0); }
    public static int getOnlineWins(Context c) { return prefs(c).getInt("onlineWins", 0); }
    public static int getBlitzFinishes(Context c) { return prefs(c).getInt("blitzFinishes", 0); }
    public static int getEliminationWins(Context c) { return prefs(c).getInt("eliminationWins", 0); }
    public static int getSurvivalWins(Context c) { return prefs(c).getInt("survivalWins", 0); }
    public static int getSeriesWins(Context c) { return prefs(c).getInt("seriesWins", 0); }
    public static int getTeamBattleWins(Context c) { return prefs(c).getInt("teamBattleWins", 0); }

    public static void addXp(Context c, int amount) {
        if (amount <= 0) return;
        SharedPreferences p = prefs(c);
        int newXp = p.getInt("xp", 0) + amount;
        p.edit().putInt("xp", newXp).apply();
        checkLevelAchievements(c);
    }

    public static void addCoins(Context c, int amount) {
        if (amount == 0) return;
        SharedPreferences p = prefs(c);
        int newCoins = Math.max(0, p.getInt("coins", 0) + amount);
        p.edit().putInt("coins", newCoins).apply();
        checkCurrencyAchievements(c);
    }

    public static boolean spendCoins(Context c, int amount) {
        if (amount <= 0 || getCoins(c) < amount) return false;
        addCoins(c, -amount);
        return true;
    }

    public static void addGems(Context c, int amount) {
        if (amount == 0) return;
        SharedPreferences p = prefs(c);
        int newGems = Math.max(0, p.getInt("gems", 0) + amount);
        p.edit().putInt("gems", newGems).apply();
        checkCurrencyAchievements(c);
    }

    public static boolean spendGems(Context c, int amount) {
        if (amount <= 0 || getGems(c) < amount) return false;
        addGems(c, -amount);
        return true;
    }

    public static int getLevel(Context c) {
        int xp = getXp(c);
        int lv = 1;
        while (xp >= xpNeededForLevel(lv)) {
            xp -= xpNeededForLevel(lv);
            lv++;
        }
        return lv;
    }

    public static int getXpIntoLevel(Context c) {
        int xp = getXp(c);
        int lv = 1;
        while (xp >= xpNeededForLevel(lv)) {
            xp -= xpNeededForLevel(lv);
            lv++;
        }
        return xp;
    }

    public static int getXpNeededForNextLevel(Context c) {
        return xpNeededForLevel(getLevel(c));
    }

    public static String getRankTitle(int level) {
        if (level >= 60) return "Legend";
        if (level >= 45) return "Master";
        if (level >= 30) return "Diamond";
        if (level >= 20) return "Gold";
        if (level >= 10) return "Silver";
        if (level >= 5) return "Bronze";
        return "Rookie";
    }

    private static int xpNeededForLevel(int level) {
        int safeLevel = Math.max(1, level);
        if (safeLevel < 5) return 120 + (safeLevel - 1) * 40;
        if (safeLevel < 10) return 320 + (safeLevel - 5) * 55;
        if (safeLevel < 20) return 620 + (safeLevel - 10) * 80;
        if (safeLevel < 30) return 1450 + (safeLevel - 20) * 130;
        if (safeLevel < 45) return 2850 + (safeLevel - 30) * 210;
        if (safeLevel < 60) return 6000 + (safeLevel - 45) * 360;
        return 11500 + (safeLevel - 60) * 550;
    }

    public static void addInventory(Context c, String type, int amount) {
        addInventoryInternal(c, type, amount, true);
    }

    public static void grantInventory(Context c, String type, int amount) {
        addInventoryInternal(c, type, amount, false);
    }

    private static void addInventoryInternal(Context c, String type, int amount, boolean countsAsPurchase) {
        String key = inventoryKey(type);
        if (key == null || amount == 0) return;
        SharedPreferences p = prefs(c);
        int next = Math.max(0, p.getInt(key, 0) + amount);
        p.edit().putInt(key, next).apply();
        if (amount > 0 && countsAsPurchase) unlockAchievement(c, ACH_BUY_POWERUP);
        checkInventoryAchievements(c);
    }

    public static boolean consumeInventory(Context c, String type) {
        String key = inventoryKey(type);
        if (key == null) return false;
        SharedPreferences p = prefs(c);
        int current = p.getInt(key, 0);
        if (current <= 0) return false;
        p.edit().putInt(key, current - 1).apply();
        if ("5050".equals(type)) unlockAchievement(c, ACH_USE_5050);
        if ("audience".equals(type)) unlockAchievement(c, ACH_USE_AUDIENCE);
        if ("call".equals(type)) unlockAchievement(c, ACH_USE_CALL);
        return true;
    }

    private static String inventoryKey(String type) {
        if ("5050".equals(type)) return "inv5050";
        if ("audience".equals(type)) return "invAudience";
        if ("call".equals(type)) return "invCall";
        return null;
    }

    public static boolean isAchievementUnlocked(Context c, String key) {
        return prefs(c).getBoolean(key, false);
    }

    public static void unlockAchievement(Context c, String key) {
        SharedPreferences p = prefs(c);
        if (!p.getBoolean(key, false)) {
            p.edit().putBoolean(key, true).apply();
            AchievementReward reward = rewardForAchievement(key);
            addCoins(c, reward.coins);
            addXp(c, reward.xp);
        }
    }

    public static void checkAllDone(Context c) {
        for (String key : ALL_ACHIEVEMENTS) {
            if (!isAchievementUnlocked(c, key)) return;
        }
        unlockAchievement(c, ACH_ALL_DONE);
    }

    public static void checkMilestoneAchievements(Context c) {
        checkLevelAchievements(c);
        checkCurrencyAchievements(c);
        checkInventoryAchievements(c);

        int games = PlayerStats.getGamesPlayed(c);
        if (games >= 10) unlockAchievement(c, ACH_GAMES_10);
        if (games >= 25) unlockAchievement(c, ACH_GAMES_25);
        if (games >= 50) unlockAchievement(c, ACH_GAMES_50);
        if (games >= 100) unlockAchievement(c, ACH_GAMES_100);
        if (games >= 250) unlockAchievement(c, ACH_GAMES_250);
        if (games >= 500) unlockAchievement(c, ACH_GAMES_500);

        int wins = PlayerStats.getWins(c);
        if (wins >= 5) unlockAchievement(c, ACH_WIN_5);
        if (wins >= 10) unlockAchievement(c, ACH_WIN_10);
        if (wins >= 25) unlockAchievement(c, ACH_WIN_25);
        if (wins >= 50) unlockAchievement(c, ACH_WIN_50);
        if (wins >= 100) unlockAchievement(c, ACH_WIN_100);
        if (wins >= 250) unlockAchievement(c, ACH_WIN_250);

        int correct = PlayerStats.getCorrectAnswers(c);
        if (correct >= 10) unlockAchievement(c, ACH_CORRECT_10);
        if (correct >= 50) unlockAchievement(c, ACH_CORRECT_50);
        if (correct >= 100) unlockAchievement(c, ACH_CORRECT_100);
        if (correct >= 500) unlockAchievement(c, ACH_CORRECT_500);
        if (correct >= 1000) unlockAchievement(c, ACH_CORRECT_1000);
        if (correct >= 2500) unlockAchievement(c, ACH_CORRECT_2500);
        if (correct >= 5000) unlockAchievement(c, ACH_CORRECT_5000);

        int totalAnswered = PlayerStats.getTotalAnswered(c);
        int accuracy = totalAnswered == 0 ? 0 : Math.round((correct * 100f) / totalAnswered);
        if (totalAnswered >= 50 && accuracy >= 70) unlockAchievement(c, ACH_ACCURACY_70);
        if (totalAnswered >= 100 && accuracy >= 80) unlockAchievement(c, ACH_ACCURACY_80);
        if (totalAnswered >= 250 && accuracy >= 90) unlockAchievement(c, ACH_ACCURACY_90);

        int bestStreak = PlayerStats.getBestStreak(c);
        if (bestStreak >= 3) unlockAchievement(c, ACH_STREAK_3);
        if (bestStreak >= 5) unlockAchievement(c, ACH_STREAK_5);
        if (bestStreak >= 10) unlockAchievement(c, ACH_STREAK_10);
        if (bestStreak >= 15) unlockAchievement(c, ACH_STREAK_15);

        int bestWinStreak = PlayerStats.getBestWinStreak(c);
        if (bestWinStreak >= 3) unlockAchievement(c, ACH_WIN_STREAK_3);
        if (bestWinStreak >= 5) unlockAchievement(c, ACH_WIN_STREAK_5);
        if (bestWinStreak >= 10) unlockAchievement(c, ACH_WIN_STREAK_10);

        int highest = PlayerStats.getHighestMoney(c);
        if (highest >= 1000) unlockAchievement(c, ACH_PRIZE_1000);
        if (highest >= 32000) unlockAchievement(c, ACH_PRIZE_32000);
        if (highest >= 500000) unlockAchievement(c, ACH_PRIZE_500000);
        if (highest >= 1000000) unlockAchievement(c, ACH_PRIZE_1000000);

        long totalEarnings = PlayerStats.getTotalEarnings(c);
        if (totalEarnings >= 100000L) unlockAchievement(c, ACH_EARNINGS_100000);
        if (totalEarnings >= 1000000L) unlockAchievement(c, ACH_EARNINGS_1000000);
        if (totalEarnings >= 10000000L) unlockAchievement(c, ACH_EARNINGS_10000000);

        int onlineWins = getOnlineWins(c);
        if (onlineWins >= 5) unlockAchievement(c, ACH_ONLINE_WIN_5);
        if (onlineWins >= 10) unlockAchievement(c, ACH_ONLINE_WIN_10);
        if (onlineWins >= 25) unlockAchievement(c, ACH_ONLINE_WIN_25);

        int blitzFinishes = getBlitzFinishes(c);
        if (blitzFinishes >= 5) unlockAchievement(c, ACH_BLITZ_FINISH_5);
        if (blitzFinishes >= 15) unlockAchievement(c, ACH_BLITZ_FINISH_15);

        int eliminationWins = getEliminationWins(c);
        if (eliminationWins >= 3) unlockAchievement(c, ACH_ELIMINATION_WIN_3);
        if (eliminationWins >= 10) unlockAchievement(c, ACH_ELIMINATION_WIN_10);

        int survivalWins = getSurvivalWins(c);
        if (survivalWins >= 3) unlockAchievement(c, ACH_SURVIVAL_WIN_3);
        if (survivalWins >= 10) unlockAchievement(c, ACH_SURVIVAL_WIN_10);

        int seriesWins = getSeriesWins(c);
        if (seriesWins >= 3) unlockAchievement(c, ACH_SERIES_WIN_3);
        if (seriesWins >= 10) unlockAchievement(c, ACH_SERIES_WIN_10);

        int teamBattleWins = getTeamBattleWins(c);
        if (teamBattleWins >= 5) unlockAchievement(c, ACH_TEAM_BATTLE_WIN_5);
        if (teamBattleWins >= 15) unlockAchievement(c, ACH_TEAM_BATTLE_WIN_15);

        checkAllDone(c);
    }

    private static void checkLevelAchievements(Context c) {
        int lv = getLevel(c);
        if (lv >= 5) unlockAchievement(c, ACH_LEVEL_5);
        if (lv >= 10) unlockAchievement(c, ACH_LEVEL_10);
        if (lv >= 20) unlockAchievement(c, ACH_LEVEL_20);
        if (lv >= 30) unlockAchievement(c, ACH_LEVEL_30);
        if (lv >= 45) unlockAchievement(c, ACH_LEVEL_45);
        if (lv >= 60) unlockAchievement(c, ACH_LEVEL_60);
    }

    private static void checkCurrencyAchievements(Context c) {
        int coins = getCoins(c);
        if (coins >= 1000) unlockAchievement(c, ACH_COINS_1000);
        if (coins >= 5000) unlockAchievement(c, ACH_COINS_5000);
        if (coins >= 10000) unlockAchievement(c, ACH_COINS_10000);
        if (coins >= 50000) unlockAchievement(c, ACH_COINS_50000);

        int gems = getGems(c);
        if (gems >= 50) unlockAchievement(c, ACH_GEMS_50);
        if (gems >= 500) unlockAchievement(c, ACH_GEMS_500);
        if (gems >= 1000) unlockAchievement(c, ACH_GEMS_1000);
    }

    private static void checkInventoryAchievements(Context c) {
        int total = getInventory5050(c) + getInventoryAudience(c) + getInventoryCall(c);
        if (total >= 5) unlockAchievement(c, ACH_INVENTORY_5);
        if (total >= 15) unlockAchievement(c, ACH_INVENTORY_15);
        if (total >= 30) unlockAchievement(c, ACH_INVENTORY_30);
    }

    public static void onGameFinished(
            Context c,
            boolean won,
            int prizeMoney,
            int bestStreak,
            boolean usedAllHelps
    ) {
        onGameFinished(c, won, prizeMoney, bestStreak, usedAllHelps, usedAllHelps);
    }

    public static void onGameFinished(
            Context c,
            boolean won,
            int prizeMoney,
            int bestStreak,
            boolean usedAllHelps,
            boolean usedAnyHelp
    ) {
        unlockAchievement(c, ACH_FIRST_GAME);
        if (won) unlockAchievement(c, ACH_FIRST_WIN);

        if (bestStreak >= 3) unlockAchievement(c, ACH_STREAK_3);
        if (bestStreak >= 5) unlockAchievement(c, ACH_STREAK_5);
        if (bestStreak >= 10) unlockAchievement(c, ACH_STREAK_10);
        if (bestStreak >= 15) unlockAchievement(c, ACH_STREAK_15);

        if (prizeMoney >= 1000) unlockAchievement(c, ACH_PRIZE_1000);
        if (prizeMoney >= 32000) unlockAchievement(c, ACH_PRIZE_32000);
        if (prizeMoney >= 500000) unlockAchievement(c, ACH_PRIZE_500000);
        if (prizeMoney >= 1000000) unlockAchievement(c, ACH_PRIZE_1000000);

        if (usedAllHelps) unlockAchievement(c, ACH_USE_ALL_HELPS);
        if (won && !usedAnyHelp) unlockAchievement(c, ACH_PERFECT_GAME);

        grantCompletedMatchBonus(c, null);
        addCoins(c, Math.max(50, prizeMoney / 40));
        addXp(c, won ? XP_OFFLINE_WIN : XP_OFFLINE_LOSS);
        checkMilestoneAchievements(c);
    }

    public static void onOnlineMatchFinished(Context c, boolean won, int roundsWon) {
        onOnlineMatchFinished(c, won, roundsWon, "battle", false, null);
    }

    public static void onOnlineMatchFinished(
            Context c,
            boolean won,
            int roundsWon,
            String matchMode,
            boolean completedToEnd,
            String completionKey
    ) {
        unlockAchievement(c, ACH_FIRST_GAME);
        unlockAchievement(c, ACH_FIRST_ONLINE);
        if (won) unlockAchievement(c, ACH_FIRST_WIN);

        int xp = won ? XP_ONLINE_WIN : XP_ONLINE_LOSS;
        xp += Math.max(0, roundsWon) * XP_ONLINE_ROUND_WON;
        addXp(c, xp);

        if (completedToEnd) {
            grantCompletedMatchBonus(c, completionKey);
        }

        if (won) {
            int onlineWins = incrementCounter(c, "onlineWins", 1);
            if (onlineWins >= 5) unlockAchievement(c, ACH_ONLINE_WIN_5);
            if (onlineWins >= 10) unlockAchievement(c, ACH_ONLINE_WIN_10);
            if (onlineWins >= 25) unlockAchievement(c, ACH_ONLINE_WIN_25);
        }

        final String normalizedMode = normalizeMode(matchMode);
        if (completedToEnd && "blitz".equals(normalizedMode)) {
            int blitzFinishes = incrementCounter(c, "blitzFinishes", 1);
            if (blitzFinishes >= 5) unlockAchievement(c, ACH_BLITZ_FINISH_5);
            if (blitzFinishes >= 15) unlockAchievement(c, ACH_BLITZ_FINISH_15);
        }

        if (won) {
            if ("elimination".equals(normalizedMode)) {
                int total = incrementCounter(c, "eliminationWins", 1);
                if (total >= 3) unlockAchievement(c, ACH_ELIMINATION_WIN_3);
                if (total >= 10) unlockAchievement(c, ACH_ELIMINATION_WIN_10);
            } else if ("survival".equals(normalizedMode)) {
                int total = incrementCounter(c, "survivalWins", 1);
                if (total >= 3) unlockAchievement(c, ACH_SURVIVAL_WIN_3);
                if (total >= 10) unlockAchievement(c, ACH_SURVIVAL_WIN_10);
            } else if ("series".equals(normalizedMode)) {
                int total = incrementCounter(c, "seriesWins", 1);
                if (total >= 3) unlockAchievement(c, ACH_SERIES_WIN_3);
                if (total >= 10) unlockAchievement(c, ACH_SERIES_WIN_10);
            } else if ("team_battle".equals(normalizedMode)) {
                int total = incrementCounter(c, "teamBattleWins", 1);
                if (total >= 5) unlockAchievement(c, ACH_TEAM_BATTLE_WIN_5);
                if (total >= 15) unlockAchievement(c, ACH_TEAM_BATTLE_WIN_15);
            }
        }

        checkMilestoneAchievements(c);
    }

    private static int incrementCounter(Context c, String key, int amount) {
        SharedPreferences p = prefs(c);
        int next = p.getInt(key, 0) + amount;
        p.edit().putInt(key, next).apply();
        return next;
    }

    private static void grantCompletedMatchBonus(Context c, String completionKey) {
        if (completionKey != null && !completionKey.trim().isEmpty()) {
            String normalizedKey = "bonusMatch:" + completionKey.trim();
            SharedPreferences p = prefs(c);
            if (p.getBoolean(normalizedKey, false)) {
                return;
            }
            p.edit().putBoolean(normalizedKey, true).apply();
        }
        addCoins(c, MATCH_COMPLETION_BONUS);
    }

    private static String normalizeMode(String matchMode) {
        if (matchMode == null) {
            return "";
        }
        return matchMode.trim().toLowerCase(Locale.US);
    }

    public static boolean canClaimDailyReward(Context c) {
        String today = new SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(new Date());
        return !today.equals(prefs(c).getString("lastDailyDate", ""));
    }

    public static DailyReward claimDailyReward(Context c) {
        SharedPreferences p = prefs(c);
        String today = new SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(new Date());
        String yesterday = p.getString("lastDailyDate", "");
        int streak = p.getInt("dailyCount", 0);
        if (!today.equals(yesterday)) {
            streak += 1;
        }
        int coins = 500 + Math.min(streak, 7) * 50;
        int gems = streak % 3 == 0 ? 2 : 1;
        addCoins(c, coins);
        addGems(c, gems);
        p.edit().putString("lastDailyDate", today).putInt("dailyCount", streak).apply();
        return new DailyReward(coins, gems, streak);
    }

    private static AchievementReward rewardForAchievement(String key) {
        switch (key) {
            case ACH_FIRST_GAME:
                return new AchievementReward(150, 40);
            case ACH_FIRST_WIN:
            case ACH_FIRST_ONLINE:
                return new AchievementReward(250, 70);
            case ACH_BUY_POWERUP:
                return new AchievementReward(200, 60);

            case ACH_LEVEL_5:
                return new AchievementReward(300, 100);
            case ACH_LEVEL_10:
                return new AchievementReward(500, 150);
            case ACH_LEVEL_20:
                return new AchievementReward(900, 250);
            case ACH_LEVEL_30:
                return new AchievementReward(1400, 400);
            case ACH_LEVEL_45:
                return new AchievementReward(2200, 650);
            case ACH_LEVEL_50:
                return new AchievementReward(2500, 700);
            case ACH_LEVEL_60:
                return new AchievementReward(3500, 1000);

            case ACH_GAMES_10:
                return new AchievementReward(250, 80);
            case ACH_GAMES_25:
                return new AchievementReward(450, 120);
            case ACH_GAMES_50:
                return new AchievementReward(700, 180);
            case ACH_GAMES_100:
                return new AchievementReward(1100, 260);
            case ACH_GAMES_250:
                return new AchievementReward(1800, 420);
            case ACH_GAMES_500:
                return new AchievementReward(3000, 700);

            case ACH_WIN_5:
                return new AchievementReward(350, 100);
            case ACH_WIN_10:
                return new AchievementReward(600, 160);
            case ACH_WIN_25:
                return new AchievementReward(1000, 260);
            case ACH_WIN_50:
                return new AchievementReward(1600, 420);
            case ACH_WIN_100:
                return new AchievementReward(2600, 650);
            case ACH_WIN_250:
                return new AchievementReward(4500, 1100);

            case ACH_CORRECT_10:
                return new AchievementReward(180, 60);
            case ACH_CORRECT_50:
                return new AchievementReward(400, 120);
            case ACH_CORRECT_100:
                return new AchievementReward(700, 180);
            case ACH_CORRECT_500:
                return new AchievementReward(1500, 350);
            case ACH_CORRECT_1000:
                return new AchievementReward(2500, 550);
            case ACH_CORRECT_2500:
                return new AchievementReward(4200, 900);
            case ACH_CORRECT_5000:
                return new AchievementReward(7000, 1500);

            case ACH_ACCURACY_70:
                return new AchievementReward(600, 180);
            case ACH_ACCURACY_80:
                return new AchievementReward(1100, 300);
            case ACH_ACCURACY_90:
                return new AchievementReward(2200, 600);

            case ACH_PRIZE_1000:
                return new AchievementReward(200, 60);
            case ACH_PRIZE_32000:
                return new AchievementReward(450, 130);
            case ACH_PRIZE_500000:
                return new AchievementReward(1200, 350);
            case ACH_PRIZE_1000000:
                return new AchievementReward(2500, 700);
            case ACH_EARNINGS_100000:
                return new AchievementReward(500, 150);
            case ACH_EARNINGS_1000000:
                return new AchievementReward(1500, 400);
            case ACH_EARNINGS_10000000:
                return new AchievementReward(4000, 900);

            case ACH_STREAK_3:
                return new AchievementReward(200, 70);
            case ACH_STREAK_5:
                return new AchievementReward(350, 100);
            case ACH_STREAK_10:
                return new AchievementReward(800, 220);
            case ACH_STREAK_15:
                return new AchievementReward(1600, 450);
            case ACH_WIN_STREAK_3:
                return new AchievementReward(500, 150);
            case ACH_WIN_STREAK_5:
                return new AchievementReward(1000, 260);
            case ACH_WIN_STREAK_10:
                return new AchievementReward(2200, 600);

            case ACH_COINS_1000:
                return new AchievementReward(200, 60);
            case ACH_COINS_5000:
                return new AchievementReward(500, 140);
            case ACH_COINS_10000:
                return new AchievementReward(900, 240);
            case ACH_COINS_50000:
                return new AchievementReward(2200, 550);
            case ACH_GEMS_50:
                return new AchievementReward(450, 120);
            case ACH_GEMS_500:
                return new AchievementReward(1500, 380);
            case ACH_GEMS_1000:
                return new AchievementReward(2600, 650);
            case ACH_INVENTORY_5:
                return new AchievementReward(300, 90);
            case ACH_INVENTORY_15:
                return new AchievementReward(700, 190);
            case ACH_INVENTORY_30:
                return new AchievementReward(1300, 340);

            case ACH_USE_5050:
            case ACH_USE_AUDIENCE:
            case ACH_USE_CALL:
                return new AchievementReward(150, 50);
            case ACH_USE_ALL_HELPS:
                return new AchievementReward(700, 220);
            case ACH_PERFECT_GAME:
                return new AchievementReward(1800, 500);

            case ACH_ONLINE_WIN_5:
                return new AchievementReward(500, 150);
            case ACH_ONLINE_WIN_10:
                return new AchievementReward(900, 240);
            case ACH_ONLINE_WIN_25:
                return new AchievementReward(1800, 500);
            case ACH_BLITZ_FINISH_5:
                return new AchievementReward(600, 180);
            case ACH_BLITZ_FINISH_15:
                return new AchievementReward(1500, 420);
            case ACH_ELIMINATION_WIN_3:
            case ACH_SURVIVAL_WIN_3:
                return new AchievementReward(700, 200);
            case ACH_ELIMINATION_WIN_10:
            case ACH_SURVIVAL_WIN_10:
                return new AchievementReward(1800, 500);
            case ACH_SERIES_WIN_3:
                return new AchievementReward(800, 230);
            case ACH_SERIES_WIN_10:
                return new AchievementReward(2000, 550);
            case ACH_TEAM_BATTLE_WIN_5:
                return new AchievementReward(900, 260);
            case ACH_TEAM_BATTLE_WIN_15:
                return new AchievementReward(2200, 600);

            case ACH_ALL_DONE:
                return new AchievementReward(10000, 2500);
            default:
                return new AchievementReward(250, 80);
        }
    }

    public static final int XP_ONLINE_WIN = 100;
    public static final int XP_ONLINE_LOSS = 30;
    public static final int XP_ONLINE_ROUND_WON = 15;
    public static final int XP_OFFLINE_WIN = 80;
    public static final int XP_OFFLINE_LOSS = 20;

    public static void resetAll(Context c) {
        prefs(c).edit().clear().apply();
    }

    private static final class AchievementReward {
        final int coins;
        final int xp;

        AchievementReward(int coins, int xp) {
            this.coins = coins;
            this.xp = xp;
        }
    }

    public static class DailyReward {
        public final int coins;
        public final int gems;
        public final int streak;

        public DailyReward(int coins, int gems, int streak) {
            this.coins = coins;
            this.gems = gems;
            this.streak = streak;
        }
    }
}
